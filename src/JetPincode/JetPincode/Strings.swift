//
//  Created on 18/03/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation

public class Strings {

    public static var notRecognized: String = "<TODO> JetUI.PincodeConfiguration.Strings.notRecognized"
    public static var notRecognizedTouchId: String? = nil
    public static var notRecognizedFaceId: String? = nil

    public static var touchIdReason: String = "<TODO> JetUI.PincodeConfiguration.Strings.touchIdReason"
    public static var osPasscodeNotSet: String = "<TODO> JetUI.PincodeConfiguration.Strings.osPasscodeNotSet"
    public static var invalidPincode: String = "<TODO> JetUI.PincodeConfiguration.Strings.invalidPincode"

    public static var notRecognizedMessage: String {
        switch BiometricAuth.type {
        case .faceID:
            return Strings.notRecognizedFaceId ?? Strings.notRecognized
        case .touchID:
            return Strings.notRecognizedTouchId ?? Strings.notRecognized
        default:
            return Strings.notRecognized
        }
    }
}
