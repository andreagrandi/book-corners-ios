//
//  PushNotificationService.swift
//  BookCorners
//

import Foundation
import Observation
import UIKit
import UserNotifications

@MainActor
protocol PushNotificationManaging: AnyObject {
    func registerForRemoteNotificationsIfNeeded() async
    func unregisterCurrentDevice() async
}

@MainActor
@Observable
final class PushNotificationService: PushNotificationManaging {
    static let deviceTokenStorageKey = "apns_device_token"

    var authorizationStatus: UNAuthorizationStatus?
    var lastRegistrationError: String?
    var pendingAdminRouteRequest: AdminNotificationRouteRequest?
    var lastContributorNotificationPayload: PushNotificationPayload?

    @ObservationIgnored private let apiClient: any APIClientProtocol
    @ObservationIgnored private let userDefaults: UserDefaults
    @ObservationIgnored private let userNotificationCenter: UNUserNotificationCenter
    @ObservationIgnored private let eventCenter: NotificationCenter
    @ObservationIgnored private var observerTokens: [NSObjectProtocol] = []

    init(
        apiClient: any APIClientProtocol,
        userDefaults: UserDefaults = .standard,
        userNotificationCenter: UNUserNotificationCenter = .current(),
        eventCenter: NotificationCenter = .default,
    ) {
        self.apiClient = apiClient
        self.userDefaults = userDefaults
        self.userNotificationCenter = userNotificationCenter
        self.eventCenter = eventCenter
    }

    func startHandlingAppDelegateEvents() {
        guard observerTokens.isEmpty else { return }

        observerTokens = [
            eventCenter.addObserver(
                forName: .remoteNotificationDeviceTokenDidRegister,
                object: nil,
                queue: .main,
            ) { [weak self] notification in
                let deviceToken = notification.userInfo?[RemoteNotificationUserInfoKey.deviceToken] as? Data
                guard let deviceToken else { return }

                Task { @MainActor in
                    await self?.handleDeviceToken(deviceToken)
                }
            },
            eventCenter.addObserver(
                forName: .remoteNotificationDeviceTokenRegistrationDidFail,
                object: nil,
                queue: .main,
            ) { [weak self] notification in
                let errorMessage = (notification.userInfo?[RemoteNotificationUserInfoKey.error] as? any Error)?
                    .localizedDescription
                MainActor.assumeIsolated {
                    self?.lastRegistrationError = errorMessage
                }
            },
            eventCenter.addObserver(
                forName: .remoteNotificationWillPresent,
                object: nil,
                queue: .main,
            ) { [weak self] notification in
                MainActor.assumeIsolated {
                    self?.handleNotification(userInfo: notification.userInfo ?? [:], shouldRoute: false)
                }
            },
            eventCenter.addObserver(
                forName: .remoteNotificationResponseDidReceive,
                object: nil,
                queue: .main,
            ) { [weak self] notification in
                MainActor.assumeIsolated {
                    self?.handleNotification(userInfo: notification.userInfo ?? [:], shouldRoute: true)
                }
            },
        ]
    }

    func registerForRemoteNotificationsIfNeeded() async {
        if let savedToken = userDefaults.string(forKey: Self.deviceTokenStorageKey) {
            await registerDeviceToken(savedToken)
        }

        let settings = await userNotificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus

        switch settings.authorizationStatus {
        case .notDetermined:
            await requestAuthorizationAndRegister()
        case .authorized, .provisional, .ephemeral:
            UIApplication.shared.registerForRemoteNotifications()
        case .denied:
            break
        @unknown default:
            break
        }
    }

    func unregisterCurrentDevice() async {
        guard
            apiClient.accessToken != nil,
            let token = userDefaults.string(forKey: Self.deviceTokenStorageKey)
        else {
            return
        }

        do {
            try await apiClient.unregisterDeviceToken(token: token)
            lastRegistrationError = nil
        } catch {
            lastRegistrationError = error.localizedDescription
        }
    }

    func clearPendingAdminRoute(id: UUID) {
        if pendingAdminRouteRequest?.id == id {
            pendingAdminRouteRequest = nil
        }
    }

    static func hexString(from data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }

    private func requestAuthorizationAndRegister() async {
        do {
            let isGranted = try await userNotificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            authorizationStatus = await (userNotificationCenter.notificationSettings()).authorizationStatus
            if isGranted {
                UIApplication.shared.registerForRemoteNotifications()
            }
        } catch {
            lastRegistrationError = error.localizedDescription
        }
    }

    private func handleDeviceToken(_ deviceToken: Data) async {
        let token = Self.hexString(from: deviceToken)
        userDefaults.set(token, forKey: Self.deviceTokenStorageKey)
        await registerDeviceToken(token)
    }

    private func registerDeviceToken(_ token: String) async {
        guard apiClient.accessToken != nil else { return }

        do {
            _ = try await apiClient.registerDeviceToken(token: token, environment: .current)
            lastRegistrationError = nil
        } catch {
            lastRegistrationError = error.localizedDescription
        }
    }

    private func handleNotification(userInfo: [AnyHashable: Any], shouldRoute: Bool) {
        guard let payload = PushNotificationPayload(userInfo: userInfo) else { return }

        postQueueRefreshNotification(for: payload)

        if shouldRoute, let adminRoute = payload.adminRoute {
            pendingAdminRouteRequest = AdminNotificationRouteRequest(route: adminRoute)
        } else if payload.isContributorEvent {
            lastContributorNotificationPayload = payload
        }
    }

    private func postQueueRefreshNotification(for payload: PushNotificationPayload) {
        switch payload.adminRoute {
        case .libraryQueue:
            eventCenter.post(name: .moderationLibraryQueueDidChange, object: nil)
        case .photoQueue:
            eventCenter.post(name: .moderationPhotoQueueDidChange, object: nil)
        case .reportQueue:
            eventCenter.post(name: .moderationReportQueueDidChange, object: nil)
        case nil:
            break
        }
    }
}
