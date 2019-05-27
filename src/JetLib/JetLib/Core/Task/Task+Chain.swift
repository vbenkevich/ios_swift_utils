//
//  Created on 22/08/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

public extension Task {

    @discardableResult
    func chain<K>(queue: DispatchQueue = DispatchQueue.global(qos: .userInitiated), nextTask: @escaping (Task<T>) -> Task<K>) -> Task<K> {
        let tcs = Task<K>.Source()

        self.notify(queue: queue) { _ in
            let task = nextTask(self)
            task.notify {
                try? tcs.setStatus($0.status)
            }
        }

        return tcs.task
    }

    @discardableResult
    func chainOnSuccess<K>(queue: DispatchQueue = DispatchQueue.global(qos: .userInitiated), nextTask: @escaping (T) throws -> Task<K>) -> Task<K>{
        return chain(queue: queue) {
            if $0.isSuccess {
                do {
                    return try nextTask($0.result!)
                } catch {
                    return Task<K>(error)
                }
            } else if $0.isCancelled {
                return Task<K>(status: .cancelled)
            } else if $0.isFailed {
                return Task<K>($0.error!)
            } else {
                preconditionFailure("inconsistent state")
            }
        }
    }

    @discardableResult
    func chainOnFail(queue: DispatchQueue = DispatchQueue.global(qos: .userInitiated), nextTask: @escaping (Error) -> Task<T>) -> Task<T>{
        return chain(queue: queue) {
            if $0.isSuccess {
                return Task($0.result!)
            } else if $0.isCancelled {
                return Task(status: .cancelled)
            } else if $0.isFailed {
                return nextTask($0.error!)
            } else {
                preconditionFailure("inconsistent state")
            }
        }
    }

    @discardableResult
    func onSuccess(queue: DispatchQueue = DispatchQueue.main, callback: @escaping (T) -> Void) -> Task<T>{
        return notify(queue: queue) {
            if $0.isSuccess {
                callback($0.result!)
            }
        }
    }

    @discardableResult
    func onFail(queue: DispatchQueue = DispatchQueue.main, callback: @escaping (Error) -> Void) -> Task<T>{
        return notify(queue: queue) {
            if $0.isFailed {
                callback($0.error!)
            }
        }
    }

    @discardableResult
    func onCancel(queue: DispatchQueue = DispatchQueue.main, callback: @escaping () -> Void) -> Task<T>{
        return notify(queue: queue) {
            if $0.isCancelled {
                callback()
            }
        }
    }

    func map<K>(mapper: @escaping (T) throws -> K) -> Task<K> {
        return chainOnSuccess {
            do {
                return Task<K>(try mapper($0))
            } catch {
                return Task<K>(error)
            }
        }
    }

    func void() -> Task<Void> {
        return self.map { _ in Void() }
    }
}
