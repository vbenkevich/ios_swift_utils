//
//  Created on 22/08/2018
//  Copyright © Vladimir Benkevich 2018
//

import XCTest
@testable import JetLib

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

        task.notify(queue: notifyQueue) {
            XCTAssertEqual($0.result, result1)
            XCTAssertEqual($0.status, .success(result1))
            notifyTask1.fulfill()
        }
        .chain(nextTask: createSecondTask)
        .notify(queue: notifyQueue) {
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
            XCTAssertEqual($0, result1)
            createTask2.fulfill()
            return Task<String>(result2)
        }

        task1.notify(queue: notifyQueue) {
            XCTAssertTrue($0.isSuccess)
            XCTAssertTrue($0.isCompleted)
            XCTAssertFalse($0.isCancelled)
            XCTAssertFalse($0.isFailed)
            notifyTask1.fulfill()
        }
        task2.notify(queue: notifyQueue) {
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

        task.notify(queue: notifyQueue) { _ in singleExpectation.fulfill() }
        let _: Task<String> = task.chainOnSuccess { _ in
            singleExpectation.fulfill()
            return Task("1")
        }.notify(queue: notifyQueue) {
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
        let task = Task<Int> { throw error }.notify(queue: notifyQueue) { _ in singleExpectation.fulfill() }
        let _: Task<String> = task.chainOnSuccess { _ in
            singleExpectation.fulfill()
            return Task("1")
        }.notify(queue: notifyQueue) {
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
        let exp = expectation(description: "expectation")
        let result = 10
        let task = Task(result)
        let sameTask = task.onSuccess {
            XCTAssertEqual(result, $0)
            exp.fulfill()
        }

        XCTAssert(task === sameTask)

        wait(exp)
    }

    func testNotifyOnSuccessOnly() {
        let exp = expectation(description: "expectation")
        let result = 10

        Task(result).onSuccess { _ in
            exp.fulfill()
        }.onCancel {
            exp.fulfill()
        }.onFail { _ in
            exp.fulfill()
        }

        wait(exp)
    }

    func testNotifyOnFaill() {
        let exp = expectation(description: "expectation")
        let error = TestError()
        let task = Task<Int> {
            throw error
        }

        let sameTask = task.onFail {
            XCTAssertEqual(error, $0 as? TestError)
            exp.fulfill()
        }

        XCTAssert(task === sameTask)

        executeQueue.async(task)

        wait(exp)
    }

    func testNotifyOnFailOnly() {
        let exp = expectation(description: "expectation")
        let error = TestError()
        let task = Task<Int> {
            throw error
        }

        task.onSuccess { _ in
            exp.fulfill()
        }.onCancel {
            exp.fulfill()
        }.onFail { _ in
            exp.fulfill()
        }

        executeQueue.async(task)

        wait(exp)
    }

    func testNotifyOnCancel() {
        let exp = expectation(description: "expectation")
        let error = TestError()
        let task = Task<Int> {
            throw error
        }

        let sameTask = task.onCancel {
            exp.fulfill()
        }

        XCTAssert(task === sameTask)

        XCTAssertNoThrow(try task.cancel())

        wait(exp)
    }

    func testNotifyOnCancelOnly() {
        let exp = expectation(description: "expectation")
        let error = TestError()
        let task = Task<Int> {
            throw error
        }

        task.onSuccess { _ in
            exp.fulfill()
        }.onCancel {
            exp.fulfill()
        }.onFail { _ in
            exp.fulfill()
        }

        XCTAssertNoThrow(try task.cancel())

        wait(exp)
    }

    func testMapSuccess() {
        let exp = expectation(description: "expectation")
        let result = 10
        let mappedResult = "mapped result"
        let task = Task(result)

        let mapped = task.map { _ in
            return mappedResult
        }

        mapped.notify { _ in
            exp.fulfill()
        }

        wait(exp)

        XCTAssertEqual(mapped.result, mappedResult)

        XCTAssertFalse(mapped.isCancelled)
        XCTAssertFalse(mapped.isFailed)

        XCTAssertTrue(mapped.isCompleted)
        XCTAssertTrue(mapped.isSuccess)

        XCTAssertNil(mapped.error)
    }

    func testMapFail() {
        let exp = expectation(description: "expectation")
        let mappedResult = "mapped result"
        let error = TestError()
        let task = Task<Int> {
            throw error
        }

        let mapped = task.map { _ in
            return mappedResult
        }

        mapped.notify { _ in
            exp.fulfill()
        }

        executeQueue.async(task)

        wait(exp)

        XCTAssertNil(mapped.result)

        XCTAssertFalse(mapped.isCancelled)
        XCTAssertFalse(mapped.isSuccess)

        XCTAssertTrue(mapped.isFailed)
        XCTAssertTrue(mapped.isCompleted)

        XCTAssertEqual(mapped.error as? TestError, error)
    }

    func testMapCancelSource() {
        let exp = expectation(description: "expectation")
        let mappedResult = "mapped result"
        let error = TestError()
        let task = Task<Int> {
            throw error
        }

        let mapped = task.map { _ in
            return mappedResult
        }

        mapped.notify { _ in
            exp.fulfill()
        }

        XCTAssertNoThrow(try task.cancel())

        wait(exp)

        XCTAssertNil(mapped.result)

        XCTAssertFalse(mapped.isFailed)
        XCTAssertFalse(mapped.isSuccess)

        XCTAssertTrue(mapped.isCancelled)
        XCTAssertTrue(mapped.isCompleted)

        XCTAssertNil(mapped.error)
    }

    func testMapCancelMapped() {
        let exp = expectation(description: "expectation")
        let mappedResult = "mapped result"
        let error = TestError()
        let task = Task<Int> {
            throw error
        }

        let mapped = task.map { _ in
            return mappedResult
        }

        mapped.notify { _ in
            exp.fulfill()
        }

        XCTAssertNoThrow(try mapped.cancel())

        wait(exp)

        XCTAssertNil(mapped.result)

        XCTAssertFalse(mapped.isFailed)
        XCTAssertFalse(mapped.isSuccess)

        XCTAssertTrue(mapped.isCancelled)
        XCTAssertTrue(mapped.isCompleted)

        XCTAssertNil(mapped.error)
    }


    func testMapConverterThrow() {
        let exp = expectation(description: "expectation")
        let result = 10
        let error = TestError()
        let task = Task(result)

        let mapped = task.map { _ in
            throw error
        }

        mapped.notify { _ in
            exp.fulfill()
        }

        wait(exp)

        XCTAssertNil(mapped.result)

        XCTAssertFalse(mapped.isCancelled)
        XCTAssertFalse(mapped.isSuccess)

        XCTAssertTrue(mapped.isFailed)
        XCTAssertTrue(mapped.isCompleted)

        XCTAssertEqual(mapped.error as? TestError, error)
    }
}
