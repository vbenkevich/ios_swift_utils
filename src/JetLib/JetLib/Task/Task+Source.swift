//
//  Created on 22/08/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

public extension Task {

    public class Source {

        private var workItem: DispatchWorkItem = DispatchWorkItem {}

        public init() {
            task = Task(workItem)
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
            workItem.perform()
        }
    }
}
