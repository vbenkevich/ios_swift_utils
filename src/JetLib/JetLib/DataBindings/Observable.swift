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
        targets.append(TargetWrapper(target, setter: callBack, queue: queue))
        return self
    }

    public func unsubscribe<Target: AnyObject>(_ target: Target) {
        targets = targets.filter { !$0.same(with: target) }
    }

    fileprivate func fireNotifications(old: Value?, new: Value?) {
        var shouldClean = false

        for target in targets {
            target.setValue(new)
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

        func same(with object: AnyObject) -> Bool {
            preconditionFailure("abstr")
        }

        func setValue(_ value: Value?) {
            preconditionFailure("abstr")
        }
    }

    fileprivate class TargetWrapper<Target: AnyObject>: TargetWrapperAbstract {

        private let setter: ((Target, Value?) -> Void)?
        private let queue: DispatchQueue

        weak var target: Target?

        init(_ target: Target, setter: ((Target, Value?) -> Void)? = nil, queue: DispatchQueue = DispatchQueue.main) {
            self.setter = setter
            self.target = target
            self.queue = queue
        }

        override var isAlive: Bool {
            return target != nil
        }

        override func setValue(_ value: Value?) {
            guard let to = target else {
                return
            }

            queue.async {
                self.setter?(to, value)
            }
        }

        override func same(with object: AnyObject) -> Bool {
            return target === object
        }
    }
}

public extension Observable {

    func addThrottling(_ throttling: DispatchTimeInterval) -> Observable {
        self.throttling = throttling
        return self
    }
}
