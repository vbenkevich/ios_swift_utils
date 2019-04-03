//
//  Created on 05/03/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation
import JetLib

class AuthService {

    private static var loginKey = UserDefaults.Key("storage.key.login")
    private static var passwordKey = UserDefaults.Key("storage.key.password")

    private let pincode: JetPincode

    init(pincode: JetPincode) {
        self.pincode = pincode
    }

    func login(login: String, password: String) -> Task<Void> {
        return Task().delay(1000).onSuccess { [pincode] in
            pincode.set(login, forKey: AuthService.loginKey)
            pincode.set(password, forKey: AuthService.passwordKey)
        }
    }

    func logout() {
        pincode.configuration.deviceOwnerStatus = nil
        pincode.configuration.pincodeStatus = nil

        pincode.delete(key: AuthService.loginKey)
        pincode.delete(key: AuthService.passwordKey)
    }

    func silentLogin() -> Task<Void> {
        guard pincode.configuration.pincodeStatus == .use else {
            return Task.cancelled()
        }

        class LoginData {
            var login: String?
            var password: String?
        }

        let loginData = LoginData()

        return pincode.dataStorage.value(forKey: AuthService.loginKey)
            .map { loginData.login = $0 }
            .chainOnSuccess { [pincode] in pincode.dataStorage.value(forKey: AuthService.passwordKey) }
            .map { loginData.password = $0 }
            .chainOnSuccess { self.login(login: loginData.login!, password: loginData.password!) }
            .onFail { [pincode] (_) in pincode.configuration.pincodeStatus = nil }
    }
}
