//
//  Created on 02/05/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation

/// Base executor command
/// this type of command hold weak reference to executor object
/// and pass this object to execution and cheking actions
/// if executor doesn't excist any more then canExecute() returns false
public class BaseExecutorCommand<Exec: AnyObject>: SerialCommand {

    weak var executor: Exec?

    var execution: ((Exec, Any?) -> Task<Void>)!
    var predicate: (Exec, Any?) -> Bool = { _,_ in true }

    init(_ executor: Exec) {
        self.executor = executor
    }

    public final override func executeImpl(parameter: Any?) -> DispatchWorkItem {
        return execution(executor!, parameter).workItem
    }

    public final override func canExecuteImpl(parameter: Any?) -> Bool {
        guard let exec = executor else {
            return false
        }

        return predicate(exec, parameter) != false
    }
}

/// Parameterless ExecutorCommand command
/// this type of command hold weak reference to executor object
/// and pass this object to execution and cheking actions
/// if executor doesn't excist any more then canExecute() returns false
public class ExecutorCommand<Exec: AnyObject>: BaseExecutorCommand<Exec> {


    /// Set execution block for command
    ///
    /// - Parameters:
    ///   - queue: dispatch queue for block execution
    ///   - block: block that executed if command triggered
    /// - Returns: self
    public func action(queue: DispatchQueue = DispatchQueue.main, block: @escaping (Exec) -> Void) -> Self {
        execution = { exec, _ in
            queue.async(Task(execute: { block(exec) }))
        }
        return self
    }

    /// set factory for task
    /// this task will creted triggered when command triggered
    ///
    /// - Parameter factory: task factory
    /// - Returns: self
    public func task<TRes>(factory: @escaping (Exec) -> Task<TRes>) -> Self {
        execution = { exec, param in
            factory(exec).map { _ in Void() }
        }
        return self
    }

    /// sets predicate that can prevent command execution
    /// it'l be called before each command execution
    ///
    /// - Parameter check: condition to check
    /// - Returns: execute comand or not
    public func predicate(check: @escaping (Exec) -> Bool) -> Self {
        predicate = { exec, param in
            check(exec)
        }
        return self
    }
}

/// Parametrized version of ExecutorCommand
/// this type of command hold weak reference to executor object
/// and pass this object to execution and cheking actions
/// if executor doesn't excist any more then canExecute() returns false
public class ExecutorCommandGeneric<Exec: AnyObject, Param>: BaseExecutorCommand<Exec> {

    /// Set execution block for command
    ///
    /// - Parameters:
    ///   - queue: dispatch queue for block execution
    ///   - block: block that executed if command triggered
    /// - Returns: self
    public func action(queue: DispatchQueue = DispatchQueue.main, block: @escaping (Exec, Param) -> Void) -> Self {
        execution = { vm, param in
            queue.async(Task(execute: { block(vm, param as! Param) }))
        }
        return self
    }

    /// set factory for task
    /// this task will creted triggered when command triggered
    ///
    /// - Parameter factory: task factory
    /// - Returns: self
    public func task<TRes>(factory: @escaping (Exec, Param) -> Task<TRes>) -> Self {
        execution = { exec, param in
            factory(exec, param as! Param).map { _ in Void() }
        }
        return self
    }

    /// sets predicate that can prevent command execution
    /// it'l be called before each command execution
    ///
    /// - Parameter check: condition to check
    /// - Returns: execute comand or not
    public func predicate<Param>(check: @escaping (Exec, Param) -> Bool) -> Self {
        predicate = { (exec: Exec, param: Any?) in
            if let typed = param as? Param {
                return check(exec, typed)
            } else {
                return false
            }
        }
        return self
    }
}
