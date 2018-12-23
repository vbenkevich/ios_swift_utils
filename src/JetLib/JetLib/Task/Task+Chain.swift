//
//  Created on 22/08/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

public extension Task {

    @discardableResult
    public func chain<K>(nextTask: @escaping (Task<T>) -> Task<K>) -> Task<K> {
        let tcs = Task<K>.Source()

        self.notify(queue: DispatchQueue.global(qos: .userInitiated)) { _ in
            let task = nextTask(self)
            task.notify {
                try? tcs.setStatus($0.status)
            }
        }

        return tcs.task
    }

    @discardableResult
    public func chainOnSuccess<K>(nextTask: @escaping (T) throws -> Task<K>) -> Task<K>{
        return chain {
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
    public func onSuccess(queue: DispatchQueue = DispatchQueue.main, callback: @escaping (T) -> Void) -> Task<T>{
        return notify(queue: queue) {
            if $0.isSuccess {
                callback($0.result!)
            }
        }
    }

    @discardableResult
    public func onFail(queue: DispatchQueue = DispatchQueue.main, callback: @escaping (Error) -> Void) -> Task<T>{
        return notify(queue: queue) {
            if $0.isFailed {
                callback($0.error!)
            }
        }
    }

    @discardableResult
    public func onCancel(queue: DispatchQueue = DispatchQueue.main, callback: @escaping () -> Void) -> Task<T>{
        return notify(queue: queue) {
            if $0.isCancelled {
                callback()
            }
        }
    }

    public func map<K>(mapper: @escaping (T) throws -> K) -> Task<K> {
        return chainOnSuccess {
            do {
                return Task<K>(try mapper($0))
            } catch {
                return Task<K>(error)
            }
        }
    }
}
