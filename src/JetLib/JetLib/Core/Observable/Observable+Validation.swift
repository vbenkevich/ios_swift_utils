//
//  Created on 02/11/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

/// Observable validation result
public struct ValidationResult: Equatable {

    /// success result shortcut
    public init() {
        self.isValid = true
        self.error = nil
    }

    /// error result shortcut
    public init(_ error: String? = nil) {
        self.isValid = false
        self.error = error
    }

    public init(_ isValid: Bool, _ error: String? = nil) {
        self.isValid = isValid
        self.error = error
    }

    /// whether validation is sucess
    public let isValid: Bool

    /// error message
    public let error: String?
}

/// Data validation policy
public protocol ValidationRule {
    associatedtype Value

    /// perform validation of data
    func check(_ data: Value?) -> ValidationResult
}

/**
 policy of merging all validation's result to one
 */
public protocol ValidationResultMerger {

    /**
     return aggregated validation result for results collection
     */
    func merge(results: [ValidationResult]) -> ValidationResult
}

/**
 dafault validation result merge policy
 observable valid if all validations are valid
 result messaage is union of all error messages
 */
open class DefaultValidationResultMerger: ValidationResultMerger {

    open func merge(results: [ValidationResult]) -> ValidationResult {
        let failed = results.filter{ !$0.isValid }
        let message = failed.map { $0.error ?? "" }.filter { $0 != "" }.joined(separator: "\n")
        return ValidationResult(failed.isEmpty, message)
    }
}

/**
 Part of the observable.
 And incapsulates value validation logic.
 It contains the collection of validation rules. And chcek this rules with a value of the observable
 There two trigger conditions:
  - onValueChanged: validation is listen observable value changing
  - onEditingEnded: validatoin trigger manualy (general from databinding)
 */
public class ObservableValidation<Value: Equatable>: Invalidatable {

    private var validationRules: [(Value?) -> ValidationResult] = []
    private var stateObserver = Observable(ValidationResult())

    private weak var valueSource: Observable<Value>? {
        didSet {
            guard oldValue !== valueSource else {
                return
            }

            oldValue?.unsubscribe(self)
            subscribe()
        }
    }

    /// validation result aggergator
    public var resultsMerger: ValidationResultMerger = DefaultValidationResultMerger()

    /// current validation result
    public var result: ValidationResult? {
        didSet {
            stateObserver.value = result
        }
    }

    /// delay between trigger ivent and the begining of validation
    public var throttling: DispatchTimeInterval? {
        get { return stateObserver.throttling }
        set { stateObserver.throttling = newValue }
    }

    lazy var editingDelegate = ControlEditingDelegate(self)

    /**
     append validation rule to validations collection
     */
    @discardableResult
    public func append<Validator: ValidationRule>(_ validator: Validator) -> ObservableValidation where Validator.Value == Value  {
        validationRules.append({ [validator] in validator.check($0) })
        return self
    }

    /**
     subsription for validation result changed
     */
    @discardableResult
    public func notify<Target: AnyObject>(_ target: Target, _ queue: DispatchQueue = DispatchQueue.main, callBack: @escaping (Target, ValidationResult?) -> Void) -> ObservableValidation<Value> {
        stateObserver.notify(target, fireRightNow: false, queue, callBack: callBack)
        callBack(target, result)

        return self
    }

    /// perform checkeing all validation witout current result updating
    public func check(value: Value?) -> ValidationResult {
        return resultsMerger.merge(results: validationRules.map { $0(value) })
    }

    /// force all validation
    public func invalidate() {
        result = check(value: valueSource?.value)
    }

    @discardableResult
    func attach(to observable: Observable<Value>) -> ObservableValidation {
        valueSource = observable
        return self
    }

    @discardableResult
    func detach() -> ObservableValidation {
        valueSource = nil
        return self
    }

    func subscribe() {
        valueSource?.notify(self) { $0.result = $0.check(value: $1) }
    }

    func unsubscribe() {
        valueSource?.unsubscribe(self)
    }
}

public extension Observable {

    /**
     append validation rule to observable
     */
    @discardableResult
    public func validation<Validator: ValidationRule>(_ validator: Validator) -> Observable where Validator.Value == Value  {
        getOrCreateValidaition().append(validator)
        return self
    }

    /**
    clear all validations from obsevable
    */
    public func removeValidation() {
        validation?.detach()
        validation = nil
    }

    fileprivate func getOrCreateValidaition() -> ObservableValidation<Value> {
        if validation == nil {
            validation = ObservableValidation()
            validation?.attach(to: self)
        }

        return validation!
    }
}

protocol Invalidatable: class {

    func invalidate()
}

class ControlEditingDelegate {

    init(_ source: Invalidatable) {
        self.source = source
    }

    weak var source: Invalidatable?

    @objc func editingDidEnd() {
        source?.invalidate()
    }

    @objc func editingDidBegin() {
        source?.invalidate()
    }
}
