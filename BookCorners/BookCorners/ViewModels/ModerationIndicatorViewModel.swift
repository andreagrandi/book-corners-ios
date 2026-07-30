//
//  ModerationIndicatorViewModel.swift
//  BookCorners
//

import Foundation

@Observable
final class ModerationIndicatorViewModel {
    private let apiClient: any APIClientProtocol
    private var isRefreshing = false
    private var needsRefresh = false

    private(set) var summary: ModerationSummary?

    var hasPendingWork: Bool {
        guard let summary else { return false }
        return summary.totalPending > 0
    }

    init(client: any APIClientProtocol) {
        apiClient = client
    }

    func refresh() async {
        if isRefreshing {
            needsRefresh = true
            return
        }

        isRefreshing = true
        defer { isRefreshing = false }

        repeat {
            needsRefresh = false

            do {
                summary = try await apiClient.getModerationSummary()
            } catch {
                // Keep the last successful summary during transient failures.
            }
        } while needsRefresh
    }
}
