//
//  Created on 30/08/2018
//  Copyright © Vladimir Benkevich 2018
//

import XCTest
@testable import Utils

class TaskGroupTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testEmpty() {
        let whenAll = expectation(description: "when all")
        let whenAny = expectation(description: "when any")

        let group = TaskGroup([])

        group.whenAny {
            XCTAssertTrue(group === $0)
            whenAny.fulfill()
        }
        group.whenAll {
            XCTAssertTrue(group === $0)
            whenAll.fulfill()
        }

        wait(for: [whenAny, whenAll], timeout: 1)
    }
    
    func testWhenAllAny() {
        let expAll = expectation(description: "when all")
        let expAny = expectation(description: "when any")
        let expTask1 = expectation(description: "task 1")
        let expTask2 = expectation(description: "task 2")

        let tcs1 = Task<Int>.Source()
        let tcs2 = Task<String>.Source()

        tcs1.task.notify { _ in
            expTask1.fulfill()
            try! tcs2.complete("2")
        }

        tcs2.task.notify { _ in
            expTask2.fulfill()
        }

        let group = TaskGroup([tcs1.task, tcs2.task])
        group.whenAll { _ in
            expAll.fulfill()
        }
        group.whenAny { _ in
            expAny.fulfill()
        }

        try! tcs1.complete(1)

        wait(for: [expTask1, expAny, expTask2, expAll], timeout: 1, enforceOrder: true)
    }

    func testCancelErrorComplete() {
        let expAll = expectation(description: "when all")
        let expAny = expectation(description: "when any")

        let tcsCompl = Task<String>.Source()
        let tcsCancel = Task<String>.Source()
        let tcsError = Task<String>.Source()

        [tcsCompl.task, tcsError.task, tcsCancel.task].whenAll { _ in
            expAll.fulfill()
        }

        [tcsCompl.task, tcsError.task, tcsCancel.task].whenAny { _ in
            expAny.fulfill()
        }

        try! tcsCompl.complete("complete")
        try! tcsCancel.cancel()
        try! tcsError.error(TestError())

        wait(for: [expAny, expAll], timeout: 1)
    }

    func testCompletedTasks() {
        let expAll = expectation(description: "when all")
        let expAny = expectation(description: "when any")
        let expTask1 = expectation(description: "task 1")
        let expTask2 = expectation(description: "task 2")

        let tcs1 = Task<Int>.Source()
        let tcs2 = Task<String>.Source()

        try! tcs1.complete(1)

        tcs1.task.notify { _ in
            expTask1.fulfill()
        }

        tcs2.task.notify { _ in
            expTask2.fulfill()
        }

        let group = TaskGroup([tcs1.task, tcs2.task])
        group.whenAll { _ in
            expAll.fulfill()
        }
        group.whenAny { _ in
            expAny.fulfill()
        }

        try! tcs2.complete("2")

        wait(for: [expTask1, expAny, expTask2, expAll], timeout: 1, enforceOrder: true)
    }

    func testGroupDelegate() {
        let expTask1 = expectation(description: "task 1")
        let expTask2 = expectation(description: "task 2")

        let tcs0 = Task<Bool>.Source()
        let tcs1 = Task<Int>.Source()
        let tcs2 = Task<String>.Source()

        try! tcs0.complete(true)

        let group = TaskGroup([tcs0.task, tcs1.task, tcs2.task])
        let delegate = TestGroupDelegate {
            XCTAssertTrue($0 === group)
            XCTAssertFalse($1 === tcs0.task)

            if $1 === tcs1.task {
                expTask1.fulfill()
            }
            if $1 === tcs2.task {
                expTask2.fulfill()
            }
        }
        group.delegate = delegate

        try! tcs1.complete(1)
        try! tcs2.error(TestError())

        wait(for: [expTask1, expTask2], timeout: 1)
        XCTAssertEqual(delegate.count, 2)
    }

    class TestGroupDelegate: TaskGroupDelegate {

        var count = 0

        private let assertsBlock: (TaskGroup, NotifyCompletion) -> Void

        init(assertsBlock: @escaping (TaskGroup, NotifyCompletion) -> Void) {
            self.assertsBlock = assertsBlock
        }

        func taskFinished(group: TaskGroup, task: NotifyCompletion) {
            count += 1
            assertsBlock(group, task)
        }
    }
}
