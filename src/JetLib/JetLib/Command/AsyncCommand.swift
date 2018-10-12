//
//  Created on 12/10/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

fileprivate protocol DispatchWorkItemProxy {
    var workItem: DispatchWorkItem! { get }
}

extension Task: DispatchWorkItemProxy {
}


// TODO: try to generalize with ActionCommand (may be we should move DispatchWorkItemProxy into serial command)

open class AsyncCommand: SerialCommand {

    private let taskFactory: (Any?) -> DispatchWorkItemProxy
    private let canExecute: (Any?) -> Bool

    public init<TOut>(task: @escaping () -> Task<TOut>, canExecute: (() -> Bool)? = nil) {
        self.taskFactory = { _ in task() }
        self.canExecute = { _ in canExecute?() != false }
    }

    public init<TParam, TOut>(task1: @escaping (TParam) -> Task<TOut>, canExecute: ((TParam) -> Bool)? = nil) {
        self.taskFactory = { task1($0 as! TParam) }
        self.canExecute = { $0 is TParam && canExecute?($0 as! TParam) != false }
    }

    open var executeQueue: DispatchQueue = DispatchQueue.main

    open override func executeImpl(parameter: Any?) -> DispatchWorkItem {
        let workItem = taskFactory(parameter).workItem!

        defer {
            executeQueue.async(execute: workItem)
        }

        return workItem
    }

    open override func canExecuteImpl(parameter: Any?) -> Bool {
        return self.canExecute(parameter)
    }
}

public extension AsyncCommand {

    public convenience init<Source: AnyObject, TOut>(
        _ source:   Source,
        task:       @escaping (Source) -> Task<TOut>,
        canExecute: ((Source) -> Bool)? = nil)
    {
        let factory: () -> Task<TOut> = { [weak source] in
            if let src = source {
                return task(src)
            } else {
                return Task<TOut>(CommandError.sourceIsNill)
            }
        }

        let canExecute: () -> Bool = { [weak source] in
            if let src = source {
                return canExecute?(src) != false
            } else {
                return false
            }
        }

        self.init(task1: factory, canExecute: canExecute)
    }

    public convenience init<Source: AnyObject, TParam, TOut>(
        _ source:   Source,
        task:       @escaping (Source, TParam) -> Task<TOut>,
        canExecute: ((Source, TParam) -> Bool)? = nil)
    {
        let factory: (TParam) -> Task<TOut> = { [weak source] (param: TParam) in
            if let src = source {
                return task(src, param)
            } else {
                return Task<TOut>(CommandError.sourceIsNill)
            }
        }

        let canExecute: (TParam) -> Bool = { [weak source] (param: TParam) in
            if let src = source {
                return canExecute?(src, param) != false
            } else {
                return false
            }
        }

        self.init(task1: factory, canExecute: canExecute)
    }
}

enum CommandError: Error {
    case sourceIsNill
}
