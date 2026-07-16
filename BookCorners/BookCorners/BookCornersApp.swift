//
//  BookCornersApp.swift
//  BookCorners
//
//  Created by Andrea Grandi on 10/03/26.
//

import GoogleSignIn
import SwiftUI

@main
struct BookCornersApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @State private var apiClient = APIClient()
    @State private var locationService = LocationService()
    @State private var networkMonitor = NetworkMonitor()
    @State private var pushNotificationService: PushNotificationService
    @State private var authService: AuthService
    @State private var isReady = false

    init() {
        let client = APIClient()
        let pushService = PushNotificationService(apiClient: client)
        pushService.startHandlingAppDelegateEvents()

        _apiClient = State(initialValue: client)
        _pushNotificationService = State(initialValue: pushService)
        _authService = State(initialValue: AuthService(
            apiClient: client,
            keychainService: KeychainService(),
            pushNotificationService: pushService,
        ))
    }

    var body: some Scene {
        WindowGroup {
            if isReady {
                ContentView()
                    .environment(\.apiClient, apiClient)
                    .environment(authService)
                    .environment(locationService)
                    .environment(networkMonitor)
                    .environment(pushNotificationService)
                    .onOpenURL { url in
                        GIDSignIn.sharedInstance.handle(url)
                    }
            } else {
                SplashView()
                    .environment(\.apiClient, apiClient)
                    .environment(authService)
                    .environment(locationService)
                    .environment(pushNotificationService)
                    .task {
                        async let restore: () = authService.restoreSession()
                        async let minDelay: () = Task.sleep(for: .milliseconds(800))
                        if locationService.isAuthorized {
                            locationService.startMonitoring()
                        }
                        networkMonitor.startMonitoring()
                        _ = await (restore, try? minDelay)
                        isReady = true
                    }
            }
        }
    }
}
