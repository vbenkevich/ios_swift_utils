//
//  Created on 30/08/2018
//  Copyright © Vladimir Benkevich 2018
//

import XCTest
@testable import Utils

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

        let command = ActionCommand {
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

    class CommandParameter: Equatable {
        static func == (lhs: ActionCommandTests.CommandParameter, rhs: ActionCommandTests.CommandParameter) -> Bool {
            return rhs === lhs
        }
    }
}
