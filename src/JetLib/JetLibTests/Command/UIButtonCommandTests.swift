//
//  Created on 30/08/2018
//  Copyright © Vladimir Benkevich 2018
//

import XCTest
@testable import JetLib

class UIButtonCommandTests: XCTestCase {
    
    func testCommandExecution() {
        let expectation = self.expectation(description: "execute")
        let button = UIButton()
        button.command = CommandFactory.action { expectation.fulfill() }
        button.sendActions(for: .touchUpInside)

        wait(expectation)
    }

    func testCommandRemoving() {
        let expectation = self.expectation(description: "execute")
        let button = UIButton()

        expectation.expectedFulfillmentCount = 1

        button.command = CommandFactory.action { expectation.fulfill() }
        button.sendActions(for: .touchUpInside)

        button.command = nil
        XCTAssertNil(button.command)

        button.sendActions(for: .touchUpInside)

        wait(expectation)
    }

    func testCommandCanExecute() {
        let button = UIButton()
        button.command = CommandFactory.action { XCTFail() }.predicate { false }
        XCTAssertFalse(button.isEnabled)

        button.sendActions(for: .touchUpInside)
    }

    func testCommandParameterReftype() {
        let expectation = self.expectation(description: "execute")
        let button = UIButton()
        let param = CommandParameterRef()

        expectation.expectedFulfillmentCount = 1

        button.command = CommandFactory.action { (p: CommandParameterRef) in
            XCTAssertEqual(p, param)
            expectation.fulfill()
        }.predicate {
            XCTAssertEqual($0, param)
            return true
        }

        XCTAssertFalse(button.isEnabled)

        button.commanParameter = param
        XCTAssertTrue(button.isEnabled)

        button.sendActions(for: .touchUpInside)
        wait(expectation)

        button.commanParameter = CommandParameterStruct()
        XCTAssertFalse(button.isEnabled)
    }

    func testCommandParameterStruct() {
        let expectation = self.expectation(description: "execute")
        let button = UIButton()
        let param = CommandParameterStruct()

        expectation.expectedFulfillmentCount = 1

        button.command = CommandFactory.action { (p: CommandParameterStruct) in
            XCTAssertEqual(p, param)
            expectation.fulfill()
        }.predicate {
            XCTAssertEqual($0, param)
            return true
        }

        XCTAssertFalse(button.isEnabled)

        button.commanParameter = param
        XCTAssertTrue(button.isEnabled)

        button.sendActions(for: .touchUpInside)
        wait(expectation)

        button.commanParameter = CommandParameterRef()
        XCTAssertFalse(button.isEnabled)
    }

    class CommandParameterRef: Equatable {
        static func == (lhs: CommandParameterRef, rhs: CommandParameterRef) -> Bool {
            return lhs === rhs
        }
    }

    struct CommandParameterStruct: Equatable {
        let uui = UUID().uuidString

        static func == (lhs: CommandParameterStruct, rhs: CommandParameterStruct) -> Bool {
            return lhs.uui == rhs.uui
        }
    }
}
