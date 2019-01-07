//
//  PinpadController.swift
//  JetLibSamples
//
//  Created by Vladimir Benkevich on 07/01/2019.
//  Copyright © 2019 Vladimir Benkevich. All rights reserved.
//

import Foundation
import UIKit
import JetLib
import JetUI

class PinpadController: UIViewController {

    @IBOutlet weak var pinpad: PinpadWidget!

    override func viewDidLoad() {
        super.viewDidLoad()
        pinpad.delegate = self
    }
}

extension PinpadController: PinpadDelegate {

    var symbolsCount: UInt8 { return 6 }

    var isTouchIdEnabled: Bool { return false }

    var isFaceIdEnabled: Bool { return false }

    func check(pincode: String) -> Task<Bool> {
        return Task(true)
    }

    func checkFaceId() -> Task<Bool> {
        return Task(true)
    }

    func checkTouchId() -> Task<Bool> {
        return Task(true)
    }
}
