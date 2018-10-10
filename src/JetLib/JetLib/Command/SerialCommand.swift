//
//  Created on 27/07/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

open class SerialCommand: Command {

    private var lock = SpinLock()

    public weak var delegate: CommandDelegate?

    open var callbackQueue: DispatchQueue = DispatchQueue.main

    open var serial = true

    public final var executing: Bool {
        return executingCount > 0
    }

    private var executingCount: Int32 = 0 {
        didSet {
            delegate?.stateChanged(self)
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
        delegate?.stateChanged(self)
    }

    open func executeImpl(parameter: Any?) -> DispatchWorkItem {
        preconditionFailure("abstract")
    }

    open func canExecuteImpl(parameter: Any?) -> Bool {
        preconditionFailure("abstract")
    }
}
