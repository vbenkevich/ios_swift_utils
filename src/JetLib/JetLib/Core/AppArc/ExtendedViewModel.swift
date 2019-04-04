//
//  Created on 27/12/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation
import UIKit

public extension ViewModel {

    @discardableResult
    func lifecycle(source: View, isSourceRetainViewModel: Bool = true) -> Self {
        source.sendViewAppearance(to: self, retain: isSourceRetainViewModel)
        return self
    }
}

open class ExtendedViewModel: ViewModel {

    public weak var loadingPresenter: LoadingPresenter? = nil

    public weak var alertPresenter: AlertPresenter? = nil

    private var isLoading: Bool = false {
        didSet {
            guard oldValue != isLoading else {
                return
            }

            loadingPresenter?.showLoading(isLoading)
        }
    }

    override open func viewWillAppear(_ animated: Bool) {
        isLoading = loading
        super.viewWillAppear(animated)
    }

    @discardableResult
    override open func submit<TData>(task: Task<TData>, tag: DataTaskTag? = nil) -> Task<TData> {
        if !loading {
            self.updateStarted()
        }

        return super.submit(task: task, tag: tag).notify { [weak self] _ in
            if self?.loading == false {
                self?.updateCompleted()
            }
        }.onFail { [weak self] in
            self?.showAlert(error: $0)
        }
    }

    override open func newLoader() -> ViewModel.DataLoader {
        return ShowErrorDecorator(super.newLoader(), viewModel: self)
    }

    override open func updateStarted() {
        isLoading = true
    }

    override open func updateCompleted() {
        isLoading = false
    }

    class ShowErrorDecorator: DataLoader {

        private let decoree: DataLoader
        private weak var viewModel: ExtendedViewModel?

        init(_ decoree: DataLoader, viewModel: ExtendedViewModel) {
            self.decoree = decoree
            self.viewModel = viewModel
        }

        var isLoading: Bool {
            return decoree.isLoading
        }

        func append<T>(_ task: Task<T>) throws -> Task<T> {
            let originTask = try decoree.append(task)

            originTask.onFail { [weak self] in
                self?.viewModel?.showAlert(error: $0)
            }

            return originTask
        }

        func load() -> Task<Void> {
            return decoree.load()
        }

        func abort() -> NotifyCompletion {
            return decoree.abort()
        }
    }
}

public extension ExtendedViewModel {

    typealias ExtendedView = View & AlertPresenter & LoadingPresenter

    @discardableResult
    func loadings(presenter: LoadingPresenter?) -> ExtendedViewModel {
        self.loadingPresenter = presenter
        return self
    }

    @discardableResult
    func alerts(presenter: AlertPresenter) -> ExtendedViewModel {
        self.alertPresenter = presenter
        return self
    }

    @discardableResult
    func wire(with view: ExtendedView) -> ExtendedViewModel {
        return self.lifecycle(source: view)
            .loadings(presenter: view)
            .alerts(presenter: view)
    }
}

extension ExtendedViewModel: AlertPresenter {

    @discardableResult
    public func showAlert(title: String?, message: String?, ok: String, cancel: String?) -> Task<Void> {
        return self.alertPresenter?.showAlert(title: title, message: message, ok: ok, cancel: cancel)
            ?? Task(Exception("alertPresenter doesn't set"))
    }

    @discardableResult
    public func showAlert(title: String?, message: String?, delete: String, cancel: String?) -> Task<Void> {
        return self.alertPresenter?.showAlert(title: title, message: message, delete: delete, cancel: cancel)
            ?? Task(Exception("alertPresenter doesn't set"))
    }
}
