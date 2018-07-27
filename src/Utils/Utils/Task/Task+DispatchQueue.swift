//
//  Task+DispatchQueue.swift
//
//  Created by Vladimir Benkevich
//  Copyright © 2018
//

import Foundation

public extension DispatchQueue {

    func await<T>(task: Task<T>) throws -> T {
        self.sync(execute: task.workItem)

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

    func async<T>(_ task: Task<T>) {
        self.async(execute: task.workItem)
    }

    func async<T>(_ task: Task<T>, after interval: DispatchTimeInterval) {
        self.asyncAfter(deadline: .now() + interval, execute: task.workItem)
    }
}
