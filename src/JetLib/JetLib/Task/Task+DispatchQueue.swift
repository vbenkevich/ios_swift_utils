//
//  Created on 22/08/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

public extension DispatchQueue {

    @discardableResult
    func await<T>(task: Task<T>) throws -> T {
        self.sync { task.item.perform() }

        switch task.status {
        case .success(let result):
            return result
        case .cancelled:
            throw TaskException.taskAlreadyCancelled
        case .failed(let error):
            throw error
        default:
            throw TaskException.cantCompleteTask
        }
    }

    @discardableResult
    func async<T>(_ task: Task<T>) -> Task<T> {
        self.async { task.item.perform() }
        return task
    }

    @discardableResult
    func async<T>(_ task: Task<T>, after interval: DispatchTimeInterval) -> Task<T> {
        self.asyncAfter(deadline: .now() + interval) { task.item.perform() }
        return task
    }
}

public class TaskException: Exception {

    static let taskAlreadyCompleted = TaskException("Task has been completed")
    static let taskAlreadyCancelled = TaskException("Task has been cancelled")
    static let cantCompleteTask = TaskException("Unable to complete task")
}
