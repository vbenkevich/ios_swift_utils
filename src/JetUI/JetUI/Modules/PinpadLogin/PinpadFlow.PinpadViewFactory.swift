//
//  Created on 07/02/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation
import JetLib

public extension PinpadFlow {

    open class PinpadViewFactory {

        open func createWidget() -> PinpadWidget {
            let widget = PinpadWidget()
            widget.service = PinpadFlow.Service(pincodeService: PinpadFlow.PincodeStorage(),
                                                authService: PinpadFlow.DeviceOwnerAuth())
            return PinpadWidget()
        }

        open func createViews() -> (UIViewController, PinpadWidget) {
            let widget = createWidget()
            return (UIViewController(), widget)
        }
    }
}
