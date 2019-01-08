//
//  PinpadWidget.ViewModel.swift
//  JetUI
//
//  Created by Vladimir Benkevich on 08/01/2019.
//

import Foundation
import JetLib

extension PinpadWidget {

    class ViewModel {

        init() {
        }

        lazy var deleteCommand = ActionCommand(self, execute: { $0.delete() }, canExecute: { $0.canDelete() })

        lazy var appendCommand = AsyncCommand(self, task: { $0.append($1) })

        var biometricCommand: Command?

        var pincode: String = "" {
            didSet {
                deleteCommand.invalidate()
                view?.pinCodeView.pincode = pincode
            }
        }

        weak var view: PinpadWidget?

        weak var delegate: PinpadDelegate? {
            didSet {
                view?.pinCodeView.setup(delegate: delegate)
            }
        }

        func append(_ symbol: String) -> Task<Void> {
            pincode += symbol

            if let delegate = delegate, delegate.symbolsCount == pincode.count {
                return delegate.check(pincode: pincode).onFail { [weak self] _ in
                    self?.pincode = ""
                }
            } else {
                return Task()
            }
        }

        func delete() {
            pincode = String(pincode.prefix(pincode.count - 1))
        }

        func canDelete() -> Bool {
            guard let maxCount = delegate?.symbolsCount else {
                return false
            }

            return !pincode.isEmpty && pincode.count < maxCount
        }
    }
}
