//
//  Created on 31/10/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation
import UIKit

public protocol BindingTargetBase: NSObjectProtocol {

    var bindableValue: Any? { get set }
}

public protocol BindingTarget: BindingTargetBase {

    associatedtype Value
}

public extension BindingTarget {

    @discardableResult
    func bind<Value>(to observable: Observable<Value>, mode: BindingMode? = nil,
                     setter: @escaping (Self, Value?) -> Void,
                     convert: ((Self.Value?) -> Value?)? = nil) throws -> Binding<Self, Value> {
        let mode = mode ?? (self is UIControl ? .twoWay : .oneWay)
        let binding = Binding<Self, Value>(target: self, mode: mode, observable: observable)
        binding.converterBack = convert
        binding.targetSetter = setter

        try binding.commit()

        return binding
    }

    @discardableResult
    func bind<Value>(to observable: Observable<Value>, mode: BindingMode? = nil,
                     convert: @escaping (Value?) -> Self.Value?,
                     convertBack: ((Self.Value?) -> Value?)? = nil) throws  -> Binding<Self, Value> {
        return try bind(to: observable, mode: mode, setter: { $0.bindableValue = convert($1) }, convert: convertBack)
    }
}

public extension BindingTarget where Value: Equatable {

    @discardableResult
    func bind(to observable: Observable<Value>, mode: BindingMode? = nil) throws  -> Binding<Self, Value> {
        return try bind(to: observable, mode: mode, convert: { $0 }, convertBack: { $0 })
    }
}
