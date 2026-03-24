//
//  BookCornersApp.swift
//  BookCorners
//
//  Created by Andrea Grandi on 10/03/26.
//

import SwiftUI

@main
struct BookCornersApp: App {
    @State private var apiClient = APIClient()
    @State private var locationService = LocationService()
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
            } else {
                SplashView()
                    .environment(\.apiClient, apiClient)
                    .environment(authService)
                    .environment(locationService)
                    .task {
                        async let restore: () = authService.restoreSession()
                        async let minDelay: () = Task.sleep(for: .milliseconds(800))
                        locationService.startMonitoring()
                        _ = await (restore, try? minDelay)
                        isReady = true
                    }
            }
        }
    }
}
