//
//  Created on 18/03/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation

public protocol PinpadViewFactory {

    func createController(_ viewModel: PincodeViewModel) -> UIViewController
}

open class PinpadViewFactoryDefault: PinpadViewFactory {

    public init() {}

    open func createController(_ viewModel: PincodeViewModel) -> UIViewController {
        let contoller = PincodeController()
        contoller.viewModel = viewModel
        contoller.pinpad = createPinpad(viewModel)
        return contoller
    }

    open func createPinpad(_ viewModel: PincodeViewModel) -> UIView & Pinpad {
        let view = PincodeView()
        view.load(self, config: viewModel.config)
        return view
    }

    open var showDeviceOwnerAuthImmidately: Bool = true

    open var color: UIColor = UIColor.white

    open var dotSize: CGSize = CGSize(width: 24, height: 24)

    open var dotButtonsSpacing: CGFloat = 32

    open var verticalSpacing: CGFloat = 16

    open var horizontalSpacing: CGFloat = 16

    open func createButton(number: Int) -> UIButton {
        let button = RoundedButton(type: .custom)
        button.setTitleColor(color, for: .normal)
        button.setTitle(number.description, for: .normal)
        button.setBackgroundImage(color.withAlphaComponent(0.2).toImage(), for: .normal)
        button.setBackgroundImage(UIColor.clear.toImage(), for: .highlighted)
        button.layer.borderWidth = 1
        button.layer.borderColor = color.withAlphaComponent(0.5) .cgColor
        button.clipsToBounds = true
        button.widthAnchor.constraint(equalTo: button.heightAnchor).isActive = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    open func createFilledDot() -> UIView {
        let view = RoundedView()
        view.backgroundColor = color
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.widthAnchor.constraint(equalToConstant: dotSize.width).isActive = true
        view.heightAnchor.constraint(equalToConstant: dotSize.height).isActive = true
        return view
    }

    open func createEmptyDot() -> UIView {
        let view = RoundedView()
        view.backgroundColor = UIColor.clear
        view.layer.borderWidth = 1
        view.layer.borderColor = color.cgColor
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.widthAnchor.constraint(equalToConstant: dotSize.width).isActive = true
        view.heightAnchor.constraint(equalToConstant: dotSize.height).isActive = true
        return view
    }

    open func createDeleteButton() -> UIButton {
        let button = UIButton(type: .custom)
        button.setTitle("del", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    open func createFaceIdButton() -> UIButton {
        let button = UIButton(type: .custom)
        button.setTitle("faceId", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    open func createTouchIdButton() -> UIButton {
        let button = UIButton(type: .custom)
        button.setTitle("touchId", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    open func createOtherIdButton() -> UIButton {
        let button = UIButton(type: .custom)
        button.setTitle("unknown auth", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
}
