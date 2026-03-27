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
    @Environment(NetworkMonitor.self) private var networkMonitor

    var body: some View {
        VStack(spacing: 0) {
            if !networkMonitor.isConnected {
                Label("No internet connection", systemImage: "wifi.slash")
                    .font(.footnote)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(.red.opacity(0.9))
                    .foregroundStyle(.white)
            }

            TabView(selection: $selectedTab) {
                Tab("Nearby", systemImage: "books.vertical", value: AppTab.nearby) {
                    LibraryListView()
                }

                Tab("Map", systemImage: "map", value: AppTab.map) {
                    MapTabView()
                }

                Tab("Submit", systemImage: "plus.circle", value: AppTab.submit) {
                    SubmitLibraryView {
                        selectedTab = previousTab
                    }
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
                    previousTab = oldValue
                }
            }
            .sheet(isPresented: $showLoginSheet) {
                AuthGateView()
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
}

#Preview {
    ContentView()
        .environment(AuthService(
            apiClient: APIClient(),
            keychainService: KeychainService(),
        ))
        .environment(NetworkMonitor())
}
