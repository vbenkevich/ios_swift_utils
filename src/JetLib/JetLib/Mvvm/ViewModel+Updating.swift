//
//  Created on 02/10/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation
import UIKit

public protocol UpdateInitiator: class {

    func updateStarted()

    func updateCompleted()

    func updateNotStarted()
}

public protocol Updatable {

    func dataUpdateRequested(initiator: UpdateInitiator)
}

public extension ViewModel {

    func reload(force: Bool = false) {
        guard force else {
            self.dataUpdateRequested(initiator: self)
            return
        }

        cancelAll().notify { _ in
            self.dataUpdateRequested(initiator: self)
        }
    }
}

extension ViewModel: UpdateInitiator {

    @objc
    open func updateNotStarted() {
    }

    @objc
    open func updateStarted() {
    }

    @objc
    open func updateCompleted() {
    }
}

extension ViewModel: Updatable {

    public func dataUpdateRequested(initiator: UpdateInitiator) {
        guard canLoadData else {
            initiator.updateNotStarted()
            return
        }

        initiator.updateStarted()

        self.startLoadData().notify(DispatchQueue.main) { _ in
            initiator.updateCompleted()
        }
    }
}

extension DispatchGroup: UpdateInitiator {

    public func updateStarted() {
        self.enter()
    }

    public func updateCompleted() {
        self.leave()
    }

    public func updateNotStarted() {
    }
}

extension UIRefreshControl: UpdateInitiator {

    public func updateStarted() {
    }

    public func updateCompleted() {
        self.endRefreshing()
    }

    public func updateNotStarted() {
        self.endRefreshing()
    }
}

extension Array: Updatable where Element == Updatable {

    public func dataUpdateRequested(initiator: UpdateInitiator) {
        guard initiator.associatedGroup == nil else {
            return
        }
        let group = DispatchGroup()
        initiator.associatedGroup = group

        initiator.updateStarted()

        for updatable in self {
            updatable.dataUpdateRequested(initiator: group)
        }

        group.notify(queue: DispatchQueue.main) {
            initiator.updateCompleted()
            initiator.associatedGroup = nil
        }
    }
}

private var updateInitiatorKey = 0

private extension UpdateInitiator {

    var associatedGroup: DispatchGroup? {
        get { return objc_getAssociatedObject(self, &updateInitiatorKey) as? DispatchGroup }
        set { objc_setAssociatedObject(self, &updateInitiatorKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
}
