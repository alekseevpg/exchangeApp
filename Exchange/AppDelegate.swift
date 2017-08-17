//
//  AppDelegate.swift
//  Exchange
//
//  Created by Pavel Alekseev on 8/8/17.
//  Copyright (c) 2017 alekseevpg. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        let homeViewController = ExchangeViewController()
        window!.rootViewController = homeViewController
        window!.makeKeyAndVisible()
        return true
    }
}
