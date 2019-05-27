//
//  Created on 02/05/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation

/// Base serial command with actions for execetion and canexecute cheking
/// this type of command hold weak reference to owner object
/// and pass this object to execution and cheking actions
/// if owner doesn't excist any more then canExecute() returns false
public class BaseCommand<Owner: AnyObject>: SerialCommand {

    weak var owner: Owner?

    var execution: ((Owner, Any?) -> Task<Void>)!
    var predicate: ((Owner, Any?) -> Bool)?

    init(_ owner: Owner) {
        self.owner = owner
    }

    public override func executeImpl(parameter: Any?) -> DispatchWorkItem {
        return execution(owner!, parameter).workItem
    }

    public override func canExecuteImpl(parameter: Any?) -> Bool {
        guard let owner = owner else {
            return false
        }

        return predicate?(owner, parameter) != false
    }
}

/// Parameterless BaseCommand command
/// this type of command hold weak reference to executor object
/// and pass this object to execution and cheking actions
/// if executor doesn't excist any more then canExecute() returns false
public class OwnedCommand<Owner: AnyObject>: BaseCommand<Owner> {

    /// Set execution block for command
    ///
    /// - Parameters:
    ///   - queue: dispatch queue for block execution
    ///   - block: block that executed if command triggered
    /// - Returns: self
    public func action(queue: DispatchQueue = DispatchQueue.main, block: @escaping (Owner) -> Void) -> Self {
        assertSetExecutionPossible()
        execution = { owner, _ in
            queue.execute { block(owner) }
        }
        return self
    }

    /// set factory for task
    /// this task will creted triggered when command triggered
    ///
    /// - Parameter factory: task factory
    /// - Returns: self
    public func task<TRes>(factory: @escaping (Owner) -> Task<TRes>) -> Self {
        assertSetExecutionPossible()
        execution = { owner, param in
            factory(owner).map { _ in Void() }
        }
        return self
    }

    /// sets predicate that can prevent command execution
    /// it'l be called before each command execution
    ///
    /// - Parameter check: condition to check
    /// - Returns: execute comand or not
    public func predicate(check: @escaping (Owner) -> Bool) -> Self {
        assertSetPredicatePossible()
        predicate = { owner, param in
            check(owner)
        }
        return self
    }
}

extension OwnedCommand {

    /// Creates generic version of commmand with the execution block for command
    ///
    /// - Parameters:
    ///   - queue: dispatch queue for block execution
    ///   - block: block that executed if command triggered
    /// - Returns: self
    public func action<Param>(queue: DispatchQueue = DispatchQueue.main, block: @escaping (Owner, Param) -> Void) -> OwnedCommandGeneric<Owner, Param> {
        assertCanMakeGeneric()
        let command = OwnedCommandGeneric<Owner, Param>(owner!)
        command.execution = { vm, param in
            queue.execute { block(vm, param as! Param) }
        }
        return command
    }

    /// Creates generic version of commmand with the factory for task
    /// this task will creted triggered when command triggered
    ///
    /// - Parameter factory: task factory
    /// - Returns: self
    public func taskg<Param, TRes>(factory: @escaping (Owner, Param) -> Task<TRes>) -> OwnedCommandGeneric<Owner, Param> {
        assertCanMakeGeneric()
        let command = OwnedCommandGeneric<Owner, Param>(owner!)
        command.execution = { exec, param in
            factory(exec, param as! Param).map { _ in Void() }
        }
        return command
    }
}

/// Parametrized version of OwnedCommand
/// this type of command hold weak reference to owner object
/// and pass this object to execution and cheking actions
/// if executor doesn't excist any more then canExecute() returns false
public class OwnedCommandGeneric<Owner: AnyObject, Param>: BaseCommand<Owner> {

    public override func canExecuteImpl(parameter: Any?) -> Bool {
        return parameter is Param && super.canExecuteImpl(parameter: parameter)
    }

    /// sets predicate that can prevent command execution
    /// it'l be called before each command execution
    ///
    /// - Parameter check: condition to check
    /// - Returns: execute comand or not
    public func predicate(check: @escaping (Owner, Param) -> Bool) -> Self {
        assertSetPredicatePossible()
        predicate = { (exec: Owner, param: Any?) in
            return check(exec, param as! Param)
        }
        return self
    }
}

/// Simple serial command parametersless implementation
/// it checks predicate after that executes action or task
public class UnownedCommand: OwnedCommand<AnyObject> {

    private let fakeOwner = FakeOwner()

    init() {
        super.init(fakeOwner)
    }

    /// sets predicate that can prevent command execution
    /// it'l be called before each command execution
    ///
    /// - Parameter check: condition to check
    /// - Returns: execute comand or not
    public func predicate(check: @escaping () -> Bool) -> Self {
        assertSetPredicatePossible()
        _ = super.predicate { _ in check() }
        return self
    }
}

/// Simple serial command paramerized implementation
/// it checks predicate after that executes action or task
public class UnownedCommandGeneric<T>: OwnedCommandGeneric<AnyObject, T>  {

    private let fakeOwner = FakeOwner()

    init() {
        super.init(fakeOwner)
    }

    /// sets predicate that can prevent command execution
    /// it'l be called before each command execution
    ///
    /// - Parameter check: condition to check
    /// - Returns: execute comand or not
    public func predicate(check: @escaping (T) -> Bool) -> Self {
        _ = super.predicate { (a: AnyObject, param: T) in
            return check(param)
        }
        return self
    }
}

private class FakeOwner {
}


extension BaseCommand {

    func assertSetExecutionPossible() {
        if execution != nil {
            preconditionFailure("execution block or task has been set already")
        }
    }

    func assertSetPredicatePossible() {
        if predicate != nil {
            preconditionFailure("predicate block has been set already")
        }
    }

    func assertCanMakeGeneric() {
        assertSetExecutionPossible()
        assertSetPredicatePossible()
    }
}
