//
//  Created on 04/03/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation
import LocalAuthentication

public protocol CodeValidator {

    func validate(code: String) -> Bool
}

public protocol CodeProvider {

    func getCode() -> Task<String>
}

public class CodeProtectedStorage: AsyncDataStorage {

    let codeLocker: CodeLocker
    private let dataStorage: AsyncDataStorage
    private let codeProvider: CodeProvider

    public init(origin: AsyncDataStorage, validator: CodeValidator, codeProvider: CodeProvider, configuration: JetPincodeConfiguration) {
        self.codeProvider = codeProvider
        self.codeLocker = CodeLocker(validator: validator, configuration: configuration)
        self.dataStorage = origin
    }

    @discardableResult
    public func value<T: Codable>(forKey defaultName: UserDefaults.Key) -> Task<T> {
        return codeLocker.tryUnlock(codeProvider: codeProvider).chainOnSuccess { [dataStorage] in
            dataStorage.value(forKey: defaultName)
        }
    }

    @discardableResult
    public func set<T: Codable>(_ value: T, forKey defaultName: UserDefaults.Key) -> Task<Void> {
        return dataStorage.set(value, forKey: defaultName)
    }

    @discardableResult
    public func delete(key defaultName: UserDefaults.Key) -> Task<Void> {
        return dataStorage.delete(key: defaultName)
    }

    public func invalidate() {
        codeLocker.invalidate()
    }

    public class InvalidCodeException: Exception {
    }

    class CodeLocker {

        let validator: CodeValidator
        let configuration: JetPincodeConfiguration

        var lastUnlockTime: Date = Date()
        var unlockTask: Task<Void>?

        init(validator: CodeValidator, configuration: JetPincodeConfiguration) {
            self.validator = validator
            self.configuration = configuration
        }

        public func unlock() {
            lastUnlockTime = Date()
            unlockTask = Task()
        }

        public func tryUnlock(codeProvider: CodeProvider) -> Task<Void> {
            if (lastUnlockTime + configuration.pincodeLifetime) < Date() {
                unlockTask = nil
            }

            if let task = unlockTask {
                return task
            }

            let task = codeProvider.getCode().map { [validator] in
                guard validator.validate(code: $0) else {
                    throw InvalidCodeException(JetPincodeStrings.invalidPincode)
                }
            }

            lastUnlockTime = Date()
            unlockTask = task

            return task
        }

        public func invalidate() {
            unlockTask = nil
        }
    }
}

public class PincodeStorage: CodeValidator {

    let storage: KeyChainStorage

    public init(storage: KeyChainStorage) {
        self.storage = storage
    }

    public func validate(code: String) -> Bool {
        do {
            let stored: String = try storage.value(forKey: UserDefaults.Key.pincodeKey)
            return code == stored
        } catch {
            return false
        }
    }

    public func setPincode(code: String) throws {
        try storage.set(code, forKey: UserDefaults.Key.pincodeKey)
    }

    public func deletePincode() throws {
        try storage.delete(key: UserDefaults.Key.pincodeKey)
    }
}

