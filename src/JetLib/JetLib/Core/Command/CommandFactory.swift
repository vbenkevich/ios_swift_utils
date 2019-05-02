//
//  Created on 02/05/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation

/// static methods for commands creation
public class CommandFactory {

    /// Create new cammand with executor
    /// this type of command hold weak reference to executor object
    /// and pass this object to execution and cheking actions
    /// if executor doesn't excist any more then canExecute() returns false
    ///
    /// - Parameter executor: command executor
    /// - Returns: createed command
    static func executor<E: AnyObject>(_ executor: E) -> ExecutorCommand<E> {
        return ExecutorCommand(executor)
    }

    /// Creates parameterless SimpleCommad with executing block
    ///
    /// - Parameters:
    ///   - queue: dispatch queue for block execution
    ///   - block: block that executed if command triggered
    /// - Returns: new SimpleCommand
    static func action(queue: DispatchQueue = DispatchQueue.main, block: @escaping () -> Void) -> SimpleCommand {
        let command = SimpleCommand()
        command.execution = { _ in queue.async(Task(execute: block)) }
        return command
    }

    /// Creates parameterless SimpleCommad with executing task
    ///
    /// - Parameter factory: task factory
    /// - Returns: new SimpleCommand
    static func task<TRes>(factory: @escaping () -> Task<TRes>) -> SimpleCommand {
        let command = SimpleCommand()
        command.execution = { _ in factory().map { _ in Void() } }
        return command
    }

    /// Creates parametrized SimpleCommad with executing block
    ///
    /// - Parameters:
    ///   - queue: dispatch queue for block execution
    ///   - block: block that executed if command triggered
    /// - Returns: new SimpleCommandGeneric
    static func action<T>(queue: DispatchQueue = DispatchQueue.main, block: @escaping (T) -> Void) -> SimpleCommandGeneric<T> {
        let command = SimpleCommandGeneric<T>()
        command.execution = { param in
            queue.async(Task(execute: {
                block(param as! T)
            }))
        }
        return command
    }

    /// Creates parametrized SimpleCommad with executing task
    ///
    /// - Parameter factory: task factory
    /// - Returns: new SimpleCommandGeneric
    static func task<T, TRes>(factory: @escaping (T?) -> Task<TRes>) -> SimpleCommandGeneric<T> {
        let command = SimpleCommandGeneric<T>()
        command.execution = { param in factory(param as? T).map { _ in Void() } }
        return command
    }
}
