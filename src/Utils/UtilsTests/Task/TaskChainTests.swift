//
//  Created on 22/08/2018
//  Copyright © Vladimir Benkevich 2018
//


import XCTest
@testable import Utils

class TaskChainTests: XCTestCase {

    var executeQueue: DispatchQueue!
    var notifyQueue: DispatchQueue!

    override func setUp() {
        super.setUp()
        executeQueue = DispatchQueue(label: "task.execute", qos: .default)
        notifyQueue = DispatchQueue(label: "task.notify", qos: .default)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testSimpleChain() {
        let notifyTask1 = expectation(description: "notify task1")
        let createTask2 = expectation(description: "create task2")
        let notifyTask2 = expectation(description: "notify task2")

        let result1 = 1
        let result2 = "2"

        let createSecondTask: (Task<Int>) -> Task<String> = { [executeQueue] (task: Task<Int>) in
            XCTAssertEqual(task.result, result1)
            XCTAssertEqual(task.status, .success(result1))
            createTask2.fulfill()

            return executeQueue!.async(Task {
                return result2
            })
        }

        let task = Task<Int> { return result1 }

        task.notify(notifyQueue) {
            XCTAssertEqual($0.result, result1)
            XCTAssertEqual($0.status, .success(result1))
            notifyTask1.fulfill()
        }
        .chain(nextTask: createSecondTask)
        .notify(notifyQueue) {
            XCTAssertEqual($0.result, result2)
            XCTAssertEqual($0.status, .success(result2))
            notifyTask2.fulfill()
        }

        executeQueue.async(task)

        wait(for: [notifyTask1, createTask2, notifyTask2], timeout: 1)
    }

    func testChainOnSuccessSuccess() {
        let result1 = 1
        let result2 = "2"
        let semafore = DispatchSemaphore(value: 1)

        let notifyTask1 = expectation(description: "notify task1")
        let createTask2 = expectation(description: "create task2")
        let notifyTask2 = expectation(description: "notify task2")

        let task1 = Task<Int> {
            semafore.wait()
            return result1
        }
        let task2: Task<String> = task1.chainOnSuccess {
            XCTAssertTrue($0.isSuccess)
            createTask2.fulfill()
            return Task<String>(result2)
        }

        task1.notify(notifyQueue) {
            XCTAssertTrue($0.isSuccess)
            XCTAssertTrue($0.isCompleted)
            XCTAssertFalse($0.isCancelled)
            XCTAssertFalse($0.isFailed)
            notifyTask1.fulfill()
        }
        task2.notify(notifyQueue) {
            XCTAssertEqual($0.result, result2)
            XCTAssertTrue($0.isSuccess)
            XCTAssertTrue($0.isCompleted)
            XCTAssertFalse($0.isCancelled)
            XCTAssertFalse($0.isFailed)
            notifyTask2.fulfill()
        }

        executeQueue.async(task1)

        wait(for: [notifyTask1, createTask2, notifyTask2], timeout: 1)
    }

    func testChainOnSuccessCancel() {
        let singleExpectation = expectation(description: "single")
        let task = Task<Int> { return 1 }
        try! task.cancel()

        task.notify(notifyQueue) { _ in singleExpectation.fulfill() }
        let _: Task<String> = task.chainOnSuccess { _ in
            singleExpectation.fulfill()
            return Task("1")
        }.notify(notifyQueue) {
            XCTAssertFalse($0.isSuccess)
            XCTAssertTrue($0.isCompleted)
            XCTAssertTrue($0.isCancelled)
            XCTAssertFalse($0.isFailed)
        }

        executeQueue.async(task)

        wait(singleExpectation)
    }

    func testChainOnSuccessError() {
        let singleExpectation = expectation(description: "single")
        let error = TestError()
        let task = Task<Int> { throw error }

        task.notify(notifyQueue) { _ in singleExpectation.fulfill() }
        let _: Task<String> = task.chainOnSuccess { _ in
            singleExpectation.fulfill()
            return Task("1")
        }.notify(notifyQueue) {
            XCTAssertFalse($0.isSuccess)
            XCTAssertTrue($0.isCompleted)
            XCTAssertFalse($0.isCancelled)
            XCTAssertTrue($0.isFailed)
            XCTAssertEqual($0.error as? TestError, error)
        }

        executeQueue.async(task)

        wait(singleExpectation)
    }

    func testNotifyOnSuccess() {
        XCTAssertFalse(true)
    }

    func testNotifyOnFail() {
        XCTAssertFalse(true)
    }

    func testNotifyOnCancel() {
        XCTAssertFalse(true)
    }

    func testMapSuccess() {
        XCTAssertFalse(true)
    }

    func testMapFailCancel() {
        XCTAssertFalse(true)
    }

    func testMapConverterThrow() {
        XCTAssertFalse(true)
    }
}
