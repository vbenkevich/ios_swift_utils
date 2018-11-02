//
//  Created on 31/10/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

public struct BindingMode: RawRepresentable, OptionSet {
    public typealias RawValue = UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public let rawValue: UInt8

    public static let updateTarget: BindingMode = BindingMode(rawValue: 0x01)
    public static let updateObservable: BindingMode = BindingMode(rawValue: 0x02)
    public static let immediatelyUpdateTarget: BindingMode = BindingMode(rawValue: 0x04)
    public static let immediatelyUpdateObservable: BindingMode = BindingMode(rawValue: 0x08)

    public static let oneWay: BindingMode = [.updateTarget, .immediatelyUpdateTarget]
    public static let twoWay: BindingMode = [.updateTarget, .updateObservable, .immediatelyUpdateTarget]
}

public protocol BindingTargetBase: NSObjectProtocol {

    var bindableValue: Any? { get set }
}

public protocol BindingTarget: BindingTargetBase {

    associatedtype Value
}

public struct BindingError: Error {

    public let message: String

    static let convertIsRequired = BindingError(message: "\(BindingMode.updateObservable) and \(BindingMode.updateObservable) is only supported by UIControl")

    static let updateObservableUIControlOnly = BindingError(message: "convert is requeired for \(BindingMode.updateObservable) and \(BindingMode.updateObservable)")
}

public extension BindingTarget {

    fileprivate var observableSetter: ObservableSetter<Value>? {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.observableSetterKey) as? ObservableSetter<Value> }
        set { objc_setAssociatedObject(self, &AssociatedKeys.observableSetterKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }

    func bind<Value>(to observable: Observable<Value>, mode: BindingMode? = nil,
                     setter: @escaping (Self, Value?) -> Void,
                     convert: ((Self.Value?) -> Value?)? = nil) throws {
        let mode = mode ?? (self is UIControl ? .twoWay : .oneWay)

        if mode.contains(.immediatelyUpdateTarget) {
            setter(self, observable.value)
        }

        if mode.contains(.immediatelyUpdateObservable) {
            guard self is UIControl else {
                throw BindingError.updateObservableUIControlOnly
            }
            guard let convert = convert else {
                throw BindingError.convertIsRequired
            }

            observable.value = convert(self.bindableValue as? Self.Value)
        }

        if mode.contains(.updateTarget) {
            observable.notify(self, callBack: setter)
        }

        if mode.contains(.updateObservable) {
            guard let control = self as? UIControl else {
                throw BindingError.updateObservableUIControlOnly
            }

            guard let convert = convert else {
                throw BindingError.convertIsRequired
            }

            observableSetter = ObservableSetter(owner: self, origin: observable, converter: convert)
            control.addTarget(observableSetter, action: #selector(ObservableSetter<Value>.valueChanged), for: [.editingChanged, .valueChanged])
        }
    }

    func bind<Value>(to observable: Observable<Value>, mode: BindingMode? = nil,
                     convert: @escaping (Value?) -> Self.Value?,
                     convertBack: ((Self.Value?) -> Value?)? = nil) throws {
        try bind(to: observable, mode: mode, setter: { $0.bindableValue = convert($1) }, convert: convertBack)
    }
}

public extension BindingTarget where Value: Equatable {

    func bind(to observable: Observable<Value>, mode: BindingMode? = nil) throws {
        try bind(to: observable, mode: mode, convert: { $0 }, convertBack: { $0 })
    }
}

private struct AssociatedKeys {
    static var observableSetterKey = 0
}

private class ObservableSetter<T> {

    private let setter: (T?) -> Void
    weak var owner: BindingTargetBase?

    init<Value>(owner: BindingTargetBase, origin: Observable<Value>, converter: @escaping (T?) -> Value?) {
        self.owner = owner
        setter = { [weak origin] in
            origin?.value = converter($0)
        }
    }

    func setValue(_ value: T?) {
        setter(value)
    }

    @objc fileprivate func valueChanged() {
        setValue(owner?.bindableValue as? T)
    }
}
