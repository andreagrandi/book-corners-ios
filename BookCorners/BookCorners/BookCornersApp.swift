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
    @State private var apiClient = APIClient()
    @State private var locationService = LocationService()
    @State private var networkMonitor = NetworkMonitor()
    @State private var authService: AuthService
    @State private var isReady = false

    init() {
        let client = APIClient()
        _apiClient = State(initialValue: client)
        _authService = State(initialValue: AuthService(
            apiClient: client,
            keychainService: KeychainService(),
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
