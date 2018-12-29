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


    func testBindWithConverter() {
        let observable = Observable(20.10)
        let slider = UISlider(frame: CGRect(x: 0, y: 10, width: 10, height: 10))
        slider.maximumValue = 100

        let converter = DoubleToFloat()

        XCTAssertNoThrow(try slider.bind(to: observable, mode: BindingMode.twoWay, converter: converter))
        XCTAssertEqual(slider.value, converter.convertForward(observable.value))

        slider.value = 30
        slider.sendActions(for: .editingChanged)
        XCTAssertEqual(slider.value, converter.convertForward(observable.value))
    }

    func testUpdateObservableErrors() {
        let observable = Observable("100500")
        let field = UITextField()
        let label = UILabel()

        XCTAssertThrowsError(try field.bind(to: observable, mode: .updateObservable, convertForward: {$0}, convertBack: nil))
        XCTAssertThrowsError(try label.bind(to: observable, mode: .updateObservable))
        XCTAssertThrowsError(try field.bind(to: observable, mode: .immediatelyUpdateObservable, convertForward: {$0}, convertBack: nil))
        XCTAssertThrowsError(try label.bind(to: observable, mode: .immediatelyUpdateObservable))
    }

    func testDefaultBindingModes() {
        let observable = Observable("100500")
        
        XCTAssertEqual(try! UITextField().bind(to: observable).mode, BindingMode.twoWay)
        XCTAssertEqual(try! UILabel().bind(to: observable).mode, BindingMode.oneWay)
    }

    func testModeTwoWayLostFocus() {
        let initialValue = "100500"
        let editedValue = "105001"

        let observable = Observable(initialValue)
        let field = UITextField()

        XCTAssertNoThrow(try field.bind(to: observable, mode: .twoWayLostFocus))
        XCTAssertEqual(field.text, initialValue)

        field.text = editedValue

        sync()

        XCTAssertEqual(observable.value, initialValue)

        field.sendActions(for: .editingDidEnd)

        sync()

        XCTAssertEqual(field.text, editedValue)
        XCTAssertEqual(observable.value, editedValue)
    }

    struct DoubleToFloat: ValueConverter {
        typealias From = Double
        typealias To = Float

        func convertForward(_ value: Double?) -> Float? {
            guard let dbl = value else { return nil }
            return Float(dbl)
        }

        func convertBack(_ value: Float?) -> Double? {
            guard let flt = value else { return nil }
            return Double(flt)
        }
    }
}
