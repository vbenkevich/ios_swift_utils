//
//  Created on 16/05/2019
//  Copyright © Vladimir Benkevich 2019
//

import XCTest
import JetLib

class UnownedCommandTests: XCTestCase {

    func testActionTriggered() {
        let exp1 = expectation(description: "command execute")

        let command = CommandFactory.action {
            exp1.fulfill()
        }

        command.execute()

        wait(exp1)
    }

    func testPredicateChecks() {
        var value: Bool!
        let commad = CommandFactory
            .action {}
            .predicate { value }

        value = false
        XCTAssertEqual(value, commad.canExecute())

        value = true
        XCTAssertEqual(value, commad.canExecute())
    }

    func testDeleagetMethodCalledWhenExecutionStartsOrFinished() {
        let command = CommandFactory.action {}

        class Delegate: CommandDelegate {
            let canExecuteExpected = [false, true]
            var expectation: XCTestExpectation!
            var index = 0

            func stateChanged(_ command: Command) {
                XCTAssertEqual(canExecuteExpected[index], command.canExecute())
                index += 1
                expectation.fulfill()
            }
        }

        let delegate = Delegate()
        delegate.expectation = expectation(description: "state changed")
        delegate.expectation.expectedFulfillmentCount = 2
        command.delegate = delegate
        command.execute()

        wait(delegate.expectation)
    }

    func testActionTriggeredManyTimes() {
        let exp = expectation(description: "command execute")
        exp.expectedFulfillmentCount = 2

        let delegate = TestCommandDelegate()
        delegate.canExecuteTrue = expectation(description: "can execute command second time")
        let command = CommandFactory.action {
            exp.fulfill()
        }

        command.delegate = delegate

        command.execute()
        wait(delegate.canExecuteTrue!)
        delegate.canExecuteTrue = expectation(description: "can execute command third time")

        command.execute()
        wait(exp, delegate.canExecuteTrue!)
    }

    func testAsyncExecution() {
        let taskSource = Task<Void>.Source()
        let command = CommandFactory.task {
            return taskSource.task
        }
        let delegate = TestCommandDelegate()
        delegate.canExecuteTrue = expectation(description: "execution has been completed")
        command.delegate = delegate

        XCTAssertEqual(true, command.canExecute())

        command.execute()

        XCTAssertEqual(false, command.canExecute())

        try! taskSource.complete()

        wait(delegate.canExecuteTrue!)

        XCTAssertEqual(true, command.canExecute())
    }

    func testGenericActionTriggered() {
        let parameter = 10
        let exp = expectation(description: "executed")
        let command = CommandFactory.action { (param: Int) in
            XCTAssertEqual(parameter, param)
            exp.fulfill()
        }

        command.execute(parameter: parameter)
        wait(exp)
    }

    func testGenericTaskTriggered() {
        let parameter = 10
        let taskSource = Task<Void>.Source()

        let command = CommandFactory.taskg { (param: Int) -> Task<Void> in
            XCTAssertEqual(parameter, param)
            return taskSource.task
        }

        let delegate = TestCommandDelegate()
        delegate.canExecuteTrue = expectation(description: "execution has been completed")
        delegate.parameter = parameter
        command.delegate = delegate

        XCTAssertTrue(command.canExecute(parameter: parameter))

        command.execute(parameter: parameter)

        XCTAssertFalse(command.canExecute(parameter: parameter))

        try! taskSource.complete()

        wait(delegate.canExecuteTrue!)

        XCTAssertTrue(command.canExecute(parameter: parameter))    }

    func testGenericParameterCorrectType() {
        let exp = expectation(description: "executed")
        exp.isInverted = true

        let command = CommandFactory.action { (param: Int) in
            exp.fulfill()
        }

        XCTAssertFalse(command.canExecute(parameter: "String"))
        XCTAssertFalse(command.canExecute(parameter: self))
        XCTAssertFalse(command.canExecute(parameter: 4321.1))
        XCTAssertTrue(command.canExecute(parameter: 1234))

        command.execute(parameter: "10")

        wait(for: [exp], timeout: 0.2)
    }

    func testGenericPredicateCheck() {
        let param = "123"
        var canExec: Bool!
        let commad = CommandFactory
            .action { (p: String) in
                XCTAssertEqual(param, p)
            }.predicate {
                XCTAssertEqual(param, $0)
                return canExec
            }

        canExec = false
        XCTAssertEqual(canExec, commad.canExecute(parameter: param))

        canExec = true
        XCTAssertEqual(canExec, commad.canExecute(parameter: param))
    }
}
