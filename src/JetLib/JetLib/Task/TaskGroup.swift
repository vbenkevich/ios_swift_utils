//
//  Created on 29/08/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

public protocol TaskGroupDelegate: class {

    func taskFinished(group: TaskGroup, task: NotifyCompletion)
}

public extension Array where Element: NotifyCompletion {

    func whenAll() -> Task<TaskGroup> {
        return TaskGroup(self).whenAll()
    }

    func whenAny() -> Task<TaskGroup> {
        return TaskGroup(self).whenAny()
    }

    public func whenAll(_ queue: DispatchQueue = DispatchQueue.main, callback: @escaping (TaskGroup) -> Void) {
        self.whenAll().notify(queue) {
            callback($0.result!)
        }
    }

    public func whenAny(_ queue: DispatchQueue = DispatchQueue.main, callback: @escaping (TaskGroup) -> Void) {
        self.whenAny().notify(queue) {
            callback($0.result!)
        }
    }
}

public extension TaskGroup {

    public func whenAll(_ queue: DispatchQueue = DispatchQueue.main, callback: @escaping (TaskGroup) -> Void) {
        self.whenAll().notify(queue) {
            callback($0.result!)
        }
    }

    public func whenAny(_ queue: DispatchQueue = DispatchQueue.main, callback: @escaping (TaskGroup) -> Void) {
        self.whenAny().notify(queue) {
            callback($0.result!)
        }
    }
}

public final class TaskGroup {

    private let workQueue = DispatchQueue(label: "taskGroup")

    public init(_ tasks: [NotifyCompletion]) {
        self.tasks = tasks

        if tasks.isEmpty {
            allQueue = nil
            anyQueue = nil
        } else {
            allQueue = []
            anyQueue = []
        }

        subscribe(tasks)
    }

    public let tasks: [NotifyCompletion]

    public weak var delegate: TaskGroupDelegate?

    private var completed: Int = 0
    private var allQueue: [Task<TaskGroup>.Source]?
    private var anyQueue: [Task<TaskGroup>.Source]?

    public func whenAll() -> Task<TaskGroup> {
        let tcs = Task<TaskGroup>.Source()

        workQueue.sync {
            if allQueue != nil {
                allQueue?.append(tcs)
            } else {
                try! tcs.complete(self)
            }
        }

        return tcs.task
    }

    public func whenAny() -> Task<TaskGroup> {
        let tcs = Task<TaskGroup>.Source()

        workQueue.sync {
            if anyQueue != nil {
                anyQueue?.append(tcs)
            } else {
                try! tcs.complete(self)
            }
        }

        return tcs.task
    }

    private func onCompleted(_ task: NotifyCompletion) {
        completed += 1

        if completed == 1 {
            for tcs in anyQueue! {
                try! tcs.complete(self)
            }

            anyQueue = nil
        }

        if completed == tasks.count {
            for tcs in allQueue! {
                try! tcs.complete(self)
            }

            allQueue = nil
        }

        delegate?.taskFinished(group: self, task: task)
    }

    private func subscribe(_ tasks: [NotifyCompletion]) {
        for task in tasks {
            task.notify(workQueue) {
                self.onCompleted($0)
            }
        }
    }
}