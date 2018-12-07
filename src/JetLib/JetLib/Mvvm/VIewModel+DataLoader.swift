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
        private var loading: TaskGroup!

        var isLoading: Bool {
            return loading != nil && !loading.whenAll().isCompleted
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
                    loading = TaskGroup(tasks)
                    loading.whenAll().linked = loading
                }

                return loading.whenAll()
            }
        }

        @discardableResult
        func abort() -> NotifyCompletion {
            return syncQueue.sync {
                if loading == nil {
                    return Task()
                }
                loading.cancel()
                return loading.whenAll()
            }
        }
    }
}
