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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authService)
                .task { await authService.restoreSession() }
        }
    }
}
