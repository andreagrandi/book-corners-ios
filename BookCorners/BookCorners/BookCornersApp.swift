//
//  BookCornersApp.swift
//  BookCorners
//
//  Created by Andrea Grandi on 10/03/26.
//

import SwiftUI

@main
struct BookCornersApp: App {
    @State private var authService = AuthService(
        apiClient: APIClient(),
        keychainService: KeychainService(),
    )
    @State private var locationService = LocationService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authService)
                .environment(locationService)
                .task {
                    await authService.restoreSession()
                    locationService.startMonitoring()
                }
        }
    }
}
