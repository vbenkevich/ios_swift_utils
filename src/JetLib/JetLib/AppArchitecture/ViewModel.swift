//
//  Created on 02/10/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

private let dataLoaderQueue: DispatchQueue = DispatchQueue(label: "viewModel.taskStorage", qos: DispatchQoS.userInitiated)

public typealias DataTaskTag = String

public extension DataTaskTag {

    public static var singleTaskTag: DataTaskTag { return "singleTaskTag" }
}

open class ViewModel<TView: View>: ViewLifecycleDelegate {

    private let taskStorage: TaskStorage

    public init() {
        self.taskStorage = TaskStorage(workQueue: dataLoaderQueue)
    }

    public weak var view: TView?

    open var loading: Bool {
        return !taskStorage.all.isEmpty
    }

    open var canLoadData: Bool {
        return !loading
    }

    open func viewWillAppear(_ animated: Bool) {
        dataUpdateRequested(initiator: self)
    }

    open func viewDidAppear(_ animated: Bool) {
    }

    open func viewWillDisappear(_ animated: Bool) {
    }

    open func viewDidDisappear(_ animated: Bool) {
        taskStorage.tryCancelAll()
    }

    @discardableResult
    open func loadData() -> NotifyCompletion {
        return taskStorage.notify(DispatchQueue.main) { [weak self] (_) in self?.loadDataCompleted() }
    }

    open func loadDataCompleted() {
    }

    @discardableResult
    open func submit<TData>(task: Task<TData>, tag: DataTaskTag? = nil) -> Task<TData> {
        self.updateStarted()
        return taskStorage.append(task: task, tag: tag)
            .notify(DispatchQueue.main) { [weak self] (_) in
                self?.updateCompleted()
        }
    }

    @discardableResult
    public func load<TData>(task: Task<TData>, tag: DataTaskTag? = .singleTaskTag) -> Task<TData> {
        return taskStorage.append(task: task, tag: tag)
    }

    @discardableResult
    public func cancelAll() -> DispatchWorkItem {
        taskStorage.tryCancelAll()
        return taskStorage.workItem
    }
}

fileprivate final class TaskStorage: NotifyCompletion {

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
