//
//  Created on 31/10/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation
import UIKit

extension UILabel: BindingTarget {
    public typealias Value = String

    public var bindableValue: Any? {
        get { return self.text }
        set { self.text = newValue as? Value }
    }
}

extension UITextField: BindingTarget {
    public typealias Value = String

    public var bindableValue: Any? {
        get { return self.text }
        set { self.text = newValue as? Value }
    }
}
