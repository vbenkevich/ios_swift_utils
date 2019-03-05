//
//  Created on 05/03/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation
import JetLib

extension UserDefaults.Key {

    static let pincodeKey = UserDefaults.Key("JetUI.JetPincode.pincodeKey")
    static let pincodeStatusKey = UserDefaults.Key("JetUI.JetPincode.pincodeStatusKey")
    static let deviceOwnerStatusKey = UserDefaults.Key("JetUI.JetPincode.deviceOwnerStatusKey")
}

open class JetPincode {

    public static var shared: JetPincode = JetPincode(configuration: JetPincodeConfiguration(),
                                                      viewFactory: PinpadWidget.DefaultFactory())

    public init(configuration: JetPincodeConfiguration, viewFactory: PinpadViewControllerFactory) {
        let keyChainStorage = KeyChainStorage(serviceName: "JetUI.JetPincode")
        pincodeStorage = PincodeStorage(storage: keyChainStorage)

        let uiCodeProvider = PincodeUIPresenter(pincodeStorage: pincodeStorage, viewFactory: viewFactory)

        self.configuration = configuration
        self.dataStorage = CodeProtectedStorage(origin: keyChainStorage.async(),
                                                validator: pincodeStorage,
                                                codeProvider: uiCodeProvider,
                                                lifetime: configuration.pincodeLifetime)
    }

    private let pincodeStorage: PincodeStorage

    public let dataStorage: CodeProtectedStorage

    public let configuration: JetPincodeConfiguration

    public func setPincode(code: String) throws {
        try pincodeStorage.setPincode(code: code)
    }

    public func deletePincode() throws {
        try pincodeStorage.deletePincode()
    }
}

public extension JetPincode {

    @discardableResult
    func value<T: Codable>(forKey defaultName: UserDefaults.Key) -> Task<T> {
        return dataStorage.value(forKey: defaultName)
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
        dataStorage.invalidate()
    }
}

open class JetPincodeConfiguration {

    public var symbolsCount: Int = 4

    public var pincodeAttempts: Int = 5

    public let pincodeLifetime: TimeInterval = TimeInterval(60 * 60)

    public var pincodeStatus: PincodeStatus? {
        get { return UserDefaults.standard.value(forKey: UserDefaults.Key.pincodeStatusKey) }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaults.Key.pincodeStatusKey) }
    }

    public var deviceOwnerStatus: DeviceOwnerAuthStatus? {
        get { return UserDefaults.standard.value(forKey: UserDefaults.Key.deviceOwnerStatusKey) }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaults.Key.deviceOwnerStatusKey) }
    }

    public enum PincodeStatus: String, Codable {
        case dontUse
        case use
    }

    public enum DeviceOwnerAuthStatus: String, Codable {
        case dontUse
        case use
    }

    public class Strings {
        public static var touchIdReason: String = "<TODO> JetUI.PincodeConfiguration.Strings.touchIdReason"
        public static var notRecognized: String = "<TODO> JetUI.PincodeConfiguration.Strings.notRecognized"
    }
}