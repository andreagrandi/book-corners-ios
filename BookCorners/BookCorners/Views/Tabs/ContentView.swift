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
        case admin
        case submit
        case profile
    }

    @SceneStorage("selectedTab") private var selectedTab: AppTab = .nearby
    @State private var showLoginSheet = false
    @State private var adminNavigationPath = [AdminNotificationRoute]()

    @Environment(AuthService.self) private var authService
    @Environment(NetworkMonitor.self) private var networkMonitor
    @Environment(PushNotificationService.self) private var pushNotificationService

    private var tabSelection: Binding<AppTab> {
        Binding {
            if selectedTab == .admin, !authService.canAccessAdmin {
                return .nearby
            }
            return selectedTab
        } set: { newValue in
            if newValue == .admin, !authService.canAccessAdmin {
                selectedTab = .nearby
            } else {
                selectedTab = newValue
            }
        }
    }

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

            TabView(selection: tabSelection) {
                Tab("Nearby", systemImage: "books.vertical", value: AppTab.nearby) {
                    LibraryListView()
                }

                Tab("Map", systemImage: "map", value: AppTab.map) {
                    MapTabView()
                }

                if authService.canAccessAdmin {
                    Tab("Admin", systemImage: "rectangle.grid.2x2", value: AppTab.admin) {
                        NavigationStack(path: $adminNavigationPath) {
                            AdminDashboardView()
                                .navigationDestination(for: AdminNotificationRoute.self) { route in
                                    adminDestination(for: route)
                                }
                        }
                    }
                }

                Tab("Submit", systemImage: "plus.circle", value: AppTab.submit) {
                    SubmitLibraryView {
                        selectedTab = .nearby
                    }
                }

                Tab("Profile", systemImage: "person", value: AppTab.profile) {
                    ProfileView()
                }
            }
            .onAppear(perform: moveAwayFromAdminIfNeeded)
            .onChange(of: selectedTab) { oldValue, newValue in
                if newValue == .admin, !authService.canAccessAdmin {
                    selectedTab = .nearby
                } else if newValue == .submit, !authService.isAuthenticated {
                    selectedTab = oldValue == .admin ? .nearby : oldValue
                    showLoginSheet = true
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
            .onChange(of: authService.canAccessAdmin) { _, newValue in
                if newValue == false {
                    moveAwayFromAdminIfNeeded()
                }
            }
            .onChange(of: pushNotificationService.pendingAdminRouteRequest) { _, request in
                handleAdminRouteRequest(request)
            }
            .tabBarMinimizeBehavior(.onScrollDown)
        }
    }

    @ViewBuilder
    private func adminDestination(for route: AdminNotificationRoute) -> some View {
        switch route {
        case .libraryQueue:
            LibraryModerationQueueView()
        case .photoQueue:
            PhotoModerationQueueView()
        case .reportQueue:
            ContentUnavailableView {
                Label("User Reports", systemImage: "flag")
            } description: {
                Text("Open reports are highlighted on the Admin Dashboard summary.")
            }
        }
    }

    private func handleAdminRouteRequest(_ request: AdminNotificationRouteRequest?) {
        guard let request else { return }
        defer { pushNotificationService.clearPendingAdminRoute(id: request.id) }

        guard authService.canAccessAdmin else { return }
        selectedTab = .admin
        adminNavigationPath = [request.route]
    }

    private func moveAwayFromAdminIfNeeded() {
        if !authService.canAccessAdmin {
            adminNavigationPath.removeAll()
        }
        if selectedTab == .admin, !authService.canAccessAdmin {
            selectedTab = .nearby
        }
    }
}

#Preview {
    let apiClient = APIClient()

    ContentView()
        .environment(AuthService(
            apiClient: apiClient,
            keychainService: KeychainService(),
        ))
        .environment(NetworkMonitor())
        .environment(PushNotificationService(apiClient: apiClient))
}
