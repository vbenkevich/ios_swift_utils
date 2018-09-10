//
//  Created on 22/08/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

protocol Cancellable: class {

    func cancel() throws
}

public protocol NotifyCompletion: class {

    @discardableResult
    func notify(_ queue: DispatchQueue, callBack: @escaping (Self) -> Void) -> Self
}

public extension NotifyCompletion {

    @discardableResult
    func notify(callBack: @escaping (Self) -> Void) -> Self {
        return notify(DispatchQueue.main, callBack: callBack)
    }
}

public enum TaskError: Swift.Error {

    case taskCancelled
    case inconsistentState(message: String)
}

public final class Task<T>: Cancellable, NotifyCompletion {

    private var lock = SpinLock()
    private var notifyItem = DispatchWorkItem {}
    private (set) var executeItem: DispatchWorkItem!

    public init(_ result: T) {
        notifyItem.perform()
        _status = .success(result)
    }

    public init(_ execute: @escaping () throws -> T) {
        executeItem = DispatchWorkItem {
            do {
                try self.setStatus(.executing)
                let data = try execute()
                try? self.setStatus(.success(data))
            } catch {
                try? self.setStatus(.failed(error))
            }
        }

        executeItem.notify(queue: DispatchQueue.global(qos: .userInitiated)) { [notifyItem] in
            notifyItem.perform()
        }
    }

    init(_ workItem: DispatchWorkItem) {
        executeItem = workItem
        executeItem.notify(queue: DispatchQueue.global(qos: .userInitiated)) { [notifyItem] in
            notifyItem.perform()
        }
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

    func setStatus(_ status: Status) throws {
        lock.lock()
        defer {
            lock.unlock()
        }

        guard !_status.completed else {
            throw TaskError.inconsistentState(message: "task has completed state")
        }

        _status = status
    }

    weak var linked: Cancellable?

    private var _status: Status = .new

    @discardableResult
    public func notify(_ queue: DispatchQueue, callBack: @escaping (Task<T>) -> Void) -> Task<T> {
        if status.completed {
            callBack(self)
            return self
        }

        notifyItem.notify(queue: queue) {
            callBack(self)
        }

        return self
    }

    public func cancel() throws {
        try setStatus(.cancelled)
        notifyItem.perform()
        executeItem.cancel()
        try linked?.cancel()
    }
}
