//
//  Created on 06/02/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation
import LocalAuthentication
import JetLib

public extension PinpadFlow {

    public class DeviceOwnerAuth: JetUI.PinpadFlowDeviceOwnerAuthService {

        private let context = LAContext()

        public init() {
        }

        public var shouldUseDeviceOwnerAuth: Bool {
            get { return UserDefaults.standard.bool(forKey: UserDefaults.Key.shouldUseDeviceOwnerAuthKey) }
            set { UserDefaults.standard.set(newValue, forKey: UserDefaults.Key.shouldUseDeviceOwnerAuthKey) }
        }

        public var isDeviceOwnerAuthAvailable: Bool {
            var error: NSError?
            return context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error)
        }

        public var isTouchIdAvailable: Bool {
            if #available(iOS 11.0, *) {
                if context.biometryType == .touchID {
                    return true
                }
            } else {
                return isDeviceOwnerAuthAvailable
            }

            return false
        }

        public var isFaceIdAvailable: Bool {
            if #available(iOS 11.0, *) {
                if context.biometryType == .faceID {
                    return true
                }
            }

            return false
        }

        public func checkDeviceOwnerAuth() -> Task<Void> {
            let taskSource = Task<Void>.Source()

            context.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics,
                                   localizedReason: PinpadWidget.localization.touchIdReason) {
                                    if let error = $1 {
                                        try? taskSource.error(AuthFailedException(nil, error))
                                    } else if $0 {
                                        try? taskSource.complete()
                                    } else {
                                        try? taskSource.error(AuthFailedException.notRecognized)
                                    }
            }

            return taskSource.task
        }

        public class AuthFailedException: Exception {
            public static let notRecognized = AuthFailedException()
        }
    }

}

extension UserDefaults.Key {
    static let shouldUseDeviceOwnerAuthKey = UserDefaults.Key("JetUI.PinCodeWidget.DeviceOwnerAuthService.shouldUseDeviceOwnerAuth")
}
