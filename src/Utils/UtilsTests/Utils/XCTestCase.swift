//
//  Created on 30/08/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation
import XCTest

extension XCTestCase {

    func wait(_ expectations: XCTestExpectation...) {
        self.wait(for: expectations, timeout: 1)
    }
}
