//
//  Task+Chain.swift
//  Utils
//
//  Created by Vladimir Benkevich on 02/08/2018.
//

import Foundation

public extension Task {

    @discardableResult
    public func chain<K>(factory: @escaping (Task<T>) -> Task<K>) -> Task<K> {
        let tcs = Task<K>.Source()

        notify(DispatchQueue.global(qos: .userInitiated)) { _ in
            let task = factory(self)
            task.notify {
                switch $0.status {
                    case .cancelled: try? tcs.cancel()
                    case .success(let result): try? tcs.complete(result)
                    case .failed(let error): try? tcs.error(error)
                    default: break
                }
            }
        }

        return tcs.task
    }
}
