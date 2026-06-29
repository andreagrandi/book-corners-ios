//
//  ModerationReportQueueViewModel.swift
//  BookCorners
//

import Foundation

extension Notification.Name {
    static let moderationReportQueueDidChange = Notification.Name("moderationReportQueueDidChange")
}

@Observable
class ModerationReportQueueViewModel {
    private let apiClient: any APIClientProtocol
    private let pageSize: Int
    private var currentPage = 1
    private var hasLoaded = false

    var summary: ModerationSummary?
    var reports: [ModerationReport] = []
    var selectedStatus: ReportModerationStatusFilter = .open
    var selectedReason: ReportModerationReasonFilter = .all
    var detailReport: ModerationReport?

    var isLoading = false
    var isRefreshing = false
    var isLoadingMore = false
    var updatingReportID: Int?

    var errorMessage: String?
    var actionErrorMessage: String?
    var hasMorePages = false

    var isUpdating: Bool {
        updatingReportID != nil
    }

    init(client: any APIClientProtocol, pageSize: Int = 20) {
        apiClient = client
        self.pageSize = pageSize
    }

    func loadInitialIfNeeded() async {
        guard !hasLoaded else { return }
        await reload(showLoading: true)
    }

    func refresh() async {
        await reload(showLoading: false)
    }

    func setStatusFilter(_ status: ReportModerationStatusFilter) async {
        guard selectedStatus != status else { return }
        selectedStatus = status
        await loadReports(reset: true, showLoading: true)
    }

    func setReasonFilter(_ reason: ReportModerationReasonFilter) async {
        guard selectedReason != reason else { return }
        selectedReason = reason
        await loadReports(reset: true, showLoading: true)
    }

    func loadMoreIfNeeded(currentReport: ModerationReport) async {
        guard currentReport.id == reports.last?.id else { return }
        await loadMore()
    }

    func loadMore() async {
        guard !isLoadingMore, hasMorePages else { return }

        isLoadingMore = true
        errorMessage = nil
        defer { isLoadingMore = false }

        do {
            let nextPage = currentPage + 1
            let response = try await apiClient.getModerationReports(
                request: makeRequest(page: nextPage),
            )
            reports.append(contentsOf: response.items)
            currentPage = nextPage
            hasMorePages = response.pagination.hasNext
        } catch {
            errorMessage = userMessage(
                for: error,
                fallback: "Failed to load more user reports.",
            )
        }
    }

    func setDetailReport(_ report: ModerationReport) {
        if detailReport?.id != report.id {
            detailReport = report
        }
        actionErrorMessage = nil
    }

    func resolve(_ report: ModerationReport) async {
        await updateReport(report, status: .resolved)
    }

    func dismiss(_ report: ModerationReport) async {
        await updateReport(report, status: .dismissed)
    }

    func clearActionError() {
        actionErrorMessage = nil
    }

    private func reload(showLoading: Bool) async {
        if showLoading {
            isLoading = true
        } else {
            isRefreshing = true
        }
        errorMessage = nil
        defer {
            isLoading = false
            isRefreshing = false
            hasLoaded = true
        }

        do {
            summary = try await apiClient.getModerationSummary()
            let response = try await apiClient.getModerationReports(
                request: makeRequest(page: 1),
            )
            reports = response.items
            currentPage = 1
            hasMorePages = response.pagination.hasNext
        } catch {
            errorMessage = userMessage(
                for: error,
                fallback: "Failed to load report moderation queue.",
            )
        }
    }

    private func loadReports(reset: Bool, showLoading: Bool) async {
        if showLoading {
            isLoading = true
        }
        errorMessage = nil
        defer { isLoading = false }

        do {
            let page = reset ? 1 : currentPage
            let response = try await apiClient.getModerationReports(
                request: makeRequest(page: page),
            )
            if reset {
                reports = response.items
                currentPage = 1
            } else {
                reports.append(contentsOf: response.items)
            }
            hasMorePages = response.pagination.hasNext
            hasLoaded = true
        } catch {
            errorMessage = userMessage(
                for: error,
                fallback: "Failed to load user reports.",
            )
        }
    }

    private func updateReport(_ report: ModerationReport, status: ReportModerationStatus) async {
        guard updatingReportID == nil else { return }

        updatingReportID = report.id
        actionErrorMessage = nil
        defer { updatingReportID = nil }

        do {
            let updatedReport = try await apiClient.updateModerationReport(
                id: report.id,
                status: status,
            )
            detailReport = updatedReport
            NotificationCenter.default.post(name: .moderationReportQueueDidChange, object: nil)
            await refresh()
        } catch {
            actionErrorMessage = userMessage(
                for: error,
                fallback: "Failed to update report status.",
            )
        }
    }

    private func makeRequest(page: Int) -> ModerationReportListRequest {
        ModerationReportListRequest(
            status: selectedStatus,
            reason: selectedReason,
            page: page,
            pageSize: pageSize,
        )
    }

    private func userMessage(for error: Error, fallback: String) -> String {
        guard let apiError = error as? APIClientError else {
            return fallback
        }

        switch apiError {
        case let .forbidden(message):
            return message.isEmpty ? "Staff access required." : message
        case .unauthorized:
            return "Sign in with a staff account to continue."
        case .networkError:
            return "Unable to connect. Check your internet connection."
        default:
            return apiError.localizedDescription
        }
    }
}
