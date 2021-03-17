//
//  AppDelegate.swift
//  PangleAd
//
//  Created by my on 2021/3/15.
//

import UIKit
import GeSwift

let kAppId = "5020801";

let kSplashId = "820801504";
// let kSplashExpressId = '887366172';

let kRewardedVideoId = "920801724";
let kRewardedVideoExpressId = "945404052";

let kBannerId = "920801711";
let kBannerExpressId = "945399224";

let kFeedId = "920801899";
let kFeedVideoExpressId = "945399537";
let kFeedTestExpressId = "945478448";

let kInterstitialExpressId = "945388068";

let kFullscreenVideoExpressId = "945428786";

let kNativeBannerId = "920801177";
let kNativeInterstitialId = "920801184";

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        customNavigationBarAppearance()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UINavigationController(rootViewController: CategoryListController())
        window?.makeKeyAndVisible()
        
        return true
    }
    
    func customNavigationBarAppearance() {
        
        let navigationBar = UINavigationBar.appearance()
        
        navigationBar.tintColor = UIColor.ge.color(with: "333333")
        if #available(iOS 13.0, *) {
            let appearence = UINavigationBarAppearance()
            appearence.titleTextAttributes = [.font: UIFont.systemFont(ofSize: 16, weight: .medium)]
            appearence.buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.ge.color(with: "333333"), .font: UIFont.systemFont(ofSize: 13, weight: .regular)]

            appearence.backgroundColor = UIColor.white
            appearence.shadowImage = nil
            appearence.shadowColor = UIColor.clear

            navigationBar.standardAppearance = appearence
        } else {
            // Fallback on earlier versions
            navigationBar.titleTextAttributes = [.foregroundColor: UIColor.ge.color(with: "333333"), .font: UIFont.systemFont(ofSize: 16, weight: .medium)]
            navigationBar.shadowImage = UIImage()
            navigationBar.barTintColor = UIColor.white
            navigationBar.backgroundColor = UIColor.white
        }
    }
}

