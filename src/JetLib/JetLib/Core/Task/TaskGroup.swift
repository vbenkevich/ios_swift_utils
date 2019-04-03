//
//  Created on 29/08/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

public protocol TaskGroupDelegate: class {

    func taskFinished(group: TaskGroup, task: NotifyCompletion)
}

public extension Array where Element: NotifyCompletion & Cancellable {

    func whenAll() -> Task<Void> {
        return TaskGroup(self).whenAll()
    }

    func whenAny() -> Task<Void> {
        return TaskGroup(self).whenAny()
    }

    public func whenAll(_ queue: DispatchQueue = DispatchQueue.main, callback: @escaping () -> Void) {
        self.whenAll().notify(queue: queue) { _ in
            callback()
        }
    }

    public func whenAny(_ queue: DispatchQueue = DispatchQueue.main, callback: @escaping () -> Void) {
        self.whenAny().notify(queue: queue) { _ in
            callback()
        }
    }
}

public extension TaskGroup {

    public func whenAll(_ queue: DispatchQueue = DispatchQueue.main, callback: @escaping () -> Void) {
        self.whenAll().notify(queue: queue) { _ in callback() }
    }

    public func whenAny(_ queue: DispatchQueue = DispatchQueue.main, callback: @escaping () -> Void) {
        self.whenAny().notify(queue: queue) { _ in callback() }
    }
}

public final class TaskGroup: Cancellable {

    private let workQueue = DispatchQueue(label: "taskGroup")

    public init(_ tasks: [NotifyCompletion & Cancellable]) {
        self.tasks = tasks

        for task in tasks {
            group.enter()

            task.notify(queue: workQueue) { [whenAnySource, group, weak self] in
                try? whenAnySource.complete()
                group.leave()

                if let gr = self {
                    gr.delegate?.taskFinished(group: gr, task: $0)
                }
            }
        }

        if tasks.isEmpty {
            try? whenAnySource.complete()
        }

        group.notify(queue: workQueue) { [whenAllSource] in
            try? whenAllSource.complete()
        }
    }

    private let whenAnySource = Task<Void>.Source()
    private let whenAllSource = Task<Void>.Source()
    private let group = DispatchGroup()

    public let tasks: [NotifyCompletion & Cancellable]

    public weak var delegate: TaskGroupDelegate?

    public func whenAll() -> Task<Void> {
        return whenAllSource.task
    }

    public func whenAny() -> Task<Void> {
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
