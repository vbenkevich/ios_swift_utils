//
//  Created on 27/07/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

open class SerialCommand: Command {

    private var lock = SpinLock()

    public init() {
    }

    open var callbackQueue: DispatchQueue = DispatchQueue.main

    open var serial = true

    public final var executing: Bool {
        return executingCount > 0
    }

    // TODO try to use WeakCollection
    private var delegates = [DelegateWrapper]()

    private var executingCount: Int32 = 0 {
        didSet {
            delegates.forEach { $0.delegate?.stateChanged(self) }
        }
    }

    public final func execute(parameter: Any?) {
        guard canExecute(parameter: parameter) else {
            return
        }

        OSAtomicIncrement32(&executingCount)

        executeImpl(parameter: parameter).notify(queue: callbackQueue) { [weak self] in
            guard self != nil else { return }
            OSAtomicDecrement32(&self!.executingCount)
        }
    }

    public final func canExecute(parameter: Any?) -> Bool {
        return !(serial && executing) && canExecuteImpl(parameter: parameter)
    }

    open func invalidate() {
        delegates.forEach { $0.delegate?.stateChanged(self) }
    }

    open func executeImpl(parameter: Any?) -> DispatchWorkItem {
        preconditionFailure("abstract")
    }

    open func canExecuteImpl(parameter: Any?) -> Bool {
        preconditionFailure("abstract")
    }

    public func addDelegate(_ commandDelegate: CommandDelegate) {
        delegates.append(DelegateWrapper(commandDelegate))
    }

    public func removeDelegate(_ commandDelegate: CommandDelegate) {
        delegates.removeAll { $0.delegate === commandDelegate || $0.delegate == nil }
    }

    class DelegateWrapper {
        init(_ delegate: CommandDelegate) {
            self.delegate = delegate
        }
        weak var delegate: CommandDelegate?
    }
}

public extension SerialCommand {

    var delegate: CommandDelegate? {
        get {
            for d in delegates {
                if let delegate = d.delegate {
                    return delegate
                }
            }
            return nil
        }
        set {
            if let d = newValue {
                delegates = [DelegateWrapper(d)]
            } else {
                delegates = []
            }
        }
    }
}
