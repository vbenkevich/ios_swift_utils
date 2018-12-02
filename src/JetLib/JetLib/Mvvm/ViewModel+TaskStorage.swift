//
//  Created on 02/12/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

extension ViewModel {

    final class TaskStorage: NotifyCompletion {

        private let workQueue: DispatchQueue

        init(workQueue: DispatchQueue) {
            self.workQueue = workQueue
            workItem.perform()
        }

        private (set) var workItem = DispatchWorkItem {}

        private (set) var tagged = [String: Cancellable]()

        private (set) var all = [NotifyCompletion & Cancellable]() {
            didSet {
                if oldValue.isEmpty {
                    workItem = DispatchWorkItem {}
                }

                if all.isEmpty {
                    workItem.perform()
                }
            }
        }

        func notify(_ queue: DispatchQueue, callBack: @escaping (TaskStorage) -> Void) -> TaskStorage {
            workItem.notify(queue: queue) {
                callBack(self)
            }

            return self
        }

        func append<T>(task: Task<T>, tag: DataTaskTag? = nil) -> Task<T> {
            workQueue.sync {
                all.append(task)

                if let tag = tag  {
                    try? tagged[tag]?.cancel()

                    tagged[tag] = task

                    task.notify(workQueue) { [weak self] (_) in
                        guard let storage = self, let old = storage.tagged[tag], old === task else { return }
                        storage.tagged.removeValue(forKey: tag)
                    }
                }
            }

            return task.notify(workQueue) { [weak self] (_) in
                guard let storage = self else { return }
                storage.all = storage.all.filter { return $0 !== task }
            }
        }

        func tryCancelAll() {
            workQueue.sync {
                for task in self.all {
                    try? task.cancel()
                }
            }
        }
    }

}
