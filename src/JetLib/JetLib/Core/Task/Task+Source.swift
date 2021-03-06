//
//  Created on 22/08/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

public typealias TaskCompletionSource<T> = Task<T>.Source

public extension Task {

    class Source {

        private var item = DispatchWorkItem {}

        public init() {
            task = Task(item)
            try! task.setStatus(.executing)
        }

        public private (set) var task: Task<T>

        public func complete(_ result: T) throws {
            try setStatus(.success(result))
        }

        public func error(_ error: Error) throws {
            try setStatus(.failed(error))
        }

        public func cancel() throws {
            try setStatus(.cancelled)
        }

        func setStatus(_ status: Task<T>.Status) throws {
            try task.setStatus(status)
            item.perform()
        }
    }
}

public extension Task.Source where T == Void {

    func complete() throws {
        try self.complete(Void())
    }
}
