//
//  AppDelegate.swift
//  Telemed
//
//  Created by Erik Grosskurth on 4/24/17.
//  Copyright © 2017 Caduceus USA. All rights reserved.
//

import UIKit
import UserNotifications
import Firebase
import FirebaseInstanceID
import FirebaseMessaging
import SystemConfiguration
import MobileCoreServices
import Quickblox
import QuickbloxWebRTC

let kQBApplicationID:UInt = 5
let kQBAuthKey = "ucYFVeFnKyxSNgj"
let kQBAuthSecret = "qXtVhw658vcL5XM"
let kQBAccountKey = "9phyMKc9HpqTutF2bfaq"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let gcmMessageIDKey = "gcm.message_id"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // [ START Quickblox config ]
        QBSettings.setApplicationID(kQBApplicationID)
        QBSettings.setAuthKey(kQBAuthKey)
        QBSettings.setAuthSecret(kQBAuthSecret)
        QBSettings.setAccountKey(kQBAccountKey)
        QBSettings.setApiEndpoint("https://apicaduceustelemed.quickblox.com", chatEndpoint: "chatcaduceustelemed.quickblox.com", forServiceZone: .production)
        QBSettings.setServiceZone(.production)
        QBSettings.setKeepAliveInterval(30)
        QBSettings.setAutoReconnectEnabled(true)
        QBRTCConfig.setStatsReportTimeInterval(1)
        QBRTCConfig.setDialingTimeInterval(5)
        QBRTCConfig.setAnswerTimeInterval(60)
        // [ END Quickblox config ]
        
        // [START register_for_notifications]
        
        FirebaseApp.configure()
        
        Messaging.messaging().delegate = self
        Messaging.messaging().shouldEstablishDirectChannel = true
        
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization( options: authOptions, completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        
        if (Messaging.messaging().fcmToken != nil) {
            DataModel.sharedInstance.sessionInfo.FirebaseAccessToken = Messaging.messaging().fcmToken!
            print("<-----------------<<< FCM token: \(DataModel.sharedInstance.sessionInfo.FirebaseAccessToken)")
        }else {
            print("<-----------------<<< token was nil")
        }
        // [END register_for_notifications]
        
        FirebaseCrashMessage("We threw an error")
        fatalError()
        
        return true
    }
    
    // [START receive_message]
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        print("<-----------------<<< didReceiveRemoteNotification 1")
        Messaging.messaging().appDidReceiveMessage(userInfo)
        
        if let messageID = userInfo[gcmMessageIDKey] {
            print("<-----------------<<< Message ID: \(messageID)")
        }
        
        print(userInfo)
        
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("<-----------------<<< didReceiveRemoteNotification 2")
        
        Messaging.messaging().appDidReceiveMessage(userInfo)
        
        if let messageID = userInfo[gcmMessageIDKey] {
            print("<-----------------<<< Message ID: \(messageID)")
        }
        
        print(userInfo)
        
        completionHandler(UIBackgroundFetchResult.newData)
        
    }
    
    
    // when APNs has assigned the device a unique token
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        let APNStoken = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Received an APNs device token: \(APNStoken)")
        DataModel.sharedInstance.sessionInfo.APNSAccessToken = APNStoken
        Messaging.messaging().apnsToken = deviceToken
        
    }
    
    
    // [END receive_message]
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("<-----------------<<< Unable to register for remote notifications: \(error.localizedDescription)")
    }
    
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("<-----------------<<< applicationDidEnterBackground")
        QBChat.instance().disconnect { (error) in
            if error != nil {
                print("error: \(String(describing: error))")
            } else {
                print("success for applicationDidEnterBackground")
            }
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("<-----------------<<< applicationWillEnterForeground")
        let qbUser = QBUUser()
        qbUser.id = DataModel.sharedInstance.qbLoginParams.id
        qbUser.password = DataModel.sharedInstance.sessionInfo.QBPassword
        QBChat.instance().connect(with: qbUser) { (error) in
            if error != nil {
                print("error: \(String(describing: error))")
            } else {
                print("success for applicationWillEnterForeground")
            }
        }
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("<-----------------<<< applicationDidBecomeActive")
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        print("<-----------------<<< applicationWillTerminate")
        QBChat.instance().disconnect { (error) in
            if error != nil {
                print("error: \(String(describing: error))")
            } else {
                print("success for applicationWillTerminate")
            }
        }
    }
    
    // LOCK IN PORTRAIT MODE
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask(rawValue: UIInterfaceOrientationMask.portrait.rawValue)
    }
    
}

// [START ios_10_message_handling]
@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        // Change this to your preferred presentation option
        completionHandler([.alert, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        completionHandler()
    }
}
// [END ios_10_message_handling]

extension AppDelegate : MessagingDelegate {
    // [START refresh_token]
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
        DataModel.sharedInstance.sessionInfo.FirebaseAccessToken = fcmToken
    }
    // [END refresh_token]
    // [START ios_10_data_message]
    // Receive data messages on iOS 10+ directly from FCM (bypassing APNs) when the app is in the foreground.
    // To enable direct data messages, you can set Messaging.messaging().shouldEstablishDirectChannel to true.
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("Received data message: \(remoteMessage.appData)")
    }
    // [END ios_10_data_message]
}

