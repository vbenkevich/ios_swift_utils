//
//  Created on 02/11/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

public struct BindingMode: OptionSet {
    public typealias RawValue = Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public let rawValue: Int

    public static let updateTarget: BindingMode                     = BindingMode(rawValue: 1 << 0)
    public static let immediatelyUpdateTarget: BindingMode          = BindingMode(rawValue: 1 << 1)
    public static let immediatelyUpdateObservable: BindingMode      = BindingMode(rawValue: 1 << 2)
    public static let updateObservableOnValueChanged: BindingMode   = BindingMode(rawValue: 1 << 3)
    public static let updateObservableOnLostFocus: BindingMode      = BindingMode(rawValue: 1 << 4)

    public static let updateObservable: BindingMode = [.updateObservableOnValueChanged, .updateObservableOnLostFocus]

    public static let oneWay: BindingMode = [.updateTarget, .immediatelyUpdateTarget]
    public static let twoWay: BindingMode = [.updateTarget, .updateObservable, .immediatelyUpdateTarget]
    public static let twoWayLostFocus: BindingMode = [.updateTarget, .immediatelyUpdateTarget, .updateObservableOnLostFocus]
}

public class Binding<Target: BindingTarget, Value: Equatable> {

    init(target: Target, mode: BindingMode, observable: Observable<Value>) {
        self.target = target
        self.mode = mode
        self.observable = observable
    }

    public weak var target: Target?

    public let mode: BindingMode

    public let observable: Observable<Value>

    public var converterForward: ((Value?) -> Target.Value?)?

    public var converterBack: ((Target.Value?) -> Value?)?

    public var targetSetter: (Target, Target.Value?) -> Void = {
        $0.bindableValue = $1
    }

    var targetValue: Target.Value? {
        return target?.bindableValue as? Target.Value
    }

    var observableValue: Value? {
        return observable.value
    }

    public func forceUpdateObservble() {
        observable.value = converterBack?(targetValue)
    }

    public func forceUpdateTarget(_ value: Value?) {
        guard let target = self.target else { return }
        targetSetter(target, converterForward?(value))
    }

    public func forceUpdateTarget() {
        forceUpdateTarget(observableValue)
    }

    func commit() throws {
        let control = target as? UIControl

        if mode.contains(.immediatelyUpdateObservable) || mode.contains(.updateObservable) {
            guard control != nil else { throw Exception.updateObservableUIControlOnly }
            guard converterBack != nil else { throw Exception.convertIsRequired}
        }

        if mode.contains(.immediatelyUpdateTarget) {
            forceUpdateTarget()
        }

        if mode.contains(.immediatelyUpdateObservable) {
            forceUpdateObservble()
        }

        if mode.contains(.updateTarget) {
            observable.notify(self, fireRightNow: false) { $0.forceUpdateTarget($1) }
        }

        if mode.contains(.updateObservableOnValueChanged) {
            control?.addTarget(self, action: #selector(controlValueChanged), for: [.valueChanged, .editingChanged])
        }

        if mode.contains(.updateObservableOnLostFocus) {
            control?.addTarget(self, action: #selector(controlEditingEnded), for: [.editingDidEnd])
        }

        target?.addBinding(self)
    }

    @objc func controlValueChanged() {
        forceUpdateObservble()
    }

    @objc func controlEditingEnded() {
        forceUpdateObservble()
    }
}

extension BindingTarget {

    fileprivate var bindings: [AnyObject]? {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.bindingsKey) as? [AnyObject] }
        set { objc_setAssociatedObject(self, &AssociatedKeys.bindingsKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }

    func addBinding(_ binding: AnyObject) {
        if bindings == nil {
            bindings = []
        }
        bindings?.append(binding)
    }
}

private struct AssociatedKeys {
    static var bindingsKey = 1
}

private extension Exception {

    static let convertIsRequired = Exception("BindingMode.updateObservable and BindingMode.updateObservable is only supported by UIControl")

    static let updateObservableUIControlOnly = Exception("Convert is requeired for BindingMode.updateObservable and BindingMode.updateObservable")
}
