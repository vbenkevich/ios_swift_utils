//
//  Created on 30/08/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation
import XCTest

extension XCTestCase {

    func wait(_ expectation: XCTestExpectation) {
        self.wait(for: [expectation], timeout: 1)
    }
}
