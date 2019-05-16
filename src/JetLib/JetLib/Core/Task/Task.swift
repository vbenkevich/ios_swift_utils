//
//  Created on 22/08/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

public protocol Cancellable: class {

    func cancel() throws
}

public protocol NotifyCompletion: class {

    @discardableResult
    func notify(queue: DispatchQueue, callBack: @escaping (Self) -> Void) -> Self
}

public extension NotifyCompletion {

    @discardableResult
    func notify(callBack: @escaping (Self) -> Void) -> Self {
        return notify(queue: DispatchQueue.main, callBack: callBack)
    }
}


public final class Task<T>: Cancellable, NotifyCompletion {

    private var lock = SpinLock()
    private (set) var item: DispatchWorkItem!

    convenience public init(_ result: T) {
        self.init(status: .success(result))
    }

    convenience public init(_ error: Error) {
        self.init(status: .failed(error))
    }

    @available(*, deprecated, renamed: "Task.from" )
    convenience init(execute: @escaping () throws -> T) {
        self.init(block: execute)
    }

    init(block: @escaping () throws -> T) {
        item = DispatchWorkItem {
            do {
                try self.setStatus(.executing)
                let data = try block()
                try? self.setStatus(.success(data))
            } catch {
                try? self.setStatus(.failed(error))
            }
        }
    }

    init(status: Task.Status) {
        _status = status
        item = DispatchWorkItem {}
        workItem.perform()
    }

    init(_ workItem: DispatchWorkItem) {
        item = workItem
    }

    public var result: T? {
        switch status {
        case .success(let res):
            return res
        default:
            return nil
        }
    }

    public var status: Status {
        lock.lock()
        defer {
            lock.unlock()
        }

        return _status
    }

    var workItem: DispatchWorkItem! {
        return item
    }

    func setStatus(_ status: Status) throws {
        lock.lock()
        defer {
            lock.unlock()
        }

        guard !_status.isCompleted else {
            throw TaskException.taskAlreadyCompleted
        }

        _status = status
    }

    weak var linked: Cancellable?

    private var _status: Status = .new

    @discardableResult
    public func notify(queue: DispatchQueue, callBack: @escaping (Task<T>) -> Void) -> Task<T> {
        if status.isCompleted {
            callBack(self)
            return self
        }

        item.notify(queue: queue) {
            callBack(self)
        }

        return self
    }

    public func cancel() throws {
        try setStatus(.cancelled)
        item.perform()
        try linked?.cancel()
    }
}

public extension Task {

    static func from(_ block: @escaping () throws -> T) -> Task<T> {
        return Task(block: block)
    }

    static func cancelled() -> Task {
        return Task(status: .cancelled)
    }
}

public extension Task where T == Void {

    convenience init() {
        self.init(Void())
    }
}
