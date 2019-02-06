//
//  Created on 06/02/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation
import JetLib

public extension PinpadFlow {

    public class PincodeStorage: JetUI.PicodeStorageService {

        public static var name = "JetUI.PinCodeWidget"

        private static let syncQueue = DispatchQueue(label: "JetUI.PinCodeWidget.syncQueue", qos: .userInteractive)

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
                PinpadFlow.isPincodeInited = true
            }
        }

        public func clear() -> Task<Void> {
            return PincodeStorage.syncQueue.execute {
                PinpadFlow.isPincodeInited = false
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
            query[kSecAttrService as String] = PinpadFlow.PincodeStorage.name as AnyObject

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
