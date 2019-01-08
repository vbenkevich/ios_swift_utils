//
//  Created by Vladimir Benkevich on 07/01/2019.
//  Copyright © Vladimir Benkevich 2019
//

import Foundation
import JetLib
import LocalAuthentication

public protocol PinpadWidgetService {

    var symbolsCount: UInt8 { get set }

    var isDeviceOwnerAuthEnabled: Bool { get }
    var isTouchIdAvailable: Bool { get }
    var isFaceIdAvailable: Bool { get }

    func check(pincode: String) -> Task<Void>
    func checkDeviceOwnerAuth() -> Task<Void>
}

public protocol PicodeStorageService {

    var isPincodeInited: Bool { get }

    func validate(pincode: String) -> Task<Void>
    func setNew(pincode: String) -> Task<Void>
    func clear() -> Task<Void>
}

public protocol DeviceOwnerAuthService {

    var shouldUseDeviceOwnerAuth: Bool { get set }
    var isDeviceOwnerAuthAvailable: Bool { get }
    var isTouchIdAvailable: Bool { get }
    var isFaceIdAvailable: Bool { get }

    func checkDeviceOwnerAuth() -> Task<Void>
}

public extension PinpadWidget {

    public class Service: JetUI.PinpadWidgetService {

        private let pincodeService: JetUI.PicodeStorageService
        private let authService: JetUI.DeviceOwnerAuthService

        public init(pincodeService: JetUI.PicodeStorageService, authService: JetUI.DeviceOwnerAuthService) {
            self.pincodeService = pincodeService
            self.authService = authService
        }

        public weak var delegate: PinpadFlowDelegate?

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
            return pincodeService.validate(pincode: pincode)
        }

        public func checkDeviceOwnerAuth() -> Task<Void> {
            return authService.checkDeviceOwnerAuth()
        }
    }

    public class DeviceOwnerAuth: JetUI.DeviceOwnerAuthService {

        private let context = LAContext()

        public init() {
        }

        private let shouldUseDeviceOwnerAuthKey = "JetUI.PinCodeWidget.DeviceOwnerAuthService.shouldUseDeviceOwnerAuth" //todo
        public var shouldUseDeviceOwnerAuth: Bool {
            get { return UserDefaults.standard.bool(forKey: shouldUseDeviceOwnerAuthKey) } // todo
            set { UserDefaults.standard.set(newValue, forKey: shouldUseDeviceOwnerAuthKey) } // todo
        }

        public var isDeviceOwnerAuthAvailable: Bool {
            var error: NSError?
            return context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error)
        }

        public var isTouchIdAvailable: Bool {
            if #available(iOS 11.0, *) {
                if context.biometryType == .touchID {
                    return true
                }
            } else {
                return isDeviceOwnerAuthAvailable
            }

            return false
        }

        public var isFaceIdAvailable: Bool {
            if #available(iOS 11.0, *) {
                if context.biometryType == .faceID {
                    return true
                }
            }

            return false
        }

        public func checkDeviceOwnerAuth() -> Task<Void> {
            let taskSource = Task<Void>.Source()

            context.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics,
                                   localizedReason: PinpadWidget.localization.touchIdReason) {
                if let error = $1 {
                    try? taskSource.error(AuthFailedException(nil, error))
                } else if $0 {
                    try? taskSource.complete()
                } else {
                    try? taskSource.error(AuthFailedException.notRecognized)
                }
            }

            return taskSource.task
        }

        public class AuthFailedException: Exception {
            public static let notRecognized = AuthFailedException()
        }
    }

    public class PincodeStorage: JetUI.PicodeStorageService {

        public static var name = "JetUI.PinCodeWidget"

        private let isPincodeInitedKey = "JetUI.PinCodeWidget.PincodeService.isPincodeInited" // todo
        public var isPincodeInited: Bool {
            get { return UserDefaults.standard.bool(forKey: isPincodeInitedKey) } // todo
            set { UserDefaults.standard.set(newValue, forKey: isPincodeInitedKey) } // todo
        }

        private static let syncQueue = DispatchQueue(label: "JetUI.PinCodeWidget.synqQueue", qos: .userInteractive)

        public init() {
        }

        public func validate(pincode: String) -> Task<Void> {
            return PincodeStorage.syncQueue.execute {
                try self.validatePincode(pincode: pincode)
            }
        }

        public func setNew(pincode: String) -> Task<Void> {
            return PincodeStorage.syncQueue.execute {
                if (try? self.readPincodeImpl()) != nil {
                    try self.removePinImpl()
                }

                try self.setPincodeImpl(pincode)
                self.isPincodeInited = true
            }
        }

        public func clear() -> Task<Void> {
            return PincodeStorage.syncQueue.execute {
                self.isPincodeInited = false
                try self.removePinImpl()
            }
        }

        fileprivate func validatePincode(pincode: String) throws {
            guard try readPincodeImpl() == pincode else {
                throw Exception(PinpadWidget.localization.incorrectPincode)
            }
        }

        fileprivate func newPincodeQuery() -> [String: AnyObject] {
            var query = [String: AnyObject]()
            query[kSecAttrAccessGroup as String] = nil
            query[kSecClass as String] = kSecClassGenericPassword
            query[kSecAttrService as String] = PinpadWidget.PincodeStorage.name as AnyObject

            return query
        }

        fileprivate func setPincodeImpl(_ pincode: String) throws {
            var query = newPincodeQuery()
            query[kSecValueData as String] = pincode.data(using: .utf8) as AnyObject?

            let status = SecItemAdd(query as CFDictionary, nil)
            if status != noErr {
                throw KeychainException(status: status)
            }
        }

        fileprivate func removePinImpl() throws {
            let query = newPincodeQuery()
            let status = SecItemDelete(query as CFDictionary)

            guard status == noErr || status == errSecItemNotFound else {
                throw KeychainException(status: status)
            }
        }

        fileprivate func readPincodeImpl() throws -> String? {
            var result: AnyObject?

            var query = newPincodeQuery()
            query[kSecReturnData as String] = kCFBooleanTrue
            query[kSecReturnAttributes as String] = kCFBooleanTrue
            query[kSecMatchLimit as String] = kSecMatchLimitOne

            let status = withUnsafeMutablePointer(to: &result) {
                SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
            }

            guard status == noErr || status == errSecItemNotFound else {
                throw KeychainException(status: status)
            }

            guard let item = result as? [String : AnyObject],
                let data = item[kSecValueData as String] as? Data,
                let pincode = String(data: data, encoding: .utf8) else {
                    throw KeychainException.dataCorrupted
            }

            return pincode
        }

        public class KeychainException: Exception {

            public convenience init(status: OSStatus) {
                self.init("Keychain error (status: \(status)")
            }

            static let dataCorrupted = KeychainException("Keychain data corrupted")
        }
    }
}
