//
//  Created on 01/12/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

public extension ViewModel {

    public class DataLoader {

        private let syncQueue: DispatchQueue

        init(syncQueue: DispatchQueue) {
            self.syncQueue = syncQueue
        }

        private var tasks = [NotifyCompletion & Cancellable]()
        private var loading: Task<TaskGroup>!

        var isLoading: Bool {
            return loading != nil && !loading.isCompleted
        }

        @discardableResult
        public func append<T>(_ task: Task<T>) throws -> Task<T> {
            return try syncQueue.sync {
                guard loading == nil else {
                    throw Exception("Data loading has already been started ar cancelled.")
                }

                tasks.append(task)

                return task
            }
        }

        @discardableResult
        func load() -> Task<TaskGroup> {
            return syncQueue.sync {
                if loading == nil {
                    let group = TaskGroup(tasks)
                    loading = group.whenAll()
                    loading.linked = group
                }

                return loading!
            }
        }

        @discardableResult
        func abort() -> NotifyCompletion {
            let task = load()
            try? task.cancel()
            return task
        }
    }
}
