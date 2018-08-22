//
//  TaskSourceTests.swift
//
//  Created by Vladimir Benkevich
//  Copyright © 2018
//

import XCTest
@testable import Utils

class TaskSourceTests: XCTestCase {

    let testError1 = TestError()
    let testError2 = TestError()
    let expectedResult = "expected result"
    let expectedResult2 = "expected result2"
    let executeQueue = DispatchQueue(label: "task.execute", qos: .default)
    let notifyQueue = DispatchQueue(label: "task.notify", qos: .default)

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCreateSource() {
        let source = Task<String>.Source()
        XCTAssertEqual(source.task.status, Task.Status.executing)
        XCTAssertEqual(source.task.result, nil)
    }

    func testComplete() {
        let source = Task<String>.Source()

        XCTAssertNoThrow(try source.complete(expectedResult))
        XCTAssertEqual(source.task.status, Task.Status.success(expectedResult))
        XCTAssertEqual(source.task.result, expectedResult)
    }

    func testCompleteIsFiniteState() {
        let source = Task<String>.Source()

        XCTAssertNoThrow(try source.complete(expectedResult))

        XCTAssertThrowsError(try source.complete(expectedResult2))
        XCTAssertThrowsError(try source.cancel())
        XCTAssertThrowsError(try source.error(testError1))

        XCTAssertEqual(source.task.status, Task.Status.success(expectedResult))
        XCTAssertEqual(source.task.result, expectedResult)
    }

    func testCancel() {
        let source = Task<String>.Source()

        XCTAssertNoThrow(try source.cancel())
        XCTAssertEqual(source.task.status, Task.Status.cancelled)
        XCTAssertEqual(source.task.result, nil)
    }

    func testCancelProxy() {
        let source = Task<String>.Source()

        XCTAssertNoThrow(try source.task.cancel())
        XCTAssertEqual(source.task.status, Task.Status.cancelled)
        XCTAssertEqual(source.task.result, nil)
    }

    func testCancelIsFiniteState() {
        let source = Task<String>.Source()

        XCTAssertNoThrow(try source.cancel())

        XCTAssertThrowsError(try source.complete(expectedResult))
        XCTAssertThrowsError(try source.error(testError1))
        XCTAssertThrowsError(try source.task.cancel())

        XCTAssertEqual(source.task.status, Task.Status.cancelled)
        XCTAssertEqual(source.task.result, nil)
    }

    func testError() {
        let source = Task<String>.Source()

        XCTAssertNoThrow(try source.error(testError1))
        XCTAssertEqual(source.task.status, Task.Status.failed(testError1))
        XCTAssertEqual(source.task.result, nil)
    }

    func testErrorIsFiniteState() {
        let source = Task<String>.Source()

        XCTAssertNoThrow(try source.error(testError1))

        XCTAssertThrowsError(try source.error(testError2))
        XCTAssertThrowsError(try source.complete(expectedResult))
        XCTAssertThrowsError(try source.cancel())

        XCTAssertEqual(source.task.status, Task.Status.failed(testError1))
        XCTAssertEqual(source.task.result, nil)
    }

    func testNotifyCompleted() {
        let source = Task<String>.Source()
        let notify = expectation(description: "notify")

        source.task.notify(notifyQueue) {
            XCTAssert($0 === source.task)
            notify.fulfill()
        }

        XCTAssertNoThrow(try source.complete(expectedResult))
        wait(for: [notify], timeout: 1)
    }

    func testNotifyCancelled() {
        let source = Task<String>.Source()
        let notify = expectation(description: "notify")

        source.task.notify(notifyQueue) {
            XCTAssert($0 === source.task)
            notify.fulfill()
        }

        XCTAssertNoThrow(try source.cancel())
        wait(for: [notify], timeout: 1)
    }

    func testNotifyTaskCancelled() {
        let source = Task<String>.Source()
        let notify = expectation(description: "notify")

        source.task.notify(notifyQueue) {
            XCTAssert($0 === source.task)
            notify.fulfill()
        }

        XCTAssertNoThrow(try source.task.cancel())
        wait(for: [notify], timeout: 1)
    }

    func testNotifyFailed() {
        let source = Task<String>.Source()
        let notify = expectation(description: "notify")

        source.task.notify(notifyQueue) {
            XCTAssert($0 === source.task)
            notify.fulfill()
        }

        XCTAssertNoThrow(try source.error(testError1))
        wait(for: [notify], timeout: 1)
    }

    func testNotifyCallbackFireOnes() {
        let source = Task<String>.Source()
        let notify = expectation(description: "notify")

        source.task.notify(notifyQueue) {
            XCTAssert($0 === source.task)
            notify.fulfill()
        }

        XCTAssertNoThrow(try source.cancel())
        XCTAssertThrowsError(try source.error(testError2))
        XCTAssertThrowsError(try source.cancel())
        XCTAssertThrowsError(try source.complete(expectedResult))

        wait(for: [notify], timeout: 1)
    }

    func testNotifyAfterCompletinon() {
        let source = Task<String>.Source()
        let notify = expectation(description: "notify")

        XCTAssertNoThrow(try source.complete(expectedResult))

        source.task.notify(notifyQueue) {
            XCTAssert($0 === source.task)
            notify.fulfill()
        }

        wait(for: [notify], timeout: 1)
    }

    func testNotifayManyCallbacks() {
        let source = Task<String>.Source()
        let notify1 = expectation(description: "callback1")
        let notify2 = expectation(description: "callback2")
        let notify3 = expectation(description: "callback after finish")

        source.task.notify(notifyQueue) {
            XCTAssert($0 === source.task)
            notify1.fulfill()
        }

        source.task.notify(notifyQueue) {
            XCTAssert($0 === source.task)
            notify2.fulfill()
        }

        XCTAssertNoThrow(try source.complete(expectedResult))

        source.task.notify(notifyQueue) {
            XCTAssert($0 === source.task)
            notify3.fulfill()
        }

        wait(for: [notify1, notify2, notify3], timeout: 1)
    }

    class TestError: Error {
    }
}
