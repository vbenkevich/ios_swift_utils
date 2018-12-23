//
//  Created on 23/12/2018
//  Copyright © Vladimir Benkevich 2018
//

import XCTest
@testable import JetLib

class ObservableCorrectionTests: XCTestCase {

    func testDefaults() {
        let observable = Observable("")
        XCTAssertNil(observable.correction)
    }

    func testAddValueCorretor() {
        let oldValue = "123"
        let observable = Observable(oldValue)
        observable.correction(TestCorrector())
        XCTAssertNotNil(observable.correction)
        XCTAssertEqual(observable.value, oldValue)
    }

    func testAddCorrectionAction() {
        let oldValue = "123"
        let observable = Observable(oldValue)
        observable.correction { (old, new) in return old }
        XCTAssertNotNil(observable.correction)
        XCTAssertEqual(observable.value, oldValue)
    }

    func testValueCorretor() {
        let oldValue = "old"
        let newValue = "new"
        let result = "result"

        let observable = Observable(oldValue)

        let corrector = TestCorrector<String> { (old, new) in
            XCTAssertEqual(old, oldValue)
            XCTAssertEqual(new, newValue)
            return result
        }

        observable.correction(corrector)

        observable.value = newValue

        XCTAssertEqual(observable.value, result)
    }

    func testCorretoionActionNewValue() {
        let oldValue = "old"
        let newValue = "new"
        let result = "result"

        let observable = Observable(oldValue)

        observable.correction { (old, new) in
            XCTAssertEqual(old, oldValue)
            XCTAssertEqual(new, newValue)
            return result
        }

        observable.value = newValue

        XCTAssertEqual(observable.value, result)
    }

    func testMultiCorrection() {
        let observable = Observable<String>()
        let validValue = "valid"
        let firstInvalid = "1"
        let secondInvalid = "2"
        let firstCor = "corrected 1"
        let secondCor = "corrected 2"

        observable.correction { old, new in
            return new == firstInvalid ? firstCor : new
        }

        observable.correction(TestCorrector { old, new in
            return new == secondInvalid ? secondCor : new
        })

        observable.value = validValue
        XCTAssertEqual(observable.value, validValue)

        observable.value = firstInvalid
        XCTAssertEqual(observable.value, firstCor)

        observable.value = secondInvalid
        XCTAssertEqual(observable.value, secondCor)

        observable.value = validValue
        XCTAssertEqual(observable.value, validValue)
    }

    func testRangeCorrector() {
        let corrector = RangeValueCorrector(minValue: 10, maxValue: 100)
        XCTAssertEqual(corrector.correct(oldValue: 50, newValue: nil), 50)
        XCTAssertEqual(corrector.correct(oldValue: 100, newValue: 10), 10)
        XCTAssertEqual(corrector.correct(oldValue: 10, newValue: 100), 100)
        XCTAssertEqual(corrector.correct(oldValue: 50, newValue: 43), 43)
        XCTAssertEqual(corrector.correct(oldValue: 90, newValue: 8), 10)
        XCTAssertEqual(corrector.correct(oldValue: 40, newValue: 3000), 100)
    }

    class TestCorrector<T>: ValueCorretor {
        typealias Value = T

        init(correctAction: ((T?, T?) -> T?)? = nil) {
            self.correctAction = correctAction
        }

        var correctAction: ((T?, T?) -> T?)?

        func correct(oldValue: T?, newValue: T?) -> T? {
            return correctAction?(oldValue, newValue)
        }
    }
}
