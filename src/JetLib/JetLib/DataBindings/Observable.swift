//
//  Created on 16/10/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

public class Observable<Value: Equatable> {

    public init(_ value: Value? = nil, throttling: DispatchTimeInterval? = nil) {
        self.value = value
        self.throttling = throttling
        self.validation = nil
    }

    public var value: Value? {
        didSet {
            guard oldValue != value else {
                return
            }

            fireNotificationWorkItem = DispatchWorkItem { [value, weak self] in
                self?.fireNotifications(old: oldValue, new: value)
            }
        }
    }

    public var validation: ObservableValueValidation<Value>?

    public var throttling: DispatchTimeInterval?

    fileprivate var fireNotificationWorkItem: DispatchWorkItem? {
        didSet {
            oldValue?.cancel()
            guard let workItem = fireNotificationWorkItem else {
                return
            }

            if let delay = throttling {
                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + delay, execute: workItem)
            } else {
                workItem.perform()
            }
        }
    }

    fileprivate var targets = [TargetWrapperAbstract]()

    @discardableResult
    public func notify<Target: AnyObject>(_ target: Target, _ queue: DispatchQueue = DispatchQueue.main, callBack: @escaping (Target, Value?) -> Void) -> Observable {
        targets.append(TargetWrapper(target, setter: callBack, setterQueue: queue))
        return self
    }

    public func unsubscribe<Target: AnyObject>(_ target: Target) {
        targets = targets.filter { !$0.same(with: target) }
    }

    fileprivate func fireNotifications(old: Value?, new: Value?) {
        var shouldClean = false

        for target in targets {
            target.value = new
            shouldClean = shouldClean || !target.isAlive
        }

        if shouldClean {
            targets = targets.filter { $0.isAlive }
        }
    }

    fileprivate class TargetWrapperAbstract {

        var isAlive: Bool {
            preconditionFailure("abstr")
        }

        var value: Value? {
            get { preconditionFailure("abstr") }
            set { preconditionFailure("abstr") }
        }

        func same(with object: AnyObject) -> Bool {
            preconditionFailure("abstr")
        }
    }

    fileprivate class TargetWrapper<Target: AnyObject>: TargetWrapperAbstract {

        private let setter: ((Target, Value?) -> Void)?
        private let getter: ((Target) -> Value?)?

        private let setterQueue: DispatchQueue
        private let getterQueue: DispatchQueue

        weak var target: Target?

        init(_ target: Target,
             setter: ((Target, Value?) -> Void)? = nil,
             getter: ((Target) -> Value?)? = nil,
             setterQueue: DispatchQueue = DispatchQueue.main,
             getterQueue: DispatchQueue = DispatchQueue.main)
        {
            self.setter = setter
            self.getter = getter
            self.target = target
            self.setterQueue = setterQueue
            self.getterQueue = getterQueue
        }

        override var isAlive: Bool {
            return target != nil
        }

        override var value: Value? {
            get {
                guard let from = target else {
                    return nil
                }

                return getterQueue.sync {
                    return getter?(from)
                }
            }
            set {
                guard let to = target else {
                    return
                }

                setterQueue.async {
                    self.setter?(to, newValue)
                }
            }
        }

        override func same(with object: AnyObject) -> Bool {
            return target === object
        }
    }
}
