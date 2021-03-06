//
//  Created on 27/07/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

@available(*, deprecated, message: "Use CommandFactory instead")
open class ActionCommand: SerialCommand {

    private let execute: (Any?) -> Void
    private let canExecute: ((Any?) -> Bool)?

    public init(execute: @escaping () -> Void) {
        self.execute = { _ in execute() }
        self.canExecute = nil
    }

    public init(execute: @escaping () -> Void, canExecute: @escaping () -> Bool) {
        self.execute = { _ in execute() }
        self.canExecute = { _ in canExecute() }
    }

    public init<T>(execute: @escaping (T) -> Void) {
        self.execute = {
            execute($0 as! T)
        }
        self.canExecute = {
            return $0 is T
        }
    }

    public init<T>(execute: @escaping (T) -> Void, canExecute: @escaping (T) -> Bool) {
        self.execute = { execute($0 as! T) }
        self.canExecute = { $0 is T && canExecute($0 as! T) }
    }

    open var executeQueue: DispatchQueue = DispatchQueue.main

    open override func executeImpl(parameter: Any?) -> DispatchWorkItem {
        let workItem = DispatchWorkItem {
            self.execute(parameter)
        }

        defer {
            executeQueue.async(execute: workItem)
        }

        return workItem
    }

    open override func canExecuteImpl(parameter: Any?) -> Bool {
        return self.canExecute?(parameter) != false
    }
}

public extension ActionCommand {

    convenience init<Source: AnyObject>(
        _ source:   Source,
        execute:    @escaping (Source) -> Void,
        canExecute: @escaping (Source) -> Bool)
    {
        self.init(
            execute: { [weak source] in
                if let src = source {
                    execute(src)
                }
            },
            canExecute: { [weak source] in
                if let src = source {
                    return canExecute(src)
                } else {
                    return false
                }
            }
        )
    }

    convenience init<Source: AnyObject, TParam>(
        _ source:   Source,
        executeGeneric:    @escaping (Source, TParam) -> Void,
        canExecute: @escaping (Source, TParam) -> Bool)
    {
        self.init(
            execute: { [weak source] (param: TParam) in
                if let src = source {
                    executeGeneric(src, param)
                }
            },
            canExecute: { [weak source] (param: TParam) in
                if let src = source {
                    return canExecute(src, param)
                } else {
                    return false
                }
            }
        )
    }

    convenience init<Source: AnyObject>(_ source: Source, execute: @escaping (Source) -> Void) {
        self.init(source, execute: { execute($0) }, canExecute: { _ in return true } )
    }

    convenience init<Source: AnyObject, Param>(_ source: Source, execute: @escaping (Source, Param) -> Void) {
        self.init(source, executeGeneric: { execute($0, $1) }, canExecute: { (_, _) in return true } )
    }
}
