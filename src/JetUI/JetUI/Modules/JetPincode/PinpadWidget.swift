//
//  Created by Vladimir Benkevich on 07/01/2019.
//  Copyright © Vladimir Benkevich 2019
//

import UIKit
import JetLib

public class PinpadWidget: UIView {

    public var configuration: PinpadWidgetConfiguration = PinpadWidget.defaultConfiguration {
        didSet {
            pincodeView.configuration = configuration
            reloadView(configuration)
        }
    }


    static let defaultConfiguration = PinpadWidgetDefaultConfiguration()

    var viewModel: PinpadViewModel! {
        didSet {
            viewModel.view = self
        }
    }

    weak var controller: UIViewController?

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

    public func showPincodeInvalid(completion: @escaping () -> Void) {
        let duration = TimeInterval(0.5)
        let shift = CGFloat(10)
        let view = pincodeView

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)

        let propertyAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 0.3) {
            view.transform = CGAffineTransform(translationX: shift, y: 0)
        }

        propertyAnimator.addAnimations({
            view.transform = CGAffineTransform(translationX: 0, y: 0)
        }, delayFactor: 0.2)

        propertyAnimator.startAnimation()
        propertyAnimator.addCompletion { _ in completion() }
    }

    public override func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview != nil && rootView == nil {
            reloadView(configuration)
        }
    }

    override public func didMoveToWindow() {
        super.didMoveToWindow()

        if window != nil && configuration.showDeviceOwnerAuthImmidately {
            viewModel.deviceOwnerAuthCommand.execute()
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

        deleteButton.command = viewModel.deleteSymbolCommand
        deleteButton.hideIfCantExecuteCommand = true

        for i in 0...9 {
            numberButtons[i].commanParameter = i.description
            numberButtons[i].command = viewModel.appendSymbolCommand
        }

        viewModel.appendSymbolCommand.delegate = nil

        setupDeviceOwnerAuthButton()
        pincodeView.setup(symbolsCount: viewModel!.symbolsCount)
    }

    func setupDeviceOwnerAuthButton() {
        let authType = DeviceOwnerLock.type

        if authType == .unknown {
            deviceOwnerAuthButton = configuration.createOtherIdButton()
        } else if authType == .faceID {
            deviceOwnerAuthButton = configuration.createFaceIdButton()
        } else if authType == .touchID {
            deviceOwnerAuthButton = configuration.createTouchIdButton()
        } else {
            deviceOwnerAuthButton = nil
        }

        deviceOwnerAuthButton?.command = viewModel.deviceOwnerAuthCommand
        deviceOwnerAuthButton?.hideIfCantExecuteCommand = true
    }

    func createButtonsView() -> UIView {
        deleteButton = configuration.createDeleteButton()
        numberButtons = (0...9).map { configuration.createButton(number: $0)}
        deviceOwnerAuthView = UIView()
        deviceOwnerAuthView.backgroundColor = UIColor.clear
        deviceOwnerAuthView.translatesAutoresizingMaskIntoConstraints = false

        var horStacks = (0..<3).map { row in
            UIStackView(arrangedSubviews: (0..<3).map { numberButtons[(row * 3) + ($0 + 1)] })
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
