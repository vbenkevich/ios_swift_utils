//
//  Created on 27/07/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

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
        self.execute = { execute($0 as! T) }
        self.canExecute = nil
    }

    public init<T>(execute: @escaping (T) -> Void, canExecute: @escaping (T) -> Bool) {
        self.execute = { execute($0 as! T) }
        self.canExecute = { $0 is T && canExecute($0 as! T) }
    }

    open override func executeImpl(parameter: Any?) {
        return self.execute(execute)
    }

    open override func canExecuteImpl(parameter: Any?) -> Bool {
        return self.canExecute?(parameter) != false
    }
}

public extension ActionCommand {

    public convenience init<Source: AnyObject>(_ source: Source, execute: @escaping (Source) -> Void) {
        self.init(
            execute: { [weak source] in
                if let src = source {
                    execute(src)
                }
            },
            canExecute: { [weak source] in
                return source != nil
            }
        )
    }

    public convenience init<Source: AnyObject, Param>(_ source: Source, execute: @escaping (Source, Param) -> Void) {
        self.init(
            execute: { [weak source] (param: Param) in
                if let src = source {
                    execute(src, param)
                }
            },
            canExecute: { [weak source] (param: Param) in
                return source != nil
            }
        )
    }

    public convenience init<Source: AnyObject>(
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

    public convenience init<Source: AnyObject, TParam>(
        _ source:   Source,
        execute:    @escaping (Source, TParam) -> Void,
        canExecute: @escaping (Source, TParam) -> Bool)
    {
        self.init(
            execute: { [weak source] (param: TParam) in
                if let src = source {
                    execute(src, param)
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
}
