//
//  AppDelegate.swift
//
//  Created by Vladimir Benkevich on 27/07/2018.
//  Copyright © 2018
//

import UIKit
import JetLib
import JetUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        UIViewController.swizzleViewAppearances()

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        PinpadFlow.shared.applicationDidBecomeActive()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        PinpadFlow.shared.applicationDidEnterBackground()
    }
}

