//
//  TaskExecutionTests.swift
//
//  Created by Vladimir Benkevich
//  Copyright © 2018
//

import XCTest

class TaskExecutionTests: XCTestCase {

    let executeQueue = DispatchQueue(label: "task.execute", qos: .default)
    let notifyQueue = DispatchQueue(label: "task.notify", qos: .default)

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testSimpleNotify() {
        let notify = expectation(description: "notify")

        let task = Task<Int> {
            return 1
        }
        task.notify(notifyQueue) {
            XCTAssertEqual($0.result, 1)
            XCTAssertEqual($0.status, .success(1))
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
        }.notify(notifyQueue) { _ in
            notify1.fulfill()
        }.notify(notifyQueue) { _ in
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

        task.notify(executeQueue) { _ in
            completed.fulfill()
        }

        executeQueue.async(task)

        wait(for: [started, completed], timeout: 1, enforceOrder: true)
    }

    func testStatusCancelRun() {
        let notify = expectation(description: "notify")

        let task = Task<Int> {
            return 1
        }.notify(notifyQueue) {
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

        task.notify(notifyQueue) { _ in
            cancelled.fulfill()
        }

        executeQueue.async(task)

        wait(for: [started], timeout: 1)

        try! task.cancel()

        wait(for: [cancelled], timeout: 1)
        XCTAssertEqual(task.status, .cancelled)

        semafore.signal()
    }
}
