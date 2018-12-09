//
//  Created on 29/08/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

public protocol TaskGroupDelegate: class {

    func taskFinished(group: TaskGroup, task: NotifyCompletion)
}

public extension Array where Element: NotifyCompletion & Cancellable {

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

public final class TaskGroup: Cancellable {

    private let workQueue = DispatchQueue(label: "taskGroup")

    public init(_ tasks: [NotifyCompletion & Cancellable]) {
        self.tasks = tasks

        for task in tasks {
            group.enter()

            task.notify(workQueue) {
                try? self.whenAnySource.complete(self)

                self.group.leave()
                self.delegate?.taskFinished(group: self, task: $0)
            }
        }

        if tasks.isEmpty {
            try? whenAnySource.complete(self)
        }

        whenAllSource.task.retainedObjects.append(self)

        group.notify(queue: workQueue) {
            try? self.whenAllSource.complete(self)
        }
    }

    private let whenAnySource = Task<TaskGroup>.Source()
    private let whenAllSource = Task<TaskGroup>.Source()
    private let group = DispatchGroup()

    public let tasks: [NotifyCompletion & Cancellable]

    public weak var delegate: TaskGroupDelegate?

    public func whenAll() -> Task<TaskGroup> {
        return whenAllSource.task
    }

    public func whenAny() -> Task<TaskGroup> {
        return whenAnySource.task
    }

    public func cancel() {
        try? whenAllSource.cancel()
        try? whenAnySource.cancel()

        for task in tasks {
            try? task.cancel()
        }
    }
}
