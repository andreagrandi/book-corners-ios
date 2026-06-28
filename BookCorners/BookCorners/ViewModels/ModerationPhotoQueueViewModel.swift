//
//  ModerationPhotoQueueViewModel.swift
//  BookCorners
//

import Foundation

extension Notification.Name {
    static let moderationPhotoQueueDidChange = Notification.Name("moderationPhotoQueueDidChange")
}

@Observable
class ModerationPhotoQueueViewModel {
    private let apiClient: any APIClientProtocol
    private let pageSize: Int
    private var currentPage = 1
    private var hasLoaded = false

    var summary: ModerationSummary?
    var photos: [ModerationPhoto] = []
    var selectedStatus: PhotoModerationStatusFilter = .pending
    var detailPhoto: ModerationPhoto?

    var isLoading = false
    var isRefreshing = false
    var isLoadingMore = false
    var updatingPhotoID: Int?

    var errorMessage: String?
    var actionErrorMessage: String?
    var hasMorePages = false

    var isUpdating: Bool {
        updatingPhotoID != nil
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

    func setStatusFilter(_ status: PhotoModerationStatusFilter) async {
        guard selectedStatus != status else { return }
        selectedStatus = status
        await loadPhotos(reset: true, showLoading: true)
    }

    func loadMoreIfNeeded(currentPhoto: ModerationPhoto) async {
        guard currentPhoto.id == photos.last?.id else { return }
        await loadMore()
    }

    func loadMore() async {
        guard !isLoadingMore, hasMorePages else { return }

        isLoadingMore = true
        errorMessage = nil
        defer { isLoadingMore = false }

        do {
            let nextPage = currentPage + 1
            let response = try await apiClient.getModerationPhotos(
                request: makeRequest(page: nextPage),
            )
            photos.append(contentsOf: response.items)
            currentPage = nextPage
            hasMorePages = response.pagination.hasNext
        } catch {
            errorMessage = userMessage(
                for: error,
                fallback: "Failed to load more photo submissions.",
            )
        }
    }

    func setDetailPhoto(_ photo: ModerationPhoto) {
        if detailPhoto?.id != photo.id {
            detailPhoto = photo
        }
        actionErrorMessage = nil
    }

    func approve(_ photo: ModerationPhoto) async {
        await updatePhoto(photo, status: .approved)
    }

    func reject(_ photo: ModerationPhoto) async {
        await updatePhoto(photo, status: .rejected)
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
            let response = try await apiClient.getModerationPhotos(
                request: makeRequest(page: 1),
            )
            photos = response.items
            currentPage = 1
            hasMorePages = response.pagination.hasNext
        } catch {
            errorMessage = userMessage(
                for: error,
                fallback: "Failed to load photo moderation queue.",
            )
        }
    }

    private func loadPhotos(reset: Bool, showLoading: Bool) async {
        if showLoading {
            isLoading = true
        }
        errorMessage = nil
        defer { isLoading = false }

        do {
            let page = reset ? 1 : currentPage
            let response = try await apiClient.getModerationPhotos(
                request: makeRequest(page: page),
            )
            if reset {
                photos = response.items
                currentPage = 1
            } else {
                photos.append(contentsOf: response.items)
            }
            hasMorePages = response.pagination.hasNext
            hasLoaded = true
        } catch {
            errorMessage = userMessage(
                for: error,
                fallback: "Failed to load photo submissions.",
            )
        }
    }

    private func updatePhoto(_ photo: ModerationPhoto, status: PhotoModerationStatus) async {
        guard updatingPhotoID == nil else { return }

        updatingPhotoID = photo.id
        actionErrorMessage = nil
        defer { updatingPhotoID = nil }

        do {
            let updatedPhoto = try await apiClient.updateModerationPhoto(
                id: photo.id,
                status: status,
            )
            detailPhoto = updatedPhoto
            NotificationCenter.default.post(name: .moderationPhotoQueueDidChange, object: nil)
            await refresh()
        } catch {
            actionErrorMessage = userMessage(
                for: error,
                fallback: "Failed to update photo status.",
            )
        }
    }

    private func makeRequest(page: Int) -> ModerationPhotoListRequest {
        ModerationPhotoListRequest(
            status: selectedStatus,
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
