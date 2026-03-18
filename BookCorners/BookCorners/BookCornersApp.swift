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
            ContentView()
                .environment(\.apiClient, apiClient)
                .environment(authService)
                .environment(locationService)
                .task {
                    await authService.restoreSession()
                    locationService.startMonitoring()
                }
        }
    }
}
