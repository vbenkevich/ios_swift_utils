//
//  SerialCommand.swift
//
//  Created by Vladimir Benkevich
//  Copyright © 2018
//

import Foundation

open class SerialCommand: Command {

    open weak var delegate: CommandDelegate?

    open var executeQueue: DispatchQueue = DispatchQueue.main

    open var serial = true

    public final var executing: Bool {
        return executingCount != 0
    }

    private var executingCount = 0 {
        didSet {
            delegate?.stateChanged(self)
        }
    }

    public final func execute(parameter: Any?) {
        guard canExecute(parameter: parameter) else {
            return
        }

        executingCount += 1

        executeQueue.async { [weak self] in
            self?.executeImpl(parameter: parameter)
            DispatchQueue.main.async {
                self?.executingCount -= 1
            }
        }
    }

    public final func canExecute(parameter: Any?) -> Bool {
        return !(serial && executing) && canExecuteImpl(parameter: parameter)
    }

    open func invalidate() {
        delegate?.stateChanged(self)
    }

    open func executeImpl(parameter: Any?) {
        fatalError("abstract")
    }

    open func canExecuteImpl(parameter: Any?) -> Bool {
        fatalError("abstract")
    }
}
