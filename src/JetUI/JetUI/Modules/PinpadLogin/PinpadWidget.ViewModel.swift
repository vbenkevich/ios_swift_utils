//
//  Created by Vladimir Benkevich on 08/01/2019.
//  Copyright © Vladimir Benkevich 2019
//

import Foundation
import JetLib

extension PinpadWidget {

    class ViewModel {

        private var attempt: Int = 0

        lazy var deleteCommand = ActionCommand(self, execute: { $0.delete() }, canExecute: { $0.canDelete() })

        lazy var appendCommand = AsyncCommand(self, task: { $0.append($1) })

        lazy var biometricCommand = AsyncCommand(self, task: { $0.biometric() }, canExecute: { $0.canBiometric() })

        weak var view: PinpadWidget?

        weak var delegate: PinpadFlowDelegate?

        var service: PinpadWidgetService? {
            didSet {
                view?.pincodeView.setup(symbolsCount: service?.symbolsCount)
                view?.setupDeviceOwnerAuthButton()
            }
        }

        var pincode: String = "" {
            didSet {
                deleteCommand.invalidate()
                biometricCommand.invalidate()
                view?.pincodeView.pincode = pincode
            }
        }

        fileprivate func append(_ symbol: String) -> Task<Void> {
            pincode += symbol

            if let service = service, service.symbolsCount == pincode.count {
                return service.check(pincode: pincode)
                    .onSuccess { [weak self] _ in
                        self?.delegate?.loginSuccess()
                    }.onFail { [weak self, attempt] in
                        self?.attempt += 1
                        self?.delegate?.loginFailed($0, attempt: attempt + 1)
                    }.notify { [weak self] _ in
                        self?.pincode = ""
                    }
            } else {
                return Task()
            }
        }

        fileprivate func delete() {
            pincode = String(pincode.prefix(pincode.count - 1))
        }

        fileprivate func canDelete() -> Bool {
            guard let maxCount = service?.symbolsCount else {
                return false
            }

            return !pincode.isEmpty && pincode.count < maxCount
        }

        fileprivate func biometric() -> Task<Void> {
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

        fileprivate func canBiometric() -> Bool {
            return service?.isDeviceOwnerAuthEnabled == true
        }
    }
}
