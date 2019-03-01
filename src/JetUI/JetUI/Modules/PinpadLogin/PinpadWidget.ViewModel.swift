//
//  Created by Vladimir Benkevich on 08/01/2019.
//  Copyright © Vladimir Benkevich 2019
//

import Foundation
import JetLib

extension PinpadWidget {

    class ViewModel {

        private var attempt: Int = 0

        lazy var deleteSymbolCommand = ActionCommand(self,
                                                     execute: { $0.executeDeleteSymbol() },
                                                     canExecute: { $0.canExecuteDeleteSymbol() })

        lazy var appendSymbolCommand = AsyncCommand(self,
                                                    task: { $0.executeAppendSymbol($1) })

        lazy var deviceOwnerAuthCommand = AsyncCommand(self,
                                                       task: { $0.executeDeviceOwnerAuth() },
                                                       canExecute: { $0.canExecuteDeviceOwnerAuth() })

        weak var view: PinpadWidget?

        weak var delegate: PinpadWidgetDelegate?

        var service: PinpadFlowWidgetService? {
            didSet {
                deleteSymbolCommand.invalidate()
                appendSymbolCommand.invalidate()
                deviceOwnerAuthCommand.invalidate()
            }
        }

        var pincode: String = "" {
            didSet {
                deleteSymbolCommand.invalidate()
                deviceOwnerAuthCommand.invalidate()
                view?.pincodeView.pincode = pincode
            }
        }

        fileprivate func executeAppendSymbol(_ symbol: String) -> Task<Void> {
            pincode += symbol

            if let service = service, service.symbolsCount == pincode.count {
                return service.check(pincode: pincode)
                    .onSuccess { [weak self] _ in
                        self?.delegate?.loginSuccess()
                    }.onFail { [weak self, attempt] in
                        self?.attempt += 1
                        self?.delegate?.loginFailed($0, attempt: attempt + 1)
                        self?.view?.showPincodeInvalid { self?.pincode = "" }
                    }
            } else {
                return Task()
            }
        }

        fileprivate func executeDeleteSymbol() {
            pincode = String(pincode.prefix(pincode.count - 1))
        }

        fileprivate func canExecuteDeleteSymbol() -> Bool {
            guard let maxCount = service?.symbolsCount else {
                return false
            }

            return !pincode.isEmpty && pincode.count < maxCount
        }

        fileprivate func executeDeviceOwnerAuth() -> Task<Void> {
            guard let service = service else {
                return Task()
            }

            return service.checkDeviceOwnerAuth()
                .onSuccess { [weak self] _ in
                    self?.delegate?.loginSuccess()
                }.onFail { [weak self, attempt] in
                    self?.attempt += 1
                    self?.delegate?.loginFailed($0, attempt: attempt + 1)
                }.notify { [weak self] _ in
                    self?.pincode = ""
                }
        }

        fileprivate func canExecuteDeviceOwnerAuth() -> Bool {
            return service?.isDeviceOwnerAuthEnabled == true
        }
    }
}
