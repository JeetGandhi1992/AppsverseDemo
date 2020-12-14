//
//  AppDelegate.swift
//  AppsverseDemo
//
//  Created by jeet_gandhi on 6/12/20.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        let navigationController = UINavigationController(rootViewController: MainCoordinator.shared.mainRootController)
        window!.rootViewController = navigationController
        window!.makeKeyAndVisible()
        return true
    }

}

