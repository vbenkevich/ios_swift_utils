//
//  Created on 23/12/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

/// value correction policy
public protocol ValueCorretor {
    associatedtype Value

    func correct(oldValue: Value?, newValue: Value?) -> Value?
}

/**
 Part of Observable. It incapsulates value correction logic
 It contains a collection of all correction policies
 Correction is performed before a new value would be set to the observable
 */
public class ObservableCorrection<T: Equatable>: ValueCorretor {
    public typealias Value = T

    public init() {
    }

    private var correctors: [(_ old: Value?, _ new: Value?) -> Value?] = []

    /// return corrected value (according ot all correctors)
    public func correct(oldValue: T?, newValue: T?) -> Value? {
        var result = newValue

        for corrector in correctors {
            result = corrector(oldValue, result)
        }

        return result
    }

    /// append the corrector to correctors collection
    @discardableResult
    public func append<Corrector: ValueCorretor>(_ corrector: Corrector) -> ObservableCorrection
        where Corrector.Value == Value {
            return append({ [corrector] in corrector.correct(oldValue: $0, newValue: $1) })
    }

    /// append the correction action to correctors collection
    @discardableResult
    public func append(_ corrector: @escaping (_ old: Value?, _ new: Value?) -> Value?) -> ObservableCorrection {
        correctors.append(corrector)
        return self
    }
}

public extension Observable {

    /// append the new correction to observable's corrections colletion
    @discardableResult
    func correction<Corrector: ValueCorretor>(_ corrector: Corrector) -> Observable
        where Corrector.Value == Value {
            getOrCreateCorrection().append(corrector)
            return self
    }

    /// append the new correction to observable's corrections colletion
    @discardableResult
    func correction(_ corrector: @escaping (_ old: Value?, _ new: Value?) -> Value?) -> Observable {
        getOrCreateCorrection().append(corrector)
        return self
    }

    fileprivate func getOrCreateCorrection() -> ObservableCorrection<Value> {
        if self.correction == nil {
            self.correction = ObservableCorrection()
        }
        return correction!
    }
}

/**
 Simple correction for values in diapason
 */
public struct RangeValueCorrector<T: Comparable>: ValueCorretor {
    public typealias Value = T

    /// minimue value
    public var minValue: T?

    /// maximum value
    public var maxValue: T?

    public func correct(oldValue: T?, newValue: T?) -> T? {
        guard let new = newValue else { return oldValue }

        if let min = minValue, min > new {
            return min
        } else if let max = maxValue, new > max {
            return max
        }

        return new
    }
}
