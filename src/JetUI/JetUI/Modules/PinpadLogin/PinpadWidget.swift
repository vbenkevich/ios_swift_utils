//
//  PinpadController.swift
//  JetUI
//
//  Created by Vladimir Benkevich on 29/12/2018.
//

import UIKit
import JetLib

public protocol PinpadDelegate: class {

    var symbolsCount: UInt8 { get }
    var isTouchIdEnabled: Bool { get }
    var isFaceIdEnabled: Bool { get }

    func check(pincode: String) -> Task<Void>
    func checkFaceId() -> Task<Void>
    func checkTouchId() -> Task<Void>
}

public class PinpadWidget: UIView {

    static let defaultConfiguration = DefaultConfiguration()

    lazy var viewModel: ViewModel = {
        let vm = ViewModel()
        vm.view = self
        vm.pincode = ""
        return vm
    }()

    public weak var delegate: PinpadDelegate? {
        get { return viewModel.delegate }
        set { viewModel.delegate = newValue }
    }

    public var configuration: PinpadConfiguration = PinpadWidget.defaultConfiguration {
        didSet {
            pinCodeView.configuration = configuration
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

    var pinCodeView: PincodeView = PincodeView(configuration: PinpadWidget.defaultConfiguration)
    var biometricView: UIView!
    var biometricButton: UIButton!
    var deleteButton: UIButton!
    var numberButtons: [UIButton] = []

    public override func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview != nil && rootView == nil {
            reloadView(configuration)
        }
    }

    func reloadView(_ configuration: PinpadConfiguration) {
        let buttons = createButtonsView()
        let rootStack = UIStackView(arrangedSubviews: [pinCodeView, buttons])
        rootStack.axis = .vertical
        rootStack.alignment = .center
        rootStack.spacing = configuration.dotButtonsSpacing
        buttons.widthAnchor.constraint(equalTo: rootStack.widthAnchor).isActive = true

        rootView = rootStack

        deleteButton.command = viewModel.deleteCommand
        deleteButton.hideIfCantExecuteCommand = true
        //biometricButton.command = biometricCommand

        for i in 0...9 {
            numberButtons[i].commanParameter = i.description
            numberButtons[i].command = viewModel.appendCommand
        }

        viewModel.appendCommand.delegate = nil
    }


    func createButtonsView() -> UIView {
        deleteButton = configuration.createDeleteButton()
        numberButtons = (0...9).map { configuration.createButton(number: $0)}
        biometricView = UIView(frame: CGRect.zero)
        biometricView.backgroundColor = UIColor.clear

        var horStacks = (0..<3).map { row in
            UIStackView(arrangedSubviews: (0..<3).map { numberButtons[6 - (row * 3) + ($0 + 1)] })
        }

        horStacks.append(UIStackView(arrangedSubviews: [biometricView, numberButtons[0], deleteButton.embedInView()]))

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
