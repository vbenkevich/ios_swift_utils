//
//  Created on 09/01/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation

open class KeyChainStorage: SyncDataStorage {

    public static let standard = KeyChainStorage(serviceName: "JetLib.KeyChainStorage")

    public init(serviceName: String, accessGroup: String? = nil) {
        self.serviceName = serviceName
        self.accessGroup = accessGroup
    }

    public let serviceName: String
    public let accessGroup: String?

    public func value<T: Codable>(forKey key: UserDefaults.Key) throws -> T {
        guard let data = try readData(forKey: key.stringKey) else {
            throw KeyNotFoundException(key)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    public func set<T: Codable>(_ value: T, forKey key: UserDefaults.Key) throws {
        let data = try JSONEncoder().encode(value)
        try write(data: data, forKey: key.stringKey)
    }

    public func delete(key: UserDefaults.Key) throws {
        let query = QueryBuilder(key: key.stringKey, serviceName: serviceName, accessGroup: accessGroup)
        let status = SecItemDelete(query.build())

        guard status == errSecSuccess else {
            throw DataAssessError(status)
        }
    }

    @discardableResult
    public func contains(key: UserDefaults.Key) throws -> Bool {
        return try readData(forKey: key.stringKey) != nil
    }

    public func clearAll() throws {
        var query = QueryBuilder(key: nil, serviceName: serviceName, accessGroup: accessGroup)
        query.matchLimitOne = false

        let status: OSStatus = SecItemDelete(query.build())

        guard status == errSecSuccess else {
            throw DataAssessError(status)
        }
    }

    fileprivate func readData(forKey key: String) throws -> Data? {
        var query = QueryBuilder(key: key, serviceName: serviceName, accessGroup: accessGroup)
        query.returnData = true
        query.matchLimitOne = true

        var result: AnyObject?
        let status = SecItemCopyMatching(query.build(), &result)

        if status == noErr {
            return result as? Data
        } else {
            throw DataAssessError(status)
        }
    }

    fileprivate func write(data: Data, forKey key: String) throws {
        var query = QueryBuilder(key: key, serviceName: serviceName, accessGroup: accessGroup)
        query.writeData = data

        let status = SecItemAdd(query.build() as CFDictionary, nil)

        if status == errSecDuplicateItem {
            try update(data: data, forKey: key)
        }

        guard status == errSecSuccess else {
            throw DataAssessError(status)
        }
    }

    fileprivate func update(data: Data, forKey key: String) throws {
        let query = QueryBuilder(key: key, serviceName: serviceName, accessGroup: accessGroup)

        let status = SecItemUpdate(query.build(), [kSecValueData: data] as CFDictionary)

        guard status == errSecSuccess else {
            throw DataAssessError(status)
        }
    }

    public class DataAssessError: Exception {

        public let status: OSStatus

        public init(_ status: OSStatus) {
            self.status = status
            super.init("Operation failed. Status = (\(status))")
        }
    }

    struct QueryBuilder {

        init(key: String?, serviceName: String, accessGroup: String?) {
            self.key = key
            self.serviceName = serviceName
            self.accessGroup = accessGroup
        }

        let serviceName: String
        let accessGroup: String?
        let key: String?

        var returnData: Bool = false
        var matchLimitOne: Bool = true
        var writeData: Data?
        var protection = kSecAttrAccessibleAlwaysThisDeviceOnly

        func build() -> CFDictionary {
            var query = [CFString: Any]()
            query[kSecAttrService] = serviceName
            query[kSecClass] = kSecClassGenericPassword

            if let group = accessGroup {
                query[kSecAttrAccessGroup] = group
            }

            if let data = writeData {
                query[kSecValueData] = data
            }

            if let key = key {
                let encodedKey = key.data(using: String.Encoding.utf8)
                query[kSecAttrAccount] = encodedKey
                query[kSecAttrGeneric] = encodedKey
            }

            query[kSecAttrAccessible] = protection
            query[kSecMatchLimit] = matchLimitOne ? kSecMatchLimitOne : kSecMatchLimitAll
            query[kSecReturnData] = returnData ? kCFBooleanTrue : kCFBooleanFalse

            return query as CFDictionary
        }
    }
}
