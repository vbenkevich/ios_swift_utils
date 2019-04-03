//
//  Created on 18/03/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation
import UIKit

public protocol Pinpad {

    func display(code: String)
    func invalideCode(completion: @escaping () -> Void)

    func setAppendCommand(_ command: Command)
    func setDeleteCommand(_ command: Command)
    func setBiometricCommand(_ command: Command)
}

class PincodeView: UIView {

    var rootView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            guard let content = rootView else { return }

            content.translatesAutoresizingMaskIntoConstraints = false
            addSubview(content)
            content.equalSizeConstraints(to: self)
        }
    }

    var codeView: CodeView!

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

    func setupDeviceOwnerAuthButton(_ factory: PinpadViewFactoryDefault) {
        let authType = BiometricAuth.type

        if authType == .unknown {
            deviceOwnerAuthButton = factory.createOtherIdButton()
        } else if authType == .faceID {
            deviceOwnerAuthButton = factory.createFaceIdButton()
        } else if authType == .touchID {
            deviceOwnerAuthButton = factory.createTouchIdButton()
        } else {
            deviceOwnerAuthButton = nil
        }

        deviceOwnerAuthButton?.hideIfCantExecuteCommand = true
    }

    func createButtonsView(_ factory: PinpadViewFactoryDefault) -> UIView {
        deleteButton = factory.createDeleteButton()
        numberButtons = (0...9).map { factory.createButton(number: $0)}
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
            stack.spacing = factory.horizontalSpacing
        }

        let buttons = UIStackView(arrangedSubviews: horStacks)
        buttons.axis = .vertical
        buttons.distribution = .fillEqually
        buttons.spacing = factory.verticalSpacing

        return buttons
    }

    class CodeView: UIStackView {

        convenience init() {
            self.init(arrangedSubviews: [])
            self.axis = .horizontal
            self.distribution = .fillEqually
        }

        var filledViews: [UIView] = [] {
            didSet {
                for view in oldValue {
                    removeArrangedSubview(view)
                }
                for (index, view) in filledViews.enumerated() {
                    addArrangedSubview(view)
                    view.isHidden = index >= pincode.count
                }
            }
        }

        var emptyViews: [UIView] = [] {
            didSet {
                for view in oldValue {
                    removeArrangedSubview(view)
                }
                for (index, view) in emptyViews.enumerated() {
                    addArrangedSubview(view)
                    view.isHidden = index < pincode.count
                }
            }
        }

        var pincode: String = "" {
            didSet {
                for index in 0..<emptyViews.count {
                    emptyViews[index].isHidden = index < pincode.count
                    filledViews[index].isHidden = index >= pincode.count
                }
            }
        }

        func reload(symbolsCount: Int, factory: PinpadViewFactoryDefault) {
            spacing = factory.horizontalSpacing
            filledViews = (0..<symbolsCount).map { _ in factory.createFilledDot() }
            emptyViews = (0..<symbolsCount).map { _ in factory.createEmptyDot() }
        }
    }
}

extension PincodeView: Pinpad {

    func load(_ factory: PinpadViewFactoryDefault, config: JetPincodeConfiguration) {
        let buttons = createButtonsView(factory)
        let rootStack = UIStackView(arrangedSubviews: [codeView, buttons])
        rootStack.axis = .vertical
        rootStack.alignment = .center
        rootStack.spacing = factory.dotButtonsSpacing
        buttons.widthAnchor.constraint(equalTo: rootStack.widthAnchor).isActive = true

        rootView = rootStack

        deleteButton.hideIfCantExecuteCommand = true

        setupDeviceOwnerAuthButton(factory)
        codeView.reload(symbolsCount: config.symbolsCount, factory: factory)
    }

    func invalideCode(completion: @escaping () -> Void) {
        let duration = TimeInterval(0.5)
        let shift = CGFloat(10)
        let view = codeView!

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

    func display(code: String) {
        codeView.pincode = code
    }

    func setAppendCommand(_ command: Command) {
        for i in 0...9 {
            numberButtons[i].commanParameter = i.description
            numberButtons[i].command = command
        }

        command.delegate = nil
    }

    func setDeleteCommand(_ command: Command) {
        deleteButton?.command = command
    }

    func setBiometricCommand(_ command: Command) {
        deviceOwnerAuthButton?.command = command
    }
}
