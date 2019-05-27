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

        guard let value = try JSONDecoder().decode([T].self, from: data).first else { // workaround for plain strings
            throw KeyNotFoundException(key)
        }

        return value
    }

    public func set<T: Codable>(_ value: T, forKey key: UserDefaults.Key) throws {
        let data = try JSONEncoder().encode([value]) // workaround for plain strings
        try write(data: data, forKey: key.stringKey)
    }

    public func delete(key: UserDefaults.Key) throws {
        try delete(key: key.stringKey)
    }

    @discardableResult
    public func contains(key: UserDefaults.Key) throws -> Bool {
        return try readData(forKey: key.stringKey) != nil
    }

    public func clearAll() throws {
        let spec: NSDictionary = [kSecClass: kSecClassGenericPassword]
        let status = SecItemDelete(spec)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw DataAssessError(status)
        }
    }

    fileprivate func readData(forKey key: String) throws -> Data? {
        let query = QueryBuilder(serviceName: serviceName).accessGroup(accessGroup).one().get().key(key).build()

        var result: AnyObject?

        let status = SecItemCopyMatching(query, &result)

        if status == noErr {
            return result as? Data
        } else if status == errSecItemNotFound {
            return nil
        } else {
            throw DataAssessError(status)
        }
    }

    fileprivate func write(data: Data, forKey key: String) throws {
        let query = QueryBuilder(serviceName: serviceName).accessGroup(accessGroup).set(data).key(key).build()

        var status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecDuplicateItem {
            try delete(key: key)
            status = SecItemAdd(query as CFDictionary, nil)
        }

        guard status == errSecSuccess else {
            throw DataAssessError(status)
        }
    }

    fileprivate func delete(key: String) throws {
        let query = QueryBuilder(serviceName: serviceName).accessGroup(accessGroup).key(key).build()

        let status = SecItemDelete(query)

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

    class QueryBuilder {

        fileprivate var query: [String : Any]

        init(serviceName: String) {
            query = [kSecClass as String : kSecClassGenericPassword as String,
                     kSecAttrService as String : serviceName]
        }

        func accessGroup(_ accessGroup: String?) -> QueryBuilder {
            if let group = accessGroup {
                query[kSecAttrAccessGroup as String] = group
            }
            return self
        }

        func key(_ key: String) -> QueryBuilder {
            query[kSecAttrAccount as String] = key
            return self
        }

        func set(_ data: Data) -> QueryBuilder {
            query[kSecValueData as String] = data
            return self
        }

        func get() -> QueryBuilder {
            query[kSecReturnData as String] = kCFBooleanTrue
            return self
        }

        func one() -> QueryBuilder {
            query[kSecMatchLimit as String] = kSecMatchLimitOne
            return self
        }

        func all() -> QueryBuilder {
            query[kSecMatchLimit as String] = kSecMatchLimitAll
            return self
        }

        func build() -> CFDictionary {
            return query as CFDictionary
        }
    }
}
