//
//  Created by Vladimir Benkevich on 07/01/2019.
//  Copyright © Vladimir Benkevich 2019
//

import UIKit
import JetLib

public protocol PinpadFlowDelegate: class {

    func loginSuccess()

    func loginFailed(_ error: Error, attempt: Int)
}

public class PinpadWidget: UIView {

    public static var localization = Localization()

    public struct Localization {
        public var incorrectPincode = "Invalid pincode"
        public var touchIdReason = "Application unlock"
    }

    static let defaultConfiguration = DefaultConfiguration()

    lazy var viewModel: ViewModel = {
        let vm = ViewModel()
        vm.view = self
        vm.pincode = ""
        return vm
    }()

    public var service: PinpadFlowWidgetService? {
        get { return viewModel.service }
        set { viewModel.service = newValue }
    }

    public var delegate: PinpadFlowDelegate? {
        get { return viewModel.delegate }
        set { viewModel.delegate = newValue }
    }

    public var configuration: PinpadWidgetConfiguration = PinpadWidget.defaultConfiguration {
        didSet {
            pincodeView.configuration = configuration
            reloadView(configuration)
        }
    }

    var rootView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            guard let content = rootView else { return }

            content.translatesAutoresizingMaskIntoConstraints = false
            addSubview(content)
            content.equalSizeConstraints(to: self)
        }
    }

    var pincodeView: PincodeView = PincodeView(configuration: PinpadWidget.defaultConfiguration)

    var deviceOwnerAuthView: UIView!

    var deviceOwnerAuthButton: UIButton? {
        didSet {
            oldValue?.removeFromSuperview()
            if let button = deviceOwnerAuthButton {
                deviceOwnerAuthView.addSubview(button)
                button.equalSizeConstraints(to: deviceOwnerAuthView)
            }
        }
    }

    var deleteButton: UIButton!

    var numberButtons: [UIButton] = []

    public override func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview != nil && rootView == nil {
            reloadView(configuration)
        }
    }

    func reloadView(_ configuration: PinpadWidgetConfiguration) {
        let buttons = createButtonsView()
        let rootStack = UIStackView(arrangedSubviews: [pincodeView, buttons])
        rootStack.axis = .vertical
        rootStack.alignment = .center
        rootStack.spacing = configuration.dotButtonsSpacing
        buttons.widthAnchor.constraint(equalTo: rootStack.widthAnchor).isActive = true

        rootView = rootStack

        deleteButton.command = viewModel.deleteCommand
        deleteButton.hideIfCantExecuteCommand = true

        for i in 0...9 {
            numberButtons[i].commanParameter = i.description
            numberButtons[i].command = viewModel.appendCommand
        }

        viewModel.appendCommand.delegate = nil

        setupDeviceOwnerAuthButton()
    }

    func setupDeviceOwnerAuthButton() {
        if service?.isFaceIdAvailable == true {
            deviceOwnerAuthButton = configuration.createFaceIdButton()
        } else if service?.isTouchIdAvailable == true {
            deviceOwnerAuthButton = configuration.createTouchIdButton()
        } else if service?.isDeviceOwnerAuthEnabled == true {
            deviceOwnerAuthButton = configuration.createOtherIdButton()
        } else {
            deviceOwnerAuthButton = nil
        }

        deviceOwnerAuthButton?.command = viewModel.biometricCommand
        deviceOwnerAuthButton?.hideIfCantExecuteCommand = true
    }

    func createButtonsView() -> UIView {
        deleteButton = configuration.createDeleteButton()
        numberButtons = (0...9).map { configuration.createButton(number: $0)}
        deviceOwnerAuthView = UIView(frame: CGRect.zero)
        deviceOwnerAuthView.backgroundColor = UIColor.clear

        var horStacks = (0..<3).map { row in
            UIStackView(arrangedSubviews: (0..<3).map { numberButtons[6 - (row * 3) + ($0 + 1)] })
        }

        horStacks.append(UIStackView(arrangedSubviews: [deviceOwnerAuthView, numberButtons[0], deleteButton.embedInView()]))

        for stack in horStacks {
            stack.distribution = .fillEqually
            stack.axis = .horizontal
            stack.spacing = configuration.horizontalSpacing
        }

        let buttons = UIStackView(arrangedSubviews: horStacks)
        buttons.axis = .vertical
        buttons.distribution = .fillEqually
        buttons.spacing = configuration.verticalSpacing

        return buttons
    }
}
