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

        stringObservable.notify(self, fireRightNow: false) {
            XCTAssertEqual($0, self)
            XCTAssertEqual($1, newValue)
            notify.fulfill()
        }

        stringObservable.value = newValue

        wait(notify)
    }

    func testSameValuesOneNotify() {
        let newValue = "123"
        let stringObservable = Observable<String>()
        let notify = expectation(description: "notify")

        stringObservable.notify(self, fireRightNow: false) {
            XCTAssertEqual($0, self)
            XCTAssertEqual($1, newValue)
            notify.fulfill()
        }

        stringObservable.value = newValue
        stringObservable.value = newValue

        wait(notify)
    }

    func testNotifyManyListeners() {
        let newValue = "1234"
        let stringObservable = Observable<String>()
        let notify = expectation(description: "notify")
        notify.expectedFulfillmentCount = 3

        stringObservable.notify(self, fireRightNow: false) { _,_ in
            notify.fulfill()
        }

        stringObservable.notify(self, fireRightNow: true) { _,_ in
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

    func testThrottling() {
        let values = [1, 2, 3, 4, 5, 6]
        let observable = Observable(0).addThrottling(.milliseconds(100))

        let notify = expectation(description: "notify")
        notify.expectedFulfillmentCount = 1

        observable.notify(self, fireRightNow: false) {
            XCTAssertEqual($1, values.last!)
            notify.fulfill()
        }

        for value in values {
            observable.value = value
        }

        wait(notify)
    }

    func testWeakTarget() {
        class Target {}

        let observable = Observable<Int>()
        var targetStrong: Target! = Target()
        weak var targetWeak = targetStrong

        observable.notify(targetStrong, fireRightNow: false, callBack: { _, _ in
            XCTFail()
        })

        targetStrong = nil
        XCTAssertNil(targetWeak)
        observable.value = 10
    }
}
