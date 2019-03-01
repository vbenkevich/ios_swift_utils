//
//  Created on 09/01/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation

open class KeyChainStorage {

    public static let standard = KeyChainStorage(serviceName: "JetLib.KeyChainStorage")

    init(serviceName: String, accessGroup: String? = nil) {
        self.serviceName = serviceName
        self.accessGroup = accessGroup
    }

    public let serviceName: String
    public let accessGroup: String?

    public func value<T: Codable>(forKey key: UserDefaults.Key) -> T? {
        guard let data = readData(forKey: key.stringKey) else {
            return nil
        }

        return try? JSONDecoder().decode(T.self, from: data)
    }

    @discardableResult
    public func set<T: Codable>(value: T, forKey key: UserDefaults.Key) -> Bool {
        guard let data = try? JSONEncoder().encode(value) else {
            return false
        }

        return write(data: data, forKey: key.stringKey)
    }

    @discardableResult
    public func delete(key: UserDefaults.Key) -> Bool {
        let query = QueryBuilder(key: key.stringKey, serviceName: serviceName, accessGroup: accessGroup)
        let status = SecItemDelete(query.build())

        if status == errSecSuccess {
            return true
        } else {
            return false
        }
    }

    public func contains(key: UserDefaults.Key) -> Bool {
        return readData(forKey: key.stringKey) != nil
    }

    @discardableResult
    public func clearAll() ->  Bool {
        var query = QueryBuilder(key: nil, serviceName: serviceName, accessGroup: accessGroup)
        query.matchLimitOne = false

        let status: OSStatus = SecItemDelete(query.build())

        if status == errSecSuccess {
            return true
        } else {
            return false
        }
    }

    fileprivate func readData(forKey key: String) -> Data? {
        var query = QueryBuilder(key: key, serviceName: serviceName, accessGroup: accessGroup)
        query.returnData = true
        query.matchLimitOne = true

        var result: AnyObject?
        let status = SecItemCopyMatching(query.build(), &result)

        if status == noErr {
            return result as? Data
        } else {
            return nil
        }
    }

    fileprivate func write(data: Data, forKey key: String) -> Bool {
        var query = QueryBuilder(key: key, serviceName: serviceName, accessGroup: accessGroup)
        query.writeData = data

        let status = SecItemAdd(query.build() as CFDictionary, nil)

        if status == errSecDuplicateItem {
            return update(data: data, forKey: key)
        } else if status == errSecSuccess {
            return true
        } else {
            return false
        }
    }

    fileprivate func update(data: Data, forKey key: String) -> Bool {
        let query = QueryBuilder(key: key, serviceName: serviceName, accessGroup: accessGroup)

        let status = SecItemUpdate(query.build(), [kSecValueData: data] as CFDictionary)

        if status == errSecSuccess {
            return true
        } else {
            return false
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
