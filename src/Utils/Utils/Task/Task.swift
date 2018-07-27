//
//  Task.swift
//
//  Created by Vladimir Benkevich
//  Copyright © 2018
//

import Foundation

public class Task<T> {

    private let lock = NSLock()
    var workItem: DispatchWorkItem!

    public init(_ execute: @escaping () throws -> T) {
        self.workItem = DispatchWorkItem {
            do {
                let data = try execute()
                try? self.setStatus(.success(result: data))
            } catch {
                try? self.setStatus(.failed(error: error))
            }
        }
    }

    private init(_ workItem: DispatchWorkItem) {
        self.workItem = workItem
    }

    public var status: Status {
        return _status
    }

    public var result: T? {
        switch status {
        case .success(let res):
            return res
        default:
            return nil
        }
    }

    private var _status: Status = .new

    @discardableResult
    public func notify(_ queue: DispatchQueue = DispatchQueue.main, callBack: @escaping (Task<T>) -> Void) -> Task<T> {
        workItem.notify(queue: queue) {
            callBack(self)
        }
        return self
    }

    @discardableResult
    public func chain<K>(factory: @escaping (Task<T>) -> Task<K>) -> Task<K> {
        let tcs = Task<K>.Source()

        workItem.notify(queue: DispatchQueue.main) {
            let task = factory(self)
            task.notify {
                try? tcs.setStatus($0.status)
            }
        }

        return tcs.task
    }

    public func cancel() throws {
        try setStatus(.cancelled)
        workItem.cancel()
    }

    fileprivate func setStatus(_ status: Status) throws {
        lock.lock()
        defer { lock.unlock() }

        guard !_status.isFinite else {
            throw TaskError.inconsistentState(message: "task has finite state")
        }

        _status = status
    }

    public enum Status {

        case new
        case executing
        case success(result: T)
        case cancelled
        case failed(error: Swift.Error)

        var isFinite: Bool {
            switch self {
            case .success(_), .cancelled, .failed(_):
                return true
            default:
                return false
            }
        }

        var isStarted: Bool {
            switch self {
            case .new:
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
            try task.setStatus(.success(result: result))
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

public enum TaskError: Swift.Error {
    case taskCancelled
    case inconsistentState(message: String)
}

