//
//  Created on 02/11/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

public protocol ErrorPresenter: class {

    func showError(message: String?)

    func hideError()
}

public extension Binding {

    /// errorPresenter doesn't retain
    @discardableResult
    func with(errorPresenter: ErrorPresenter) throws -> Binding {
        guard let validation = observable.validation else {
            throw Exception.noValidationAtObservable
        }

        guard let target = target else {
            throw Exception("BindingTarget == nil")
        }

        target.errorPresenter = errorPresenter

        validation.notify(target) {
            guard let result = $1, let presenter = $0.errorPresenter else {
                return
            }
            if result.isValid {
                presenter.hideError()
            } else {
                presenter.showError(message: result.error)
            }
        }

        validation.invalidate()

        if mode.contains(.updateObservable), let control = target as? UIControl {
            control.addTarget(validation.editingDelegate, action: #selector(ControlEditingDelegate.editingDidEnd), for: .editingDidEnd)
            control.addTarget(validation.editingDelegate, action: #selector(ControlEditingDelegate.editingDidBegin), for: .editingDidBegin)
        }

        return self
    }
}

public extension BindingTarget {

    fileprivate var errorPresenter: ErrorPresenter? {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.errorPresenterKey) as? ErrorPresenter }
        set { objc_setAssociatedObject(self, &AssociatedKeys.errorPresenterKey, newValue, .OBJC_ASSOCIATION_ASSIGN) }
    }
}

extension UILabel: ErrorPresenter {

    @objc public func showError(message: String?) {
        text = message
        isHidden = false
    }

    @objc public func hideError() {
        isHidden = true
    }
}

private struct AssociatedKeys {
    static var errorPresenterKey = 0
}

private extension Exception {

    static let noValidationAtObservable = Exception("Observable has no validation. Call observable.withValidation() or observable.addValidationRule() before setting ErrorPresenter")
}
