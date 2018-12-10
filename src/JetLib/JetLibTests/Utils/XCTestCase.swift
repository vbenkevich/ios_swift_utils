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

extension XCTestCase {

    func sync(with queue: DispatchQueue = DispatchQueue.main, timeout: TimeInterval = TimeInterval(1)) {
        let exp = expectation(description: "sync with: \(queue)")
        queue.async(flags: .barrier) {
            exp.fulfill()
        }
        wait(for: [exp], timeout: timeout)
    }
}
