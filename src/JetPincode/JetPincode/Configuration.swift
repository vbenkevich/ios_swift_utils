//
//  Created on 18/03/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation

open class Configuration {

    public init() {}

    public var symbolsCount: Int = 4

    public var pincodeAttempts: Int = 5

    public var pincodeLifetime: TimeInterval = TimeInterval(10 * 60)

    public var showBiometricAuthOnDidAppear = true

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
}

extension UserDefaults.Key {

    static let pincodeKey = UserDefaults.Key("JetUI.JetPincode.pincodeKey")
    static let pincodeStatusKey = UserDefaults.Key("JetUI.JetPincode.pincodeStatusKey")
    static let deviceOwnerStatusKey = UserDefaults.Key("JetUI.JetPincode.deviceOwnerStatusKey")
}
