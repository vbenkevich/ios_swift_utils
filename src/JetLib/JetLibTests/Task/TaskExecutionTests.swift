//
//  Created on 22/08/2018
//  Copyright © Vladimir Benkevich 2018
//

import XCTest
@testable import JetLib

class TaskExecutionTests: XCTestCase {

    var executeQueue: DispatchQueue!
    var notifyQueue: DispatchQueue!

    override func setUp() {
        super.setUp()
        notifyQueue = DispatchQueue(label: "task.notify", qos: .default)
        executeQueue = DispatchQueue(label: "task.execute", qos: .default)
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testCompletedTaskCreation() {
        let result = "completed"
        let task = Task(result)

        XCTAssertEqual(task.result, result)
        XCTAssertEqual(task.status, .success(result))
    }

    func testCompletedUnableToCancel() {
        let task = Task("completed")
        XCTAssertThrowsError(try task.cancel())
    }

    func testCompletedTaskNotify() {
        let notify = expectation(description: "notify")
        let result = "completed"
        let task = Task(result)

        task.notify(queue: notifyQueue) {
            XCTAssertEqual($0.result, result)
            XCTAssertEqual($0.status, .success(result))
            XCTAssert($0 === task)
            notify.fulfill()
        }

        wait(for: [notify], timeout: 1)
    }

    func testActionTaskNotify() {
        let notify = expectation(description: "notify")

        let task = Task<Int> {
            return 1
        }
        task.notify(queue: notifyQueue) {
            XCTAssertEqual($0.result, 1)
            XCTAssertEqual($0.status, .success(1))
            XCTAssert($0 === task)
            notify.fulfill()
        }

        executeQueue.async(task)

        wait(for: [notify], timeout: 1)
    }

    func testActionTaskErrorNotify() {
        let notify = expectation(description: "notify")
        let error = TestError()

        let task = Task<Int> {
            throw error
        }
        task.notify(queue: notifyQueue) {
            XCTAssertEqual($0.result, nil)
            XCTAssertEqual($0.status, .failed(error))
            XCTAssert($0 === task)
            notify.fulfill()
        }

        executeQueue.async(task)

        wait(for: [notify], timeout: 1)
    }

    func testMultiNotify() {
        let notify1 = expectation(description: "notify1")
        let notify2 = expectation(description: "notify2")

        let task = Task<Int> {
            return 1
        }.notify(queue: notifyQueue) { _ in
            notify1.fulfill()
        }.notify(queue: notifyQueue) { _ in
            notify2.fulfill()
        }

        executeQueue.async(task)

        wait(for: [notify1, notify2], timeout: 1)
        XCTAssertEqual(task.status, .success(1))
    }

    func testStatusRunComplete() {
        let started = expectation(description: "started")
        let completed = expectation(description: "completed")

        let task = Task<Int> {
            started.fulfill()
            return 1
        }

        task.notify(queue: executeQueue) { _ in
            completed.fulfill()
        }

        executeQueue.async(task)

        wait(for: [started, completed], timeout: 1, enforceOrder: true)
    }

    func testStatusRunCompleteDelayed() {
        let started = expectation(description: "started")
        let completed = expectation(description: "completed")

        let task = Task<Int> {
            started.fulfill()
            return 1
        }

        task.notify(queue: executeQueue) { _ in
            completed.fulfill()
        }

        executeQueue.async(task, after: .milliseconds(1))

        wait(for: [started, completed], timeout: 1, enforceOrder: true)
    }

    func testStatusCancelRun() {
        let notify = expectation(description: "notify")

        let task = Task<Int> {
            return 1
        }.notify(queue: notifyQueue) {
            XCTAssertEqual($0.result, nil)
            XCTAssertEqual($0.status, .cancelled)
            notify.fulfill()
        }

        try! task.cancel()

        executeQueue.async(task)

        wait(for: [notify], timeout: 1)
        XCTAssertEqual(task.status, .cancelled)
    }

    func testStatusRunCancel() {
        let started = expectation(description: "started")
        let cancelled = expectation(description: "cancelled")

        let semafore = DispatchSemaphore(value: 0)

        let task = Task<Int> {
            started.fulfill()
            semafore.wait()
            return 1
        }

        task.notify(queue: notifyQueue) { _ in
            cancelled.fulfill()
        }

        executeQueue.async(task)

        wait(for: [started], timeout: 1)

        try! task.cancel()

        wait(for: [cancelled], timeout: 1)
        XCTAssertEqual(task.status, .cancelled)

        semafore.signal()
    }

    func testAwaitSuccess() {
        let task = Task<Int> {
            return 1
        }

        XCTAssertNoThrow(try executeQueue.await(task: task))
        XCTAssertEqual(task.result, 1)
        XCTAssertEqual(task.status, .success(1))
    }

    func testAwaitError() {
        let error = TestError()

        let task = Task<Int> {
            throw error
        }

        XCTAssertThrowsError(try executeQueue.await(task: task))
        XCTAssertEqual(task.result, nil)
        XCTAssertEqual(task.status, .failed(error))
    }

    func testAwaitCancel() {
        let error = TestError()
        let semafore = DispatchSemaphore(value: 0)
        let cancelled = expectation(description: "cancelled")
        let cancelledError = expectation(description: "cancelledErrors")

        let task = Task<Int> {
            semafore.wait()
            throw error
        }

        notifyQueue.async {
            do {
                try self.executeQueue.await(task: task)
            } catch is TaskException {
                XCTAssertEqual(task.status, .cancelled)
                cancelledError.fulfill()
            } catch {}

            XCTAssertEqual(task.result, nil)
            XCTAssertEqual(task.status, .cancelled)
            cancelled.fulfill()
        }

        try! task.cancel()

        wait(for: [cancelledError, cancelled], timeout: 1)
    }
}
