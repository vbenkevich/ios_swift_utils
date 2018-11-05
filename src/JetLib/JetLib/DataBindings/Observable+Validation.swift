//
//  Created on 02/11/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

public struct ValidationResult: Equatable {

    public init() {
        self.isValid = true
        self.error = nil
    }

    public init(_ error: String? = nil) {
        self.isValid = false
        self.error = error
    }

    public init(_ isValid: Bool, _ error: String? = nil) {
        self.isValid = isValid
        self.error = error
    }

    public let isValid: Bool

    public let error: String?
}

protocol Invalidatable: class {

    func invalidate()
}

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
        return ValidationResult(failed.isEmpty, failed.reduce("", { $0 + ($1.error ?? "") }))
    }
}

public enum ValidationMode {
    case onValueChanged
    case onEditingEnded
}

public class ObservableValueValidation<Value: Equatable>: Invalidatable {

    private var validationRules: [(Value?) -> ValidationResult] = []
    private var stateObserver = Observable(ValidationResult())

    private weak var valueSource: Observable<Value>? {
        didSet {
            guard oldValue !== valueSource else {
                return
            }

            oldValue?.unsubscribe(self)

            if mode == .onValueChanged {
                subscribe()
            } else {
                unsubscribe()
            }
        }
    }

    public var mode: ValidationMode = ValidationMode.onEditingEnded {
        didSet {
            guard oldValue != mode else {
                return
            }

            if mode == .onValueChanged {
                subscribe()
            } else {
                unsubscribe()
            }
        }
    }

    public var resultsMerger: ValidationResultMerger = DefaultValidationResultMerger()

    public var result: ValidationResult? {
        didSet {
            stateObserver.value = result
        }
    }

    public var throttling: DispatchTimeInterval? {
        get { return stateObserver.throttling }
        set { stateObserver.throttling = newValue }
    }

    lazy var editingDelegate = ControlEditingDelegate(self)

    public func mode(_ mode: ValidationMode) -> ObservableValueValidation {
        self.mode = mode
        return self
    }

    @discardableResult
    public func addRule<Validator: ValidationRule>(_ rule: Validator) -> ObservableValueValidation where Validator.Data == Value  {
        validationRules.append({ [rule] in rule.check($0) })
        return self
    }

    @discardableResult
    public func notify<Target: AnyObject>(_ target: Target, _ queue: DispatchQueue = DispatchQueue.main, callBack: @escaping (Target, ValidationResult?) -> Void) -> ObservableValueValidation<Value> {
        stateObserver.notify(target, queue, callBack: callBack)

        callBack(target, result)

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
        valueSource = observable
        return self
    }

    @discardableResult
    func detach() -> ObservableValueValidation {
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

    @discardableResult
    public func addValidation(mode: ValidationMode? = nil) -> Observable {
        validation = validation ?? ObservableValueValidation()

        if let mode = mode {
            validation = validation?.mode(mode)
        }

        validation?.attach(to: self)

        return self
    }

    @discardableResult
    public func addValidationRule<Validator: ValidationRule>(_ rule: Validator) -> Observable where Validator.Data == Value  {
        addValidation().validation?.addRule(rule)
        return self
    }

    public func removeValidation() {
        validation?.detach()
        validation = nil
    }
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
