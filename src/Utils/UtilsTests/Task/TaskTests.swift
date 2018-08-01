//
//  TaskTests.swift
//  UtilsTests
//
//  Created by Vladimir Benkevich on 01/08/2018.
//

import XCTest

class TaskTests: XCTestCase {

    let executeQueue = DispatchQueue(label: "task.execute", qos: .default)
    let notifyQueue = DispatchQueue(label: "task.notify", qos: .default)

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testPositiveLifeCycle() {
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
        XCTAssertEqual(task.status, .success(result: 1))
    }

    func testCancelRunningLifeCycle() {
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
