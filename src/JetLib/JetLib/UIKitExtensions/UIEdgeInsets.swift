//
//  Created on 03/04/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation

public extension UIEdgeInsets {

    static func + (left: UIEdgeInsets, right: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets(top: left.top + right.top,
                            left: left.left + right.right,
                            bottom: left.bottom + right.bottom,
                            right: left.right + right.right)
    }

    static func - (left: UIEdgeInsets, right: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets(top: left.top - right.top,
                            left: left.left - right.right,
                            bottom: left.bottom - right.bottom,
                            right: left.right - right.right)
    }

    static prefix func - (right: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets(top: -right.top,
                            left: -right.right,
                            bottom: -right.bottom,
                            right: -right.right)
    }
}
