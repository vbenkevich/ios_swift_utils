//
//  Created on 05/11/2018
//  Copyright © Vladimir Benkevich 2018
//

import XCTest
@testable import JetLib

class BindingValidationTests: XCTestCase {

    var field: UITextField!
    var errorLabel: TestErrorLabel!

    override func setUp() {
        super.setUp()
        field = UITextField()
        errorLabel = TestErrorLabel()
    }

    override func tearDown() {
        super.tearDown()
        field = nil
        errorLabel = nil
    }

    func testValidationOnBind() {
        let rule = TestRule()
        let correct = expectation(description: "hide error")

        let observable = Observable(rule.expected)
            .addValidationRule(rule)

        try! field.bind(to: observable)
            .with(errorPresenter: errorLabel)

        errorLabel.onHideError = { correct.fulfill() }

        wait(correct)

        XCTAssertEqual(rule.expected, field.text)
        XCTAssertEqual(rule.expected, observable.value)
        XCTAssertTrue(errorLabel.isHidden)
    }

    func testValidationOnChangeValue() {
        let rule = TestRule()

        let observable = Observable(rule.expected)
            .addValidation(mode: .onValueChanged)
            .addValidationRule(rule)

        try! field.bind(to: observable)
            .with(errorPresenter: errorLabel)

        let correct = expectation(description: "hide error")
        let error = expectation(description: "show error")

        errorLabel.onShowError = {
            XCTAssertEqual($0, rule.message)
            error.fulfill()
        }

        errorLabel.onHideError = {
            correct.fulfill()
        }

        wait(correct)

        field.text = "unexpected value"
        field.sendActions(for: .valueChanged)

        wait(error)

        XCTAssertEqual(observable.value, "unexpected value")
        XCTAssertFalse(errorLabel.isHidden)
        XCTAssertEqual(errorLabel.text, rule.message)
    }

    func testValidationOnEndEditing() {
        let rule = TestRule()

        let observable = Observable(rule.expected)
            .addValidation(mode: .onEditingEnded)
            .addValidationRule(rule)

        try! field.bind(to: observable)
            .with(errorPresenter: errorLabel)

        let error = expectation(description: "show error")

        errorLabel.onShowError = { _ in error.fulfill() }

        field.text = "unexpected..."
        field.text = "unexpected value"
        field.sendActions(for: .valueChanged)
        field.sendActions(for: .editingDidEnd)

        wait(error)

        XCTAssertEqual(observable.value, "unexpected value")
        XCTAssertFalse(errorLabel.isHidden)
        XCTAssertEqual(errorLabel.text, rule.message)
    }

    func testValidationOnChangeValueThrottling() {
        let rule = TestRule()
        let error = expectation(description: "show error")

        let observable = Observable(rule.expected)
            .addThrottling(.milliseconds(50))
            .addValidation(mode: .onValueChanged)
            .addValidationRule(rule)

        try! field.bind(to: observable)
            .with(errorPresenter: errorLabel)

        errorLabel.onShowError = { _ in error.fulfill() }

        let values = ["1", "2", "3", "4", "5"]

        for val in values {
            field.text = val
            field.sendActions(for: .valueChanged)
        }

        wait(error)

        XCTAssertEqual(observable.value, values.last)
        XCTAssertFalse(errorLabel.isHidden)
        XCTAssertEqual(errorLabel.text, rule.message)
    }

    class TestErrorLabel: UILabel {

        var onShowError: ((String?) -> Void) = {_ in}
        var onHideError: (() -> Void) = {}

        override func showError(message: String?) {
            super.showError(message: message)
            onShowError(message)
        }

        override func hideError() {
            super.hideError()
            onHideError()
        }
    }

    class TestRule: ValidationRule {

        typealias Data = String

        var expected: String? = "expected value"
        var message = "fail"

        func check(_ data: String?) -> ValidationResult {
            if data == expected {
                return ValidationResult()
            } else {
                return ValidationResult(message)
            }
        }
    }
}
