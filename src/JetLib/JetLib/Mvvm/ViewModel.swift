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

open class ViewModel: ViewLifecycleDelegate {

    public init() {
    }

    private let submitedTasks = TaskStorage(workQueue: dataLoaderQueue)

    private var loader: DataLoader? {
        didSet {
            oldValue?.abort()
        }
    }

    open var loading: Bool {
        return !submitedTasks.all.isEmpty || loader != nil
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
        loader?.abort()
    }

    open func willLoadData(loader: DataLoader) {
    }

    public func startLoadData() -> NotifyCompletion {
        let loader = DataLoader(syncQueue: dataLoaderQueue)
        willLoadData(loader: loader)
        return loadData()
    }

    @discardableResult
    @available(*, deprecated, message: "use willLoadData instead")
    open func loadData() -> NotifyCompletion {
        if loader == nil {
            loader = DataLoader(syncQueue: dataLoaderQueue)
        }

        return performDataLoading(loader: loader!)
    }

    open func loadDataCompleted() {
    }

    @discardableResult
    open func submit<TData>(task: Task<TData>, tag: DataTaskTag? = nil) -> Task<TData> {
        return submitedTasks.append(task: task, tag: tag)
    }

    @discardableResult
    public func load<TData>(task: Task<TData>) -> Task<TData> {
        if loader == nil {
            loader = DataLoader(syncQueue: dataLoaderQueue)
        }

        return try! loader!.append(task)
    }

    @discardableResult
    public func cancelAll() -> NotifyCompletion {
        return loader?.abort() ?? Task()
    }

    func performDataLoading(loader: DataLoader) -> NotifyCompletion {
        self.loader = loader

        return loader.load().notify { [weak self] (_) in
            if self?.loader === loader {
                self?.loader = nil
            }

            self?.loadDataCompleted()
        }
    }
}
