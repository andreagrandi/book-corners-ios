//
//  BookCornersApp.swift
//  BookCorners
//
//  Created by Andrea Grandi on 10/03/26.
//

import GoogleSignIn
import Sentry
import SwiftUI

@main
struct BookCornersApp: App {
    @State private var apiClient = APIClient()
    @State private var locationService = LocationService()
    @State private var networkMonitor = NetworkMonitor()
    @State private var authService: AuthService
    @State private var isReady = false

    init() {
        Self.startSentry()

        let client = APIClient()
        _apiClient = State(initialValue: client)
        _authService = State(initialValue: AuthService(
            apiClient: client,
            keychainService: KeychainService(),
        ))
    }

    private static func startSentry() {
        let dsn = Bundle.main.object(forInfoDictionaryKey: "SentryDSN") as? String
        guard let dsn, !dsn.isEmpty, !dsn.hasPrefix("__") else {
            #if DEBUG
                print("[Sentry] SentryDSN missing or placeholder in Info.plist — Sentry not started.")
            #endif
            return
        }

        SentrySDK.start { options in
            options.dsn = dsn
            options.debug = false
            #if DEBUG
                options.environment = "debug"
            #else
                options.environment = "release"
            #endif
        }
    }

    var body: some Scene {
        WindowGroup {
            if isReady {
                ContentView()
                    .environment(\.apiClient, apiClient)
                    .environment(authService)
                    .environment(locationService)
                    .environment(networkMonitor)
                    .onOpenURL { url in
                        GIDSignIn.sharedInstance.handle(url)
                    }
            } else {
                SplashView()
                    .environment(\.apiClient, apiClient)
                    .environment(authService)
                    .environment(locationService)
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
