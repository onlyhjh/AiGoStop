//
//  AppDelegate.swift
//  AiGoStop
//
//  Created by Joey's Mac mini on 8/12/26.
//

import UIKit
import AVFoundation

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("\(#function) called")
        
        // play sound when in Silent Mode
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Allow playback even if Ring/Silent switch is on mute
            let sessionCategory = AVAudioSession.Category.playback.rawValue
            let defaultValue: AVAudioSession.Category = .ambient
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category(rawValue: sessionCategory))

        } catch {
            print("AVAudioSession error: \(error.localizedDescription)")
        }
        
        // Push 동의 요청
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            DispatchQueue.main.async {
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        return true
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // TODO: Check it
        let userInfo = notification.request.content.userInfo
        print(userInfo)
        
        self.checkAPNS(userInfo: userInfo, wasAppActivated: true)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Save token remote id
        let tokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        print("-------APNS PUSH deviceToken-------: \(tokenString)")

        if tokenString != UserDefaults.standard.pushToken {
            UserDefaults.standard.pushToken = tokenString
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("-------APNS PUSH Register Fail-------: \(error.localizedDescription)")

    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        print("-------APNS PUSH didReceive -------: \(response.notification.request.content.userInfo)")
        let userInfo = response.notification.request.content.userInfo
        // when pressed on inactivate state
        completionHandler()
        checkAPNS(userInfo: userInfo, wasAppActivated: false)
    }
    
    func checkAPNS(userInfo: [AnyHashable : Any], wasAppActivated: Bool) {
    }
}

