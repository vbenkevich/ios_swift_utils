//
//  Created on 29/09/2018
//  Copyright © Vladimir Benkevich 2018
//

import UIKit

public protocol ControllerPresenter: class {

    var currentController: UIViewController? { get set }
}

open class ContainerViewController: UIViewController, ControllerPresenter {

    public var currentController: UIViewController? {
        didSet {
            if isBeingPresented {
                oldValue?.beginAppearanceTransition(false, animated: false)
                currentController?.beginAppearanceTransition(true, animated: false)
            }

            oldValue?.willMove(toParent: nil)

            if let newValue = currentController {
                addChild(newValue)
                newValue.view.frame = view.bounds
                newValue.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                newValue.view.translatesAutoresizingMaskIntoConstraints = true
                view.addSubview(newValue.view)
            }
            title = currentController?.title
            oldValue?.view.removeFromSuperview()

            oldValue?.removeFromParent()
            currentController?.didMove(toParent: self)

            if isBeingPresented {
                currentController?.endAppearanceTransition()
                oldValue?.endAppearanceTransition()
            }
        }
    }
}
