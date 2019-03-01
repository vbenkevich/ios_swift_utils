//
//  Created on 06/02/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation
import JetLib

open class PinpadFlow {

    public class PinpadFlowException: Exception {
        public static let keyNotFoundException: PinpadFlowException = PinpadFlowException("Key not found")
        public static let pincodeDoesntSetException: PinpadFlowException = PinpadFlowException("Pincode hasn't been set")
    }

    public static var shared: PinpadFlow = PinpadFlow()

    public var maxInactivityTime: TimeInterval = TimeInterval(15 * 60) // 15 min
    public var incorrectPinAttempts: Int = 5
    public var viewFactory: PinpadFlowViewControllerFactory = PinpadDefaultViewControllerFactory()

    public static var isPincodeInited: Bool {
        get { return UserDefaults.standard.bool(forKey: UserDefaults.Key.isPincodeInited) }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaults.Key.isPincodeInited) }
    }

    public static var dontUsePincode: Bool {
        get { return UserDefaults.standard.bool(forKey: UserDefaults.Key.dontUsePincode) }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaults.Key.dontUsePincode) }
    }

    private var storage = DataStorage() //TODO use encrypted
    private var lastBackgroudTime = Date()

    private var _storageLocker: StorageLocker?
    private var storageLocker: StorageLocker {
        get {
            _storageLocker = _storageLocker ?? StorageLocker(maxAttemps: incorrectPinAttempts, viewFactory: viewFactory)
            return _storageLocker!
        }
        set {
            _storageLocker = newValue
        }
    }

    open func applicationDidBecomeActive() {
        guard lastBackgroudTime.addingTimeInterval(maxInactivityTime) < Date(), !storageLocker.inProgress else {
            return
        }

        storageLocker = StorageLocker(maxAttemps: incorrectPinAttempts, viewFactory: viewFactory)
    }

    open func applicationDidEnterBackground() {
        lastBackgroudTime = Date()
    }

    open func set<T: Codable>(_ data: T, forKey key: UserDefaults.Key) throws -> Task<Void> {
        guard PinpadFlow.isPincodeInited, !PinpadFlow.dontUsePincode else {
            throw PinpadFlowException.pincodeDoesntSetException
        }

        return storageLocker.unlock().map {
            try self.storage.set(data, forKey: key)
        }
    }

    open func data<T: Codable>(forKey key: UserDefaults.Key) throws -> Task<T> {
        guard PinpadFlow.isPincodeInited, !PinpadFlow.dontUsePincode else {
            throw PinpadFlowException.pincodeDoesntSetException
        }

        return storageLocker.unlock().map {
            try self.storage.data(forKey: key)
        }
    }

    //TODO use encrypted storage
    private class DataStorage {

        func set<T: Codable>(_ data: T, forKey key: UserDefaults.Key) throws {
            UserDefaults.standard.set(data, forKey: key)
        }

        func data<T: Codable>(forKey key: UserDefaults.Key) throws -> T {
            guard let data: T = UserDefaults.standard.value(forKey: key) else {
                throw PinpadFlowException.keyNotFoundException
            }

            return data
        }
    }
}

extension UserDefaults.Key {
    static let isPincodeInited = UserDefaults.Key("JetUI.PinpadFlow.isPincodeInited")
    static let dontUsePincode = UserDefaults.Key("JetUI.PinpadFlow.dontUsePincode")
}
