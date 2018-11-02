//
//  Created on 01/11/2018
//  Copyright © Vladimir Benkevich 2018
//

import XCTest
@testable import JetLib

class BindingTargetTests: XCTestCase {

    func testImmideatelyUpdatedTarget() {
        let text = "Test text"
        let label = UILabel()
        let observable = Observable(text)

        try! label.bind(to: observable, mode: BindingMode.immediatelyUpdateTarget)

        XCTAssertEqual(text, label.text)
        XCTAssertEqual(text, observable.value)
    }

    func testImmideatelyUpdateObservable() {
        let text = "Test text"
        let field = UITextField()
        let observable = Observable("Old text")
        field.text = text

        try! field.bind(to: observable, mode: BindingMode.immediatelyUpdateObservable)

        XCTAssertEqual(text, field.text)
        XCTAssertEqual(text, observable.value)
    }

    func testOneWay() {
        let text = "Test text 1"
        let newText = "Test text 2"
        let field = UITextField()
        let observable = Observable(text)
        let exp = expectation(description: "binding triggered")

        try! field.bind(to: observable, mode: BindingMode.oneWay)
        XCTAssertEqual(text, field.text)
        XCTAssertEqual(text, observable.value)

        observable.value = newText
        DispatchQueue.main.async {
            XCTAssertEqual(newText, field.text)
            XCTAssertEqual(newText, observable.value)
            exp.fulfill()
        }

        wait(exp)
    }

    func testTwoWay() {
        let text = "Test text 1"
        let newText = "Test text 2"
        let newText2 = "Test text 2"
        let field = UITextField()
        let observable = Observable(text)
        let exp = expectation(description: "binding triggered")

        try! field.bind(to: observable, mode: BindingMode.twoWay)
        XCTAssertEqual(text, field.text)
        XCTAssertEqual(text, observable.value)

        observable.value = newText
        DispatchQueue.main.async {
            XCTAssertEqual(newText, field.text)
            XCTAssertEqual(newText, observable.value)
            exp.fulfill()
        }

        wait(exp)

        field.text = newText2
        XCTAssertEqual(newText2, field.text)
        XCTAssertEqual(newText2, observable.value)
    }
}
