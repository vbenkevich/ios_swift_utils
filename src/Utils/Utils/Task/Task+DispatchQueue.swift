//
//  Task+DispatchQueue.swift
//
//  Created by Vladimir Benkevich
//  Copyright © 2018
//

import Foundation

public extension DispatchQueue {

    func await<T>(task: Task<T>) throws -> T {
        self.sync(execute: task.executeItem)

        switch task.status {
        case .success(let result):
            return result
        case .cancelled:
            throw TaskError.taskCancelled
        case .failed(let error):
            throw error
        case .executing, .new:
            throw TaskError.inconsistentState(message: "Unable to complete task")
        }
    }

    @discardableResult
    func async<T>(_ task: Task<T>) -> Task<T> {
        self.async(execute: task.executeItem)
        return task
    }

    @discardableResult
    func async<T>(_ task: Task<T>, after interval: DispatchTimeInterval) -> Task<T> {
        self.asyncAfter(deadline: .now() + interval, execute: task.executeItem)
        return task
    }
}
