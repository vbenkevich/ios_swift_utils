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
        pinpad.service = PinpadWidget.Service(pincodeService: PinpadWidget.PincodeStorage(),
                                                          authService: PinpadWidget.DeviceOwnerAuth())
    }
}
