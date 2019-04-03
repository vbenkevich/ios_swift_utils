//
//  Created on 05/03/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation
import LocalAuthentication

public class BiometricAuth {

    public enum AuthType {
        case faceID
        case touchID
        case unknown
        case none
    }

    private let storage: KeyChainStorage
    private let context = LAContext()

    public init(storage: KeyChainStorage) {
        self.storage = storage
    }

    public static var type: AuthType {
        var error: NSError?

        let context = LAContext()
        let evaluteRes = context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error)

        if #available(iOS 11.0, *) {
            switch context.biometryType {
            case .LABiometryNone:   return .none
            case .faceID:           return .faceID
            case .touchID:          return .touchID
            default:                return .unknown
            }
        }

        return evaluteRes ? .touchID : .none
    }

    public func getCode() -> Task<String> {
        return checkAuth().map { [storage] in
            return try storage.value(forKey: UserDefaults.Key.pincodeKey)
        }
    }

    public func checkAuth() -> Task<Void> {
        let taskSource = Task<Void>.Source()

        context.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics,
                               localizedReason: JetPincodeStrings.touchIdReason)
        {
            if let error = $1 {
                if error.isCancel {
                    try? taskSource.cancel()
                } else {
                    try? taskSource.error(BiometricAuth.tryParseError(error))
                }
            } else if $0 {
                try? taskSource.complete()
            } else {
                try? taskSource.error(Exception(JetPincodeStrings.notRecognized))
            }
        }

        return taskSource.task
    }

    private static func tryParseError(_ error: Error) -> Exception {
        guard let laError = error as? LAError else {
            return Exception(nil, error)
        }

        switch laError.code {
        case .authenticationFailed:
            return Exception(JetPincodeStrings.notRecognizedMessage)
        case .passcodeNotSet:
            return Exception(JetPincodeStrings.osPasscodeNotSet)
        default:
            return Exception(laError.localizedDescription, error)
        }
    }
}

fileprivate extension Error {

    var isCancel: Bool {
        guard let laError = self as? LAError else {
            return false
        }

        switch laError.code {
        case .userCancel, .systemCancel, .appCancel, .userFallback:
            return true
        default:
            return false
        }
    }
}
