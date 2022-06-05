//
//  AppDelegate.swift
//  notipush
//
//  Created by 三原一道 on 2022/05/16.
//

import UIKit
import GoogleMobileAds
import AppTrackingTransparency
import AdSupport
import SwiftyStoreKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate,UNUserNotificationCenterDelegate {
    var myViewController: ViewController!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.delegate = self
        
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        if #available(iOS 14, *) {
                    switch ATTrackingManager.trackingAuthorizationStatus {
                    case .authorized:
                        print("Allow Tracking")
                        print("IDFA: \(ASIdentifierManager.shared().advertisingIdentifier)")
                    case .denied:
                        print("😭拒否")
                    case .restricted:
                        print("🥺制限")
                    case .notDetermined:
                        showRequestTrackingAuthorizationAlert()
                    @unknown default:
                        fatalError()
                    }
                } else {// iOS14未満
                    if ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
                        print("Allow Tracking")
                        print("IDFA: \(ASIdentifierManager.shared().advertisingIdentifier)")
                    } else {
                        print("🥺制限")
                    }
                }
        initSwiftyStorekit()
        return true
    }

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // フォアグラウンドで通知を受け取った際に呼ばれるメソッド
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler(
            [
                //UNNotificationPresentationOptions.banner,
                UNNotificationPresentationOptions.list,
                UNNotificationPresentationOptions.sound,
                UNNotificationPresentationOptions.badge
            ]
        )
    }
    
    // バックグランドで通知を受け取った際に呼ばれるメソッド
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
        myViewController.removeCurrentNotifications()
        myViewController.notify(nil)
        myViewController.notifyPersistent()
    }
    
    func initSwiftyStorekit() {
           SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
               for purchase in purchases {
                   switch purchase.transaction.transactionState {
                   case .purchased, .restored:
                       if purchase.needsFinishTransaction {
                           SwiftyStoreKit.finishTransaction(purchase.transaction)
                       }
                   // Unlock content
                   case .failed, .purchasing, .deferred:
                       break // do nothing
                   @unknown default:
                       fatalError()
                   }
               }
           }
       }
    
    ///Alert表示
    private func showRequestTrackingAuthorizationAlert() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in
                switch status {
                case .authorized:
                    print("🎉")
                    //IDFA取得
                    print("IDFA: \(ASIdentifierManager.shared().advertisingIdentifier)")
                case .denied, .restricted, .notDetermined:
                    print("😭")
                @unknown default:
                    fatalError()
                }
            }
            )}
            
        })
    }
    
    func applicationSignificantTimeChange(_ application: UIApplication){
        NotificationCenter.default.post(name: .dayChanged, object: nil)
    }
}
