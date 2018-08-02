//
//  Task.swift
//
//  Created by Vladimir Benkevich
//  Copyright © 2018
//

import Foundation

typealias SpinLock = os_unfair_lock

extension SpinLock {

    mutating func lock() {
        os_unfair_lock_lock(&self)
    }

    mutating func unlock() {
        os_unfair_lock_unlock(&self)
    }
}

protocol Cancellable: class {

    func cancel() throws
}

public enum TaskError: Swift.Error {

    case taskCancelled
    case inconsistentState(message: String)
}

public class Task<T>: Cancellable {

    private var lock = SpinLock()
    private var notifyItem = DispatchWorkItem {}
    private (set) var executeItem: DispatchWorkItem!

    public init(_ execute: @escaping () throws -> T) {
        executeItem = DispatchWorkItem {
            do {
                try self.setStatus(.executing)
                let data = try execute()
                try? self.setStatus(.success(data))
            } catch {
                try? self.setStatus(.failed(error: error))
            }
        }

        executeItem.notify(queue: DispatchQueue.main) { [notifyItem] in
            notifyItem.perform()
        }
    }

    private init(_ workItem: DispatchWorkItem) {
        executeItem = workItem

        notifyItem.notify(queue: DispatchQueue.main) { [notifyItem] in
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

    fileprivate func setStatus(_ status: Status) throws {
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
    public func notify(_ queue: DispatchQueue = DispatchQueue.main, callBack: @escaping (Task<T>) -> Void) -> Task<T> {
        if status.completed {
            callBack(self)
            return self
        }

        notifyItem.notify(queue: queue) {
            callBack(self)
        }

        return self
    }

    @discardableResult
    public func chain<K>(factory: @escaping (Task<T>) -> Task<K>) -> Task<K> {
        let tcs = Task<K>.Source()

        notifyItem.notify(queue: DispatchQueue.main) {
            let task = factory(self)
            task.notify {
                try? tcs.setStatus($0.status)
            }
        }

        return tcs.task
    }

    public func cancel() throws {
        try setStatus(.cancelled)
        notifyItem.perform()
        executeItem.cancel()
        try linked?.cancel()
    }

    public enum Status: Equatable {

        case new
        case executing
        case success(_: T)
        case cancelled
        case failed(error: Swift.Error)

        var completed: Bool {
            switch self {
            case .success(_), .cancelled, .failed(_):
                return true
            default:
                return false
            }
        }

        public static func == (lhs: Task<T>.Status, rhs: Task<T>.Status) -> Bool {
            switch (lhs, rhs) {
            case (.new, .new):
                return true
            case (.executing, .executing):
                return true
            case (.cancelled, .cancelled):
                return true
            case (.failed(_), .failed(_)):
                return true
            case (.success(_), .success(_)):
                return true
            default:
                return false
            }
        }
    }

    public class Source {

        private var workItem: DispatchWorkItem!

        public init() {
            workItem = DispatchWorkItem {}
            task = Task(workItem)
            task._status = .executing
        }

        public private (set) var task: Task<T>

        public func complete(_ result: T) throws {
            try task.setStatus(.success(result))
            workItem.perform()
        }

        public func cancel(_ result: T) throws {
            try task.setStatus(.cancelled)
            workItem.cancel()
        }

        fileprivate func setStatus(_ status: Task<T>.Status) throws {
            try task.setStatus(status)
            workItem.perform()
        }
    }
}
