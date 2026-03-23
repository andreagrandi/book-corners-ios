//
//  ContentView.swift
//  BookCorners
//
//  Created by Andrea Grandi on 10/03/26.
//

import SwiftUI

struct ContentView: View {
    enum AppTab: String {
        case nearby
        case map
        case submit
        case profile
    }

    @SceneStorage("selectedTab") private var selectedTab: AppTab = .nearby
    @State private var previousTab: AppTab = .nearby
    @State private var showLoginSheet = false

    @Environment(AuthService.self) private var authService

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Nearby", systemImage: "books.vertical", value: AppTab.nearby) {
                LibraryListView()
            }

            Tab("Map", systemImage: "map", value: AppTab.map) {
                MapTabView()
            }

            Tab("Submit", systemImage: "plus.circle", value: AppTab.submit) {
                SubmitLibraryView()
            }

            Tab("Profile", systemImage: "person", value: AppTab.profile) {
                ProfileView()
            }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == .submit, !authService.isAuthenticated {
                selectedTab = oldValue
                showLoginSheet = true
            } else {
                previousTab = newValue
            }
        }
        .sheet(isPresented: $showLoginSheet) {
            LoginView()
        }
        .onChange(of: authService.isAuthenticated) { _, newValue in
            if newValue == true, showLoginSheet {
                showLoginSheet = false
                selectedTab = .submit
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

#Preview {
    ContentView()
        .environment(AuthService(
            apiClient: APIClient(),
            keychainService: KeychainService(),
        ))
}
