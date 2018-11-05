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

        try! field.bind(to: observable, mode: BindingMode.oneWay)
        XCTAssertEqual(text, field.text)
        XCTAssertEqual(text, observable.value)

        observable.value = newText

        sync()

        XCTAssertEqual(newText, field.text)
        XCTAssertEqual(newText, observable.value)
    }

    func testTwoWay() {
        let text = "Test text 1"
        let newText = "Test text 2"
        let newText2 = "Test text 2"
        let field = UITextField()
        let observable = Observable(text)

        try! field.bind(to: observable, mode: BindingMode.twoWay)
        XCTAssertEqual(text, field.text)
        XCTAssertEqual(text, observable.value)

        observable.value = newText

        sync()

        XCTAssertEqual(newText, field.text)
        XCTAssertEqual(newText, observable.value)

        field.text = newText2

        XCTAssertEqual(newText2, field.text)
        XCTAssertEqual(newText2, observable.value)
    }

    func testUpdateObservableErrors() {
        let observable = Observable("100500")
        let field = UITextField()
        let label = UILabel()

        XCTAssertThrowsError(try field.bind(to: observable, mode: .updateObservable, convert: {$0}, convertBack: nil))
        XCTAssertThrowsError(try label.bind(to: observable, mode: .updateObservable))
        XCTAssertThrowsError(try field.bind(to: observable, mode: .immediatelyUpdateObservable, convert: {$0}, convertBack: nil))
        XCTAssertThrowsError(try label.bind(to: observable, mode: .immediatelyUpdateObservable))
    }

    func testDefaultBindingModes() {
        let observable = Observable("100500")
        
        XCTAssertEqual(try! UITextField().bind(to: observable).mode, BindingMode.twoWay)
        XCTAssertEqual(try! UILabel().bind(to: observable).mode, BindingMode.oneWay)
    }
}
