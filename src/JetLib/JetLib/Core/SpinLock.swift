//
//  Created on 22/08/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

typealias SpinLock = os_unfair_lock

extension SpinLock {

    mutating func lock() {
        os_unfair_lock_lock(&self)
    }

    mutating func unlock() {
        os_unfair_lock_unlock(&self)
    }
}
