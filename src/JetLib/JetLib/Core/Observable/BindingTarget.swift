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
    func bind<Converter: ValueConverter, Value: Equatable>(to observable: Observable<Value>, mode: BindingMode? = nil, converter: Converter)
        throws -> Binding<Self, Value> where Converter.From == Value, Converter.To == Self.Value
    {
        return try bind(to: observable, mode: mode, convertForward: converter.convertForward, convertBack: converter.convertBack)
    }

    @discardableResult
    func bind<Value>(to observable: Observable<Value>,
                     mode: BindingMode? = nil,
                     convertForward: @escaping (Value?) -> Self.Value?,
                     convertBack: ((Self.Value?) -> Value?)? = nil)
        throws  -> Binding<Self, Value>
    {
        let mode = mode ?? (self is UIControl ? .twoWay : .oneWay)
        let binding = Binding<Self, Value>(target: self, mode: mode, observable: observable)

        binding.converterForward = convertForward
        binding.converterBack = convertBack

        try binding.commit()

        return binding
    }
}

public extension BindingTarget where Value: Equatable {

    @discardableResult
    func bind(to observable: Observable<Value>, mode: BindingMode? = nil) throws  -> Binding<Self, Value> {
        return try bind(to: observable, mode: mode, convertForward: { $0 }, convertBack: { $0 })
    }
}
