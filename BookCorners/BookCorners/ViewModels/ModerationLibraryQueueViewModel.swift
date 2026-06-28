//
//  ModerationLibraryQueueViewModel.swift
//  BookCorners
//

import Foundation

extension Notification.Name {
    static let moderationLibraryQueueDidChange = Notification.Name("moderationLibraryQueueDidChange")
}

@Observable
class ModerationLibraryQueueViewModel {
    private let apiClient: any APIClientProtocol
    private let pageSize: Int
    private var currentPage = 1
    private var hasLoaded = false

    var summary: ModerationSummary?
    var libraries: [ModerationLibrary] = []
    var selectedStatus: ModerationStatusFilter = .pending
    var searchQuery: String = ""
    var detailLibrary: ModerationLibrary?

    var isLoading = false
    var isRefreshing = false
    var isLoadingMore = false
    var isLoadingDetail = false
    var updatingLibrarySlug: String?

    var errorMessage: String?
    var detailErrorMessage: String?
    var actionErrorMessage: String?
    var hasMorePages = false

    var isUpdating: Bool {
        updatingLibrarySlug != nil
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

    func performSearch(query: String) async {
        searchQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        await loadLibraries(reset: true, showLoading: true)
    }

    func setStatusFilter(_ status: ModerationStatusFilter) async {
        guard selectedStatus != status else { return }
        selectedStatus = status
        await loadLibraries(reset: true, showLoading: true)
    }

    func loadMoreIfNeeded(currentLibrary: ModerationLibrary) async {
        guard currentLibrary.id == libraries.last?.id else { return }
        await loadMore()
    }

    func loadMore() async {
        guard !isLoadingMore, hasMorePages else { return }

        isLoadingMore = true
        errorMessage = nil
        defer { isLoadingMore = false }

        do {
            let nextPage = currentPage + 1
            let response = try await apiClient.getModerationLibraries(
                request: makeRequest(page: nextPage),
            )
            libraries.append(contentsOf: response.items)
            currentPage = nextPage
            hasMorePages = response.pagination.hasNext
        } catch {
            errorMessage = userMessage(
                for: error,
                fallback: "Failed to load more library submissions.",
            )
        }
    }

    func setDetailLibrary(_ library: ModerationLibrary) {
        if detailLibrary?.slug != library.slug {
            detailLibrary = library
        }
        detailErrorMessage = nil
    }

    func loadDetail(slug: String) async {
        isLoadingDetail = true
        detailErrorMessage = nil
        defer { isLoadingDetail = false }

        do {
            detailLibrary = try await apiClient.getModerationLibrary(slug: slug)
        } catch {
            detailErrorMessage = userMessage(
                for: error,
                fallback: "Failed to load library details.",
            )
        }
    }

    func approve(_ library: ModerationLibrary) async {
        await updateLibrary(
            library,
            status: .approved,
            rejectionReason: nil,
        )
    }

    func reject(_ library: ModerationLibrary, reason: String) async {
        let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedReason.isEmpty else {
            actionErrorMessage = "Enter a rejection reason before rejecting this library."
            return
        }

        await updateLibrary(
            library,
            status: .rejected,
            rejectionReason: trimmedReason,
        )
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
            let response = try await apiClient.getModerationLibraries(
                request: makeRequest(page: 1),
            )
            libraries = response.items
            currentPage = 1
            hasMorePages = response.pagination.hasNext
        } catch {
            errorMessage = userMessage(
                for: error,
                fallback: "Failed to load library moderation queue.",
            )
        }
    }

    private func loadLibraries(reset: Bool, showLoading: Bool) async {
        if showLoading {
            isLoading = true
        }
        errorMessage = nil
        defer { isLoading = false }

        do {
            let page = reset ? 1 : currentPage
            let response = try await apiClient.getModerationLibraries(
                request: makeRequest(page: page),
            )
            if reset {
                libraries = response.items
                currentPage = 1
            } else {
                libraries.append(contentsOf: response.items)
            }
            hasMorePages = response.pagination.hasNext
            hasLoaded = true
        } catch {
            errorMessage = userMessage(
                for: error,
                fallback: "Failed to load library submissions.",
            )
        }
    }

    private func updateLibrary(
        _ library: ModerationLibrary,
        status: LibraryModerationStatus,
        rejectionReason: String?,
    ) async {
        guard updatingLibrarySlug == nil else { return }

        updatingLibrarySlug = library.slug
        actionErrorMessage = nil
        defer { updatingLibrarySlug = nil }

        do {
            let updatedLibrary = try await apiClient.updateModerationLibrary(
                slug: library.slug,
                status: status,
                rejectionReason: rejectionReason,
            )
            detailLibrary = updatedLibrary
            NotificationCenter.default.post(name: .moderationLibraryQueueDidChange, object: nil)
            await refresh()
        } catch {
            actionErrorMessage = userMessage(
                for: error,
                fallback: "Failed to update library status.",
            )
        }
    }

    private func makeRequest(page: Int) -> ModerationLibraryListRequest {
        ModerationLibraryListRequest(
            status: selectedStatus,
            query: searchQuery.isEmpty ? nil : searchQuery,
            country: nil,
            source: nil,
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
