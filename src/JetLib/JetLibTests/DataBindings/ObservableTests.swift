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

        observable.notify(target, fireRightNow: false, queue) {
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

    func testMergeObservablesInitialValueTest() {
        let first = Observable<String>()
        let second = Observable<Int>()
        let notify = expectation(description: "merged")
        let expected = Res(first: nil, second: nil)

        let merged = first.merge(with: second).notify(self, fireRightNow: true) { _, mergedResult in
            XCTAssertEqual(expected, mergedResult)
            notify.fulfill()
        }

        wait(notify)
    }

    func testMergeObservablesUpdatesSequence() {
        let first = Observable<String>()
        let second = Observable<Int>()
        let notify = [expectation(description: "first upd"),
                      expectation(description: "second upd"),
                      expectation(description: "second upd2")]
        var index = 0
        var expected = Res(first: nil, second: nil)

        let merged = first.merge(with: second).notify(self, fireRightNow: false) { _, mergedResult in
            XCTAssertEqual(expected, mergedResult)
            notify[index].fulfill()
            index += 1
        }

        expected = Res(first: "test value", second: expected.second)
        first.value = expected.first

        wait(notify[index])

        expected = Res(first: expected.first, second: 123)
        second.value = expected.second

        wait(notify[index])

        expected = Res(first: expected.first, second: 321)
        second.value = expected.second

        wait(notify[index])
    }

    func testMergeObservablesRetainSelf() {
        var first: Observable<String>! = Observable<String>()
        var second: Observable<Int>! = Observable<Int>()
        weak var firstRef = first
        weak var secondRef = second

        let merged = first?.merge(with: second, retainSelf: true, retainAnoher: false)
        first = nil
        second = nil

        XCTAssertNotNil(firstRef)
        XCTAssertNil(secondRef)
    }

    func testMergeObservablesRetainAnother() {
        var first: Observable<String>! = Observable<String>()
        var second: Observable<Int>! = Observable<Int>()
        weak var firstRef = first
        weak var secondRef = second

        let merged = first?.merge(with: second, retainSelf: false, retainAnoher: true)
        first = nil
        second = nil

        XCTAssertNil(firstRef)
        XCTAssertNotNil(secondRef)
    }
}

private typealias Res = Observable<String>.Merged<Int>
