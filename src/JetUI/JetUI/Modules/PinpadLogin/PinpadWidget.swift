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

    func check(pincode: String) -> Task<Bool>
    func checkFaceId() -> Task<Bool>
    func checkTouchId() -> Task<Bool>
}

open class PinpadWidget: UIView {

    open weak var delegate: PinpadDelegate? {
        didSet {
            pinCodeView.setup(delegate: delegate, configuration: configuration)
        }
    }

    public var configuration: PinpadConfiguration = DefaultConfiguration() {
        didSet {
            reloadView()
        }
    }

    var pincode: String = "" {
        didSet {
            pinCodeView.pincode = pincode
        }
    }

    var rootView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            guard let content = rootView else { return }

            content.translatesAutoresizingMaskIntoConstraints = false
            addSubview(content)
            content.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            content.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
            content.topAnchor.constraint(equalTo: topAnchor).isActive = true
            content.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

            superview?.setNeedsLayout()
        }
    }

    var deleteCommand: Command?
    var appendCommand: Command?
    var biometricCommand: Command?

    var pinCodeView: PincodeView = PincodeView()
    var biometricView: UIView!
    var biometricButton: UIButton!
    var deleteButton: UIButton!
    var numberButtons: [UIButton] = []


    open override func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview != nil && rootView == nil {
            reloadView()
        }
    }

    func reloadView() {
        let buttons = createButtonsView()
        let rootStack = UIStackView(arrangedSubviews: [pinCodeView, buttons])
        rootStack.axis = .vertical
        rootStack.alignment = .center
        rootStack.spacing = configuration.dotButtonsSpacing
        buttons.widthAnchor.constraint(equalTo: rootStack.widthAnchor).isActive = true

        rootView = rootStack

        deleteButton.command = deleteCommand
        //biometricButton.command = biometricCommand

        for i in 0...9 {
            numberButtons[i].command = appendCommand
            numberButtons[i].commanParameter = i
        }

        appendCommand?.delegate = nil
    }

    func append(symbol: String) {
        pincode += symbol
    }

    func canAppend(symbol: String) -> Bool {
        guard let maxCount = delegate?.symbolsCount else {
            return false
        }

        return pincode.count < maxCount
    }

    func delete() {
        pincode = String(pincode.prefix(pincode.count - 1))
    }

    func canDelete() -> Bool {
        guard let maxCount = delegate?.symbolsCount else {
            return false
        }

        return !pincode.isEmpty && pincode.count < maxCount
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

extension PinpadWidget {

    class PincodeView: UIStackView {

        var count: Int = 0
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

        convenience init() {
            self.init(arrangedSubviews: [])
            self.axis = .horizontal
            self.distribution = .fillEqually
        }

        var pincode: String = "" {
            didSet {
                for index in 0..<emptyViews.count {
                    emptyViews[index].isHidden = index >= pincode.count
                    filledViews[index].isHidden = index < pincode.count
                }
            }
        }

        func setup(delegate: PinpadDelegate?, configuration: PinpadConfiguration) {
            guard let delegate = delegate else { return }

            spacing = configuration.horizontalSpacing
            filledViews = (0..<delegate.symbolsCount).map { _ in configuration.createFilledDot() }
            emptyViews = (0..<delegate.symbolsCount).map { _ in configuration.createEmptyDot() }
        }
    }
}
