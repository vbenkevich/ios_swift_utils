//
//  Created by Vladimir Benkevich on 08/01/2019.
//  Copyright © Vladimir Benkevich 2019
//

import Foundation
import JetLib

extension PinpadWidget {

    public class PinpadViewModel {

        public init(symbolsCount: Int, deviceOwnerLock: DevideOwnerLock?) {
            self.symbolsCount = symbolsCount
            self.deviceOwnerLock = deviceOwnerLock
        }

        let symbolsCount: Int
        let deviceOwnerLock: DevideOwnerLock?

        lazy var deleteSymbolCommand = ActionCommand(self,
                                                     execute: { $0.executeDeleteSymbol() },
                                                     canExecute: { $0.canExecuteDeleteSymbol() })

        lazy var appendSymbolCommand = AsyncCommand(self,
                                                    task: { $0.executeAppendSymbol($1) })

        lazy var deviceOwnerAuthCommand = AsyncCommand(self,
                                                       task: { $0.executeDeviceOwnerAuth() },
                                                       canExecute: { $0.canExecuteDeviceOwnerAuth() })

        weak var view: PinpadWidget?

        public weak var delegate: UIPincodeProviderDelegate?

        var pincode: String = "" {
            didSet {
                deleteSymbolCommand.invalidate()
                deviceOwnerAuthCommand.invalidate()
                view?.pincodeView.pincode = pincode
            }
        }

        fileprivate func executeAppendSymbol(_ symbol: String) -> Task<Void> {
            pincode += symbol

            if symbolsCount == pincode.count && delegate?.validate(code: pincode) == false {
                view?.showPincodeInvalid { [weak self] in self?.pincode = "" }
            }

            return Task()
        }

        fileprivate func executeDeleteSymbol() {
            pincode = String(pincode.prefix(pincode.count - 1))
        }

        fileprivate func canExecuteDeleteSymbol() -> Bool {
            return !pincode.isEmpty && pincode.count < symbolsCount
        }

        fileprivate func executeDeviceOwnerAuth() -> Task<Void> {
            guard let lock = deviceOwnerLock else {
                return Task()
            }

            return lock.getCode().onSuccess { [delegate] in
                _ = delegate?.validate(code: $0)
                }.map { _ in return Void() }
        }

        fileprivate func canExecuteDeviceOwnerAuth() -> Bool {
            return deviceOwnerLock != nil
        }
    }
}
