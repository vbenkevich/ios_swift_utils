//
//  Created on 07/02/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation
import JetLib

public protocol PinpadFlowViewFactory {

    func createViews() -> (UIViewController, PinpadWidget)
}

public extension PinpadFlow {

    open class PinpadDefaultViewFactory: PinpadFlowViewFactory {

        public var backgroundImage: UIImage?
        public var headerImage: UIImage?

        open func createWidget() -> PinpadWidget {
            let widget = PinpadWidget()
            widget.service = PinpadFlow.WidgetService(pincodeService: PinpadFlow.PincodeStorage(),
                                                authService: PinpadFlow.DeviceOwnerAuth())
            return PinpadWidget()
        }

        open func createViews() -> (UIViewController, PinpadWidget) {
            let controller = PinpadViewControler()
            controller.widget = createWidget()
            controller.backgroundImage = backgroundImage
            controller.headerImage = headerImage

            return (controller, controller.widget)
        }

        class PinpadViewControler: UIViewController {

            var backgroundImage: UIImage?
            var headerImage: UIImage?
            var widget: PinpadWidget!

            override func loadView() {
                let root = UIImageView()
                root.contentMode = .scaleAspectFill
                root.image = backgroundImage

                let header = UIImageView()
                header.contentMode = .scaleAspectFit
                header.image = headerImage

                let stack = UIStackView()
                stack.translatesAutoresizingMaskIntoConstraints = false
                stack.axis = .vertical
                stack.spacing = PinpadWidget.defaultConfiguration.verticalSpacing
                stack.addArrangedSubview(header)
                stack.addArrangedSubview(widget)

                stack.centerXAnchor.constraint(equalTo: root.centerXAnchor).isActive = true
                stack.centerYAnchor.constraint(equalTo: root.centerYAnchor).isActive = true

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
