//
//  Created on 12/10/2018
//  Copyright © Vladimir Benkevich 2018
//

import XCTest
@testable import JetLib

class AsyncCommandTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    fileprivate func createTestTask<T>(res: T, with expectation: XCTestExpectation? = nil) -> () -> Task<T> {
        return {
            Task(execute: {
                expectation?.fulfill()
                return res
            })
        }
    }

    func testExecute() {
        let execute = expectation(description: "execute")
        let created = expectation(description: "created")
        let command = AsyncCommand(task: createTestTask(res: 1, with: execute))

        created.fulfill()
        command.execute()

        wait(for: [created, execute], timeout: 1, enforceOrder: true)
    }

    func testCanExecuteTrue() {
        let execute = expectation(description: "execute")
        let created = expectation(description: "created")

        let command = AsyncCommand(task: createTestTask(res: 1, with: execute), canExecute: { return true })

        created.fulfill()
        command.execute()

        wait(for: [created, execute], timeout: 1, enforceOrder: true)
    }

    func testCanExecuteFalseTrue() {
        let execute = expectation(description: "execute")

        var canExecute = false

        let command = AsyncCommand(task: createTestTask(res: 1, with: execute), canExecute: { return canExecute })

        let testQueue = DispatchQueue(label: "test queue")
        command.executeQueue = testQueue
        command.callbackQueue = testQueue

        testQueue.async {
            command.execute()
            canExecute = true
            command.execute()
        }

        wait(execute)
    }

    func testSerialExecution() {
        let execute = expectation(description: "execute")
        let semaphore = DispatchSemaphore(value: 0)

        let taskFactory: () -> Task<Int> = {
            Task(execute: {
                execute.fulfill()
                semaphore.wait()
                return 1
            })
        }

        let command = AsyncCommand(task: taskFactory)

        command.executeQueue = DispatchQueue(label: "execute")
        command.callbackQueue = DispatchQueue(label: "callback")

        command.execute()
        command.execute()
        semaphore.signal()

        wait(execute)
    }

    func testExecuteGeneric() {
        let execute = expectation(description: "execute")
        let parameter = CommandParameter()

        let taskFactory: (CommandParameter) -> Task<Int> = { param in
            Task(execute: {
                XCTAssertEqual(param, parameter)
                execute.fulfill()
                return 1
            })
        }

        let command = AsyncCommand(task1: taskFactory)
        command.execute(parameter: parameter)

        wait(execute)
    }

    func testCanExecuteGeneric() {
        let execute = expectation(description: "execute")
        let parameter = CommandParameter()

        let taskFactory: (CommandParameter) -> Task<Int> = { param in
            Task(execute: {
                XCTAssertEqual(param, parameter)
                execute.fulfill()
                return 1
            })
        }

        let command = AsyncCommand(task1: taskFactory, canExecute: { (param: CommandParameter) in
            return true
        })

        command.execute(parameter: parameter)

        wait(execute)
    }

    func testGenericWrongType() {
        let execute = expectation(description: "execute")
        execute.fulfill()

        let taskFactory: (CommandParameter) -> Task<Int> = { param in
            Task(execute: {
                XCTAssertTrue(false)
                return 1
            })
        }

        let command = AsyncCommand(task1: taskFactory, canExecute: { (param: CommandParameter) in
            execute.fulfill()
            return true
        })

        command.execute(parameter: 1)

        wait(execute)
    }

    func testCommandSource() {
        class MyCommandSource: CommandSource {
            var correctSourceExp: XCTestExpectation?
            override func executeVoid() -> Task<Int> {
                correctSourceExp?.fulfill()
                return super.executeVoid()
            }
        }

        let execute = expectation(description: "execute")
        let correct = expectation(description: "correct")
        let source = MyCommandSource(execute)
        source.correctSourceExp = correct

        let command = AsyncCommand(source, task: { $0.executeVoid() })
        command.execute()

        wait(correct, execute)
    }

    func testCommandSourceGeneric() {
        class MyCommandSource: CommandSource {
            var correctSourceExp: XCTestExpectation?
            var correctParam: AnyObject?

            override func executeGeneric<T: AnyObject>(_ param: T) -> Task<Int> {
                correctSourceExp?.fulfill()
                XCTAssertTrue(correctParam === param)
                return super.executeGeneric(param)
            }
        }

        let execute = expectation(description: "execute")
        let correct = expectation(description: "correct")
        let parameter = CommandParameter()
        let source = MyCommandSource(execute)
        source.correctParam = parameter
        source.correctSourceExp = correct

        let command = AsyncCommand(source, task: { (src: MyCommandSource, param: CommandParameter ) in return src.executeGeneric(param) })

        command.execute(parameter: parameter)

        wait(correct, execute)
    }

    func testCommandSourceIsWeak() {
        let execute = expectation(description: "execute")
        var source: CommandSource? = CommandSource(execute)

        weak var sourceRef = source
        execute.fulfill()

        let command = AsyncCommand(source!, task: {$0.executeVoid()})

        source = nil
        command.execute()

        XCTAssertNil(sourceRef)
        wait(execute)
    }

    class CommandSource: Equatable {
        let exp: XCTestExpectation

        init(_ taskExpectation: XCTestExpectation) {
            self.exp = taskExpectation
        }

        func executeVoid() -> Task<Int> {
            return DispatchQueue.main.async(Task(execute: {
                self.exp.fulfill()
                return 1
            }))
        }

        func executeGeneric<T: AnyObject>(_ param: T) -> Task<Int> {
            return DispatchQueue.main.async(Task(execute: {
                self.exp.fulfill()
                return 1
            }))
        }

        static func == (lhs: AsyncCommandTests.CommandSource, rhs: AsyncCommandTests.CommandSource) -> Bool {
            return rhs === lhs
        }
    }

    class CommandParameter: Equatable {
        static func == (lhs: AsyncCommandTests.CommandParameter, rhs: AsyncCommandTests.CommandParameter) -> Bool {
            return rhs === lhs
        }
    }
}
