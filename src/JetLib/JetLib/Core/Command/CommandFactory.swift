//
//  Created on 02/05/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation

/// static methods for commands creation
public class CommandFactory {

    /// Create new cammand with owner
    /// this type of command hold weak reference to executor object
    /// and pass this object to execution and cheking actions
    /// if executor doesn't excist any more then canExecute() returns false
    ///
    /// - Parameter executor: command executor
    /// - Returns: createed command
    public static func owner<E: AnyObject>(_ owner: E) -> OwnedCommand<E> {
        return OwnedCommand(owner)
    }

    /// Creates parameterless unowned commad with executing block
    ///
    /// - Parameters:
    ///   - queue: dispatch queue for block execution
    ///   - block: block that executed if command triggered
    /// - Returns: new SimpleCommand
    public static func action(queue: DispatchQueue = DispatchQueue.main, block: @escaping () -> Void) -> UnownedCommand {
        return UnownedCommand().action(queue: queue, block: { _ in block() })
    }

    /// Creates parameterless unowned commad with executing task
    ///
    /// - Parameter factory: task factory
    /// - Returns: new SimpleCommand
    public static func task<TRes>(factory: @escaping () -> Task<TRes>) -> UnownedCommand {
        return UnownedCommand().task { _ in factory().map { _ in Void() } }
    }

    /// Creates parametrized unowned commad with executing block
    ///
    /// - Parameters:
    ///   - queue: dispatch queue for block execution
    ///   - block: block that executed if command triggered
    /// - Returns: new SimpleCommandGeneric
    public static func action<T>(queue: DispatchQueue = DispatchQueue.main, block: @escaping (T) -> Void) -> UnownedCommandGeneric<T> {
        let command = UnownedCommandGeneric<T>()
        command.execution = { _, param in
            queue.async(Task(execute: {
                block(param as! T)
            }))
        }
        return command
    }

    /// Creates parametrized unowned commad with executing task
    ///
    /// - Parameter factory: task factory
    /// - Returns: new SimpleCommandGeneric
    public static func taskg<T, TRes>(factory: @escaping (T) -> Task<TRes>) -> UnownedCommandGeneric<T> {
        let command = UnownedCommandGeneric<T>()
        command.execution = { _, param in factory(param as! T).map { _ in Void() } }
        return command
    }
}
