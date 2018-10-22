//
//  Created on 17/10/2018
//  Copyright © Vladimir Benkevich 2018
//

import XCTest
@testable import JetLib

class ObservableTests: XCTestCase {

    override func setUp() {
    }

    override func tearDown() {
    }

    func testSimpleNotify() {
        let newValue = "123"
        let stringObservable = Observable<String>()
        let notify = expectation(description: "notify")

        stringObservable.notify(self) {
            XCTAssertEqual($0, self)
            XCTAssertEqual($1, newValue)
            notify.fulfill()
        }

        stringObservable.value = newValue

        wait(notify)
    }

    func testNotifyManyListeners() {
        let newValue = "1234"
        let stringObservable = Observable<String>()
        let notify = expectation(description: "notify")
        notify.expectedFulfillmentCount = 2

        stringObservable.notify(self) { _,_ in
            notify.fulfill()
        }

        stringObservable.notify(self) { _,_ in
            notify.fulfill()
        }

        stringObservable.value = newValue

        wait(notify)
    }

    func testNotifyMultipleValues() {
        let observable = Observable<Int>()
        let semaphore = DispatchSemaphore(value: 0)
        let queue = DispatchQueue.global(qos: .userInitiated)

        class Target {
            var expected = [123, 111, 234, 99]
            var counter = 0
        }

        let target = Target()

        observable.notify(target, queue) {
            XCTAssertEqual(target.expected[target.counter], $1)
            $0.counter += 1
            semaphore.signal()
        }

        while target.counter < target.expected.count {
            observable.value = target.expected[target.counter]

            if semaphore.wait(timeout: .now() + .milliseconds(100)) == .timedOut {
                break
            }
        }

        XCTAssertEqual(target.counter, target.expected.count)
    }

    func testWeakTarget() {
        class Target {}

        let observable = Observable<Int>()
        let exp = expectation(description: "notify shouldn't trigger")

        var targetStrong: Target! = Target()
        weak var targetWeak = targetStrong

        observable.notify(targetStrong, callBack: { _, _ in
            exp.fulfill()
        })

        // faster than exp.isInverted = true
        exp.fulfill()
        targetStrong = nil
        XCTAssertNil(targetWeak)
        observable.value = 10

        wait(exp)
    }
}
