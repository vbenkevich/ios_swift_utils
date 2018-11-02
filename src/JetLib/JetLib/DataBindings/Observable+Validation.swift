//
//  Created on 02/11/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

public typealias ValidationResult = (isValid: Bool, error: String?)


public protocol ValidationRule {
    associatedtype Data

    func check(_ data: Data?) -> ValidationResult
}

public protocol ValidationResultMerger {

    func merge(results: [ValidationResult]) -> ValidationResult
}

open class DefaultValidationResultMerger: ValidationResultMerger {

    open func merge(results: [ValidationResult]) -> ValidationResult {
        let failed = results.filter{ !$0.isValid }
        return (isValid: failed.isEmpty, error: failed.reduce("", { $0 + ($1.error ?? "") }))
    }
}

public class ObservableValueValidation<Value: Equatable> {

    private var validationRules: [(Value?) -> ValidationResult] = []
    private weak var valueSource: Observable<Value>?
    private var stateObserver = Observable(ValidationResult(isValid: true, error: nil), throttling: DispatchTimeInterval.milliseconds(50))

    public var resultsMerger: ValidationResultMerger = DefaultValidationResultMerger()

    public var validateOnValueChange: Bool = false {
        didSet {
            guard oldValue == validateOnValueChange, let observable = valueSource else {
                return
            }

            if validateOnValueChange {
                self.attach(to: observable)
            } else {
                self.detach(from: observable)
            }
        }
    }

    public var result: ValidationResult? {
        didSet {

        }
    }

    @discardableResult
    public func addRule<Validator: ValidationRule>(_ rule: Validator) -> ObservableValueValidation where Validator.Data == Value  {
        validationRules.append({ [rule] in rule.check($0) })
        return self
    }

    public func check(value: Value?) -> ValidationResult {
        return resultsMerger.merge(results: validationRules.map { $0(value) })
    }

    public func invalidate() {
        result = check(value: valueSource?.value)
    }

    @discardableResult
    func attach(to observable: Observable<Value>) -> ObservableValueValidation {
        if validateOnValueChange {
            observable.notify(self) { $0.result = $0.check(value: $1) }
        }

        return self
    }

    func detach(from observable: Observable<Value>) {
        observable.unsubscribe(self)
    }
}

extension Observable {

    public func withValidation() -> Observable {
        validation = validation ?? ObservableValueValidation().attach(to: self)
        return self
    }

    public func removeValidation() {
        validation?.detach(from: self)
        validation = nil
    }
}


