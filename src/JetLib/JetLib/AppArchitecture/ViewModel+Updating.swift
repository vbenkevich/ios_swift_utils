//
//  Created on 02/10/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

public protocol UpdateInitiator: class {

    func updateStarted()

    func updateCompleted()

    func updateAborted()
}

public protocol Updatable {

    func dataUpdateRequested(initiator: UpdateInitiator)
}

extension ViewModel: UpdateInitiator {

    open func updateAborted() {
    }

    open func updateStarted() {
        (view as? DataLoadingPresenter)?.showLoading(true)
    }

    open func updateCompleted() {
        (view as? DataLoadingPresenter)?.showLoading(false)
    }
}

extension ViewModel: Updatable {

    public func dataUpdateRequested(initiator: UpdateInitiator) {
        guard canLoadData else {
            initiator.updateAborted()
            return
        }

        initiator.updateStarted()

        self.loadData().notify(DispatchQueue.main) { _ in
            initiator.updateCompleted()
        }
    }
}
