//
//  Created on 18/03/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation

public class JetPincodeStrings {

    public static var notRecognized: String = "<TODO> JetPincodeStrings.notRecognized"
    public static var notRecognizedTouchId: String? = nil
    public static var notRecognizedFaceId: String? = nil

    public static var touchIdReason: String = "<TODO> JetPincodeStrings.touchIdReason"
    public static var osPasscodeNotSet: String = "<TODO> JetPincodeStrings.osPasscodeNotSet"
    public static var invalidPincode: String = "<TODO> JetPincodeStrings.invalidPincode"

    public static var notRecognizedMessage: String {
        switch BiometricAuth.type {
        case .faceID:
            return JetPincodeStrings.notRecognizedFaceId ?? JetPincodeStrings.notRecognized
        case .touchID:
            return JetPincodeStrings.notRecognizedTouchId ?? JetPincodeStrings.notRecognized
        default:
            return JetPincodeStrings.notRecognized
        }
    }
}
