//
//  Created on 02/05/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation

/// Base class for simple SerialCommand implementations
/// it checks predicate after that executes action or task
public class SimpleCommandBase: SerialCommand {

    var execution: ((Any?) -> Task<Void>)!
    var predicate: (Any?) -> Bool = { _ in true }

    public final override func executeImpl(parameter: Any?) -> DispatchWorkItem {
        return execution(parameter).workItem
    }

    public final override func canExecuteImpl(parameter: Any?) -> Bool {
        return predicate(parameter) != false
    }
}

/// Simple serial command parametersless implementation
/// it checks predicate after that executes action or task
public class SimpleCommand: SimpleCommandBase {

    /// sets predicate that can prevent command execution
    /// it'l be called before each command execution
    ///
    /// - Parameter check: condition to check
    /// - Returns: execute comand or not
    public func predicate(check: @escaping () -> Bool) -> Self {
        predicate = { _ in check() }
        return self
    }
}

/// Simple serial command paramerized implementation
/// it checks predicate after that executes action or task
public class SimpleCommandGeneric<T>: SimpleCommandBase {

    /// sets predicate that can prevent command execution
    /// it'l be called before each command execution
    ///
    /// - Parameter check: condition to check
    /// - Returns: execute comand or not
    public func predicate(check: @escaping (T) -> Bool) -> Self {
        predicate = { param in
            if let typed = param as? T {
                return check(typed)
            } else {
                return false
            }
        }
        return self
    }
}
