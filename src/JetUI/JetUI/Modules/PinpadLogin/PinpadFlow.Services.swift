//
//  Created by Vladimir Benkevich on 07/01/2019.
//  Copyright © Vladimir Benkevich 2019
//

import Foundation
import JetLib

public protocol PinpadFlowWidgetService {

    var symbolsCount: UInt8 { get set }

    var isDeviceOwnerAuthEnabled: Bool { get }
    var isTouchIdAvailable: Bool { get }
    var isFaceIdAvailable: Bool { get }

    func check(pincode: String) -> Task<Void>
    func checkDeviceOwnerAuth() -> Task<Void>
}

public protocol PinpadFlowDeviceOwnerAuthService {

    var shouldUseDeviceOwnerAuth: Bool { get set }
    var isDeviceOwnerAuthAvailable: Bool { get }
    var isTouchIdAvailable: Bool { get }
    var isFaceIdAvailable: Bool { get }

    func checkDeviceOwnerAuth() -> Task<Void>
}

public protocol PinpadFlowPicodeStorageService {

    func validate(pincode: String) -> Task<Void>
    func setNew(pincode: String) -> Task<Void>
    func clear() -> Task<Void>
}

public extension PinpadFlow {

    public class WidgetService: JetUI.PinpadFlowWidgetService {

        private let pincodeStorage: JetUI.PinpadFlowPicodeStorageService
        private let authService: JetUI.PinpadFlowDeviceOwnerAuthService

        public init(pincodeService: JetUI.PinpadFlowPicodeStorageService,
                    authService: JetUI.PinpadFlowDeviceOwnerAuthService) {
            self.pincodeStorage = pincodeService
            self.authService = authService
        }

        public var symbolsCount: UInt8 = 4

        public var isDeviceOwnerAuthEnabled: Bool {
            return authService.isDeviceOwnerAuthAvailable && authService.shouldUseDeviceOwnerAuth
        }

        public var isTouchIdAvailable: Bool {
            return authService.isFaceIdAvailable
        }

        public var isFaceIdAvailable: Bool {
            return authService.isTouchIdAvailable
        }

        public func check(pincode: String) -> Task<Void> {
            return pincodeStorage.validate(pincode: pincode)
        }

        public func checkDeviceOwnerAuth() -> Task<Void> {
            return authService.checkDeviceOwnerAuth()
        }
    }
}
