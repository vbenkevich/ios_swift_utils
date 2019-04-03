//
//  Created on 04/03/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation

public class KeyNotFoundException: Exception {

    public init(_ key: UserDefaults.Key) {
        super.init("Key not found (\(key.stringKey)).")
    }
}

public protocol SyncDataStorage {

    func value<T: Codable>(forKey defaultName: UserDefaults.Key) throws -> T

    func set<T: Codable>(_ value: T, forKey defaultName: UserDefaults.Key) throws

    func delete(key defaultName: UserDefaults.Key) throws
}

public protocol AsyncDataStorage {

    func value<T: Codable>(forKey defaultName: UserDefaults.Key) -> Task<T>

    func set<T: Codable>(_ value: T, forKey defaultName: UserDefaults.Key) -> Task<Void>

    func delete(key defaultName: UserDefaults.Key) -> Task<Void>
}

public extension SyncDataStorage {

    /// creates new async wrapper
    func async() -> AsyncDataStorage {
        return AsyncDataStorageAdapter(sync: self)
    }
}

public class AsyncDataStorageAdapter: AsyncDataStorage {

    private let queue: DispatchQueue
    private let sync: SyncDataStorage

    public init(sync: SyncDataStorage,
                queue: DispatchQueue = DispatchQueue(label: "AsyncDataStorageAdapter.SyncQueue", qos: .userInitiated)) {
        self.sync = sync
        self.queue = queue
    }

    public func value<T: Codable>(forKey defaultName: UserDefaults.Key) -> Task<T> {
        return queue.async(Task(execute: { [sync] in
            if let value: T = try sync.value(forKey: defaultName) {
                return value
            } else {
                throw KeyNotFoundException(defaultName)
            }
        }))
    }

    public func set<T: Codable>(_ value: T, forKey defaultName: UserDefaults.Key) -> Task<Void> {
        return queue.async(Task(execute: { [sync] in
            try sync.set(value, forKey: defaultName)
        }))
    }

    public func delete(key defaultName: UserDefaults.Key) -> Task<Void> {
        return queue.async(Task(execute: { [sync] in
            try sync.delete(key: defaultName)
        }))
    }
}
