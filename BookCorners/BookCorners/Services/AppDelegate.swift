//
//  AppDelegate.swift
//  BookCorners
//

import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil,
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(
        _: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data,
    ) {
        NotificationCenter.default.post(
            name: .remoteNotificationDeviceTokenDidRegister,
            object: nil,
            userInfo: [RemoteNotificationUserInfoKey.deviceToken: deviceToken],
        )
    }

    func application(
        _: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: any Error,
    ) {
        NotificationCenter.default.post(
            name: .remoteNotificationDeviceTokenRegistrationDidFail,
            object: nil,
            userInfo: [RemoteNotificationUserInfoKey.error: error],
        )
    }

    func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void,
    ) {
        NotificationCenter.default.post(
            name: .remoteNotificationWillPresent,
            object: nil,
            userInfo: notification.request.content.userInfo,
        )
        completionHandler([.banner, .list, .sound, .badge])
    }

    func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void,
    ) {
        NotificationCenter.default.post(
            name: .remoteNotificationResponseDidReceive,
            object: nil,
            userInfo: response.notification.request.content.userInfo,
        )
        completionHandler()
    }
}

enum RemoteNotificationUserInfoKey {
    static let deviceToken = "deviceToken"
    static let error = "error"
}

extension Notification.Name {
    static let remoteNotificationDeviceTokenDidRegister = Notification.Name("remoteNotificationDeviceTokenDidRegister")
    static let remoteNotificationDeviceTokenRegistrationDidFail = Notification.Name("remoteNotificationDeviceTokenRegistrationDidFail")
    static let remoteNotificationWillPresent = Notification.Name("remoteNotificationWillPresent")
    static let remoteNotificationResponseDidReceive = Notification.Name("remoteNotificationResponseDidReceive")
}
