//
//  Created on 03/04/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation
import UIKit

public extension UIScrollView {

    var totalContentInsets: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return adjustedContentInset + contentInset
        } else {
            return contentInset
        }
    }
}

