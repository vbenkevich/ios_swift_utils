//
//  Created on 07/02/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation
import JetLib

public protocol PinpadFlowViewControllerFactory {

    func create() -> UIViewController & PinpadViewController
}

public protocol PinpadViewController {

    var widget: PinpadWidget! { get }
}

public extension PinpadFlow {

    open class PinpadDefaultViewControllerFactory: PinpadFlowViewControllerFactory {

        public var backgroundView: UIView?
        public var headerView: UIView?

        open func createWidget() -> PinpadWidget {
            let widget = PinpadWidget()
            widget.service = PinpadFlow.WidgetService(pincodeService: PinpadFlow.PincodeStorage(),
                                                      authService: PinpadFlow.DeviceOwnerAuth())
            return widget
        }

        open func create() -> UIViewController & PinpadViewController {
            let controller = DefaultControler()
            controller.widget = createWidget()
            controller.backgroundView = backgroundView
            controller.headerView = headerView
            controller.modalPresentationStyle = .overFullScreen

            return controller
        }

        class DefaultControler: UIViewController, PinpadViewController {

            var backgroundView: UIView?
            var headerView: UIView?
            var widget: PinpadWidget!

            override func loadView() {
                let root = backgroundView ?? {
                    let view = UIView()
                    let effectView = UIVisualEffectView()
                    effectView.effect = UIBlurEffect(style: .light)
                    effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    effectView.frame = view.bounds
                    effectView.translatesAutoresizingMaskIntoConstraints = true
                    view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
                    view.addSubview(effectView)
                    return view
                }()

                let stack = UIStackView()
                stack.translatesAutoresizingMaskIntoConstraints = false
                stack.axis = .vertical
                stack.spacing = PinpadWidget.defaultConfiguration.verticalSpacing

                if let header = headerView {
                    stack.addArrangedSubview(header)
                }

                stack.addArrangedSubview(widget)

                root.addSubview(stack)

                stack.centerXAnchor.constraint(equalTo: root.centerXAnchor).isActive = true
                stack.centerYAnchor.constraint(equalTo: root.centerYAnchor).isActive = true
                stack.widthAnchor.constraint(equalTo: root.widthAnchor, multiplier: 0.67).isActive = true

                if #available(iOS 11.0, *) {
                    stack.topAnchor.constraint(greaterThanOrEqualTo: root.safeAreaLayoutGuide.topAnchor, constant: 24).isActive = true
                    stack.leftAnchor.constraint(greaterThanOrEqualTo: root.safeAreaLayoutGuide.leftAnchor, constant: 24).isActive = true
                } else {
                    stack.topAnchor.constraint(greaterThanOrEqualTo: root.topAnchor, constant: 24).isActive = true
                    stack.leftAnchor.constraint(greaterThanOrEqualTo: root.leftAnchor, constant: 24).isActive = true
                }

                view = root
            }
        }
    }
}
