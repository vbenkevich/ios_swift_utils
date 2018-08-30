//
//  Created on 27/07/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

open class SerialCommand: Command {

    private var lock = SpinLock()

    open weak var delegate: CommandDelegate?

    open var executeQueue: DispatchQueue = DispatchQueue.main
    open var callbackQueue: DispatchQueue = DispatchQueue.main

    open var serial = true

    public final var executing: Bool {
        return lock.sync { return executingCount > 0 }
    }

    private var executingCount: Int = 0 {
        didSet {
            delegate?.stateChanged(self)
        }
    }

    public final func execute(parameter: Any?) {
        guard canExecute(parameter: parameter) else {
            return
        }

        lock.sync {
            self.executingCount += 1
        }

        let item = DispatchWorkItem { [weak self] in
            self?.executeImpl(parameter: parameter)
        }

        item.notify(queue: callbackQueue) { [weak self] in
            self?.lock.sync {
                self?.executingCount -= 1
            }
        }

        executeQueue.async(execute: item)
    }

    public final func canExecute(parameter: Any?) -> Bool {
        return !(serial && executing) && canExecuteImpl(parameter: parameter)
    }

    open func invalidate() {
        delegate?.stateChanged(self)
    }

    open func executeImpl(parameter: Any?) {
        preconditionFailure("abstract")
    }

    open func canExecuteImpl(parameter: Any?) -> Bool {
        preconditionFailure("abstract")
    }
}
