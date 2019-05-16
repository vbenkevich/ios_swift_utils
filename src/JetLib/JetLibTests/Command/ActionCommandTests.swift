//
//  Created on 30/08/2018
//  Copyright © Vladimir Benkevich 2018
//

import XCTest
@testable import JetLib

class ActionCommandTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExecute() {
        let created = expectation(description: "created")
        let execute = expectation(description: "execute")

        let command = ActionCommand() {
            execute.fulfill()
        }

        created.fulfill()

        command.execute()

        wait(for: [created, execute], timeout: 1, enforceOrder: true)
    }

    func testCanExecuteTrue() {
        let created = expectation(description: "created")
        let execute = expectation(description: "execute")

        let command = ActionCommand(execute: { execute.fulfill() }, canExecute: { return true })

        created.fulfill()

        command.execute()

        wait(for: [created, execute], timeout: 1, enforceOrder: true)
    }

    func testCanExecuteFalseTrue() {
        let created = expectation(description: "created")

        var canExecute = false

        let command = ActionCommand(execute: {
            created.fulfill()
        }, canExecute: {
            return canExecute
        })

        let testQueue = DispatchQueue(label: "test queue")
        command.executeQueue = testQueue
        command.callbackQueue = testQueue

        testQueue.async {
            command.execute()
            canExecute = true
            command.execute()
        }

        wait(created)
    }

    func testSerialExecution() {
        let execute = expectation(description: "execute")
        let semaphore = DispatchSemaphore(value: 0)

        let command = ActionCommand {
            execute.fulfill()
            semaphore.wait()
        }

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
        let command = ActionCommand { (param: CommandParameter) in
            XCTAssertEqual(param, parameter)
            execute.fulfill()
        }
        command.execute(parameter: parameter)
        wait(execute)
    }

    func testCanExecuteGeneric() {
        let execute = expectation(description: "execute")
        let parameter = CommandParameter()

        let command = ActionCommand(execute: { (param: CommandParameter) in
            execute.fulfill()
        }, canExecute: { (param: CommandParameter) in
            return true
        })

        command.execute(parameter: parameter)

        wait(execute)
    }

    func testGenericWrongType() {
        let execute = expectation(description: "execute")
        execute.fulfill()

        let command = ActionCommand(execute: { (param: CommandParameter) in
            execute.fulfill()
            XCTAssertTrue(false)
        }, canExecute: { (param: CommandParameter) in
            execute.fulfill()
            return true
        })

        command.execute(parameter: 1)

        wait(execute)
    }

    func testCommandSource() {
        let execute = expectation(description: "execute")
        let source = CommandSource()

        let command = ActionCommand(source) {
            XCTAssertEqual(source, $0)
            execute.fulfill()
        }

        command.execute()

        wait(execute)
    }

    func testCommandSourceGeneric() {
        let execute = expectation(description: "execute")
        let source = CommandSource()
        let parameter = CommandParameter()

        let command = ActionCommand(source) { (src: CommandSource, param: CommandParameter) in
            XCTAssertEqual(source, src)
            XCTAssertEqual(parameter, param)
            execute.fulfill()
        }

        command.execute(parameter: parameter)

        wait(execute)
    }

    func testCommandSourceIsWeak() {
        let execute = expectation(description: "execute")
        var source: CommandSource? = CommandSource()

        weak var sourceRef = source
        execute.fulfill()

        let command = ActionCommand(source!) { (source: CommandSource, param: CommandParameter) in
            execute.fulfill()
        }

        source = nil
        command.execute(parameter: CommandParameter())

        XCTAssertNil(sourceRef)
        wait(execute)
    }

    func testCommandDelegate() {

        class Delegate: CommandDelegate {
            var executing: XCTestExpectation!
            var completed: XCTestExpectation!

            func stateChanged(_ command: Command) {
                if command.executing {
                    XCTAssertFalse(command.canExecute(parameter: nil))
                    executing.fulfill()
                } else {
                    XCTAssertTrue(command.canExecute(parameter: nil))
                    completed.fulfill()
                }
            }
        }

        let delegate = Delegate()
        let executing = expectation(description: "executeing")
        let completed = expectation(description: "completed")
        let command = ActionCommand() {}

        delegate.executing = executing
        delegate.completed = completed

        command.addDelegate(delegate)
        command.execute()

        wait(for: [executing, completed], timeout: 1, enforceOrder: true)
    }

    func testCommandDelegateWeak() {
        class Delegate: CommandDelegate {
            func stateChanged(_ command: Command) {
            }
        }

        var delegateStrong: Delegate? = Delegate()
        weak var delegateWeak: Delegate? = delegateStrong

        let command = ActionCommand() {}
        command.delegate = delegateStrong

        delegateStrong = nil
        XCTAssertNil(delegateWeak)
    }

    func testCommandInvalidateFireDelegateChanged() {
        class Delegate: CommandDelegate {
            var exp: XCTestExpectation!
            func stateChanged(_ command: Command) {
                exp.fulfill()
            }
        }

        let delegate = Delegate()
        let command = ActionCommand{}

        delegate.exp = expectation(description: "delegate")
        command.addDelegate(delegate)
        command.invalidate()

        wait(delegate.exp)
    }

    class CommandSource: Equatable {
        static func == (lhs: ActionCommandTests.CommandSource, rhs: ActionCommandTests.CommandSource) -> Bool {
            return rhs === lhs
        }
    }

    class CommandParameter: Equatable {
        static func == (lhs: ActionCommandTests.CommandParameter, rhs: ActionCommandTests.CommandParameter) -> Bool {
            return rhs === lhs
        }
    }
}
