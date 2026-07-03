//
//  ContributionCenterViewModel.swift
//  BookCorners
//

import Foundation

@Observable
class ContributionCenterViewModel {
    private let apiClient: any APIClientProtocol
    private let pageSize: Int

    var librarySubmissions: [ContributionLibrary] = []
    var reports: [ContributionReport] = []
    var photos: [ContributionPhoto] = []
    var favourites: [Library] = []

    var librarySubmissionCount: Int?
    var reportCount: Int?
    var photoCount: Int?
    var favouriteCount: Int?

    var isLoadingLibraries = false
    var isLoadingReports = false
    var isLoadingPhotos = false
    var isLoadingFavourites = false

    var isLoadingMoreLibraries = false
    var isLoadingMoreReports = false
    var isLoadingMorePhotos = false
    var isLoadingMoreFavourites = false

    var libraryErrorMessage: String?
    var reportErrorMessage: String?
    var photoErrorMessage: String?
    var favouriteErrorMessage: String?

    var hasMoreLibraries = false
    var hasMoreReports = false
    var hasMorePhotos = false
    var hasMoreFavourites = false

    private var hasLoadedInitialData = false
    private var libraryPage = 1
    private var reportPage = 1
    private var photoPage = 1
    private var favouritePage = 1

    init(client: any APIClientProtocol, pageSize: Int = 10) {
        apiClient = client
        self.pageSize = pageSize
    }

    func loadInitialIfNeeded() async {
        guard !hasLoadedInitialData else { return }
        hasLoadedInitialData = true
        await refresh()
    }

    func refresh() async {
        await loadLibrarySubmissions(reset: true)
        await loadReports(reset: true)
        await loadPhotos(reset: true)
        await loadFavourites(reset: true)
    }

    func retryLibrarySubmissions() async {
        await loadLibrarySubmissions(reset: true)
    }

    func retryReports() async {
        await loadReports(reset: true)
    }

    func retryPhotos() async {
        await loadPhotos(reset: true)
    }

    func retryFavourites() async {
        await loadFavourites(reset: true)
    }

    func loadMoreLibrarySubmissions() async {
        guard hasMoreLibraries, !isLoadingMoreLibraries else { return }
        await loadLibrarySubmissions(reset: false)
    }

    func loadMoreReports() async {
        guard hasMoreReports, !isLoadingMoreReports else { return }
        await loadReports(reset: false)
    }

    func loadMorePhotos() async {
        guard hasMorePhotos, !isLoadingMorePhotos else { return }
        await loadPhotos(reset: false)
    }

    func loadMoreFavourites() async {
        guard hasMoreFavourites, !isLoadingMoreFavourites else { return }
        await loadFavourites(reset: false)
    }

    private func loadLibrarySubmissions(reset: Bool) async {
        if reset {
            isLoadingLibraries = true
            libraryErrorMessage = nil
        } else {
            isLoadingMoreLibraries = true
            libraryErrorMessage = nil
        }
        defer {
            isLoadingLibraries = false
            isLoadingMoreLibraries = false
        }

        do {
            let page = reset ? 1 : libraryPage + 1
            let response = try await apiClient.getContributionLibraries(page: page, pageSize: pageSize)
            if reset {
                librarySubmissions = response.items
            } else {
                librarySubmissions.append(contentsOf: response.items)
            }
            librarySubmissionCount = response.pagination.total
            hasMoreLibraries = response.pagination.hasNext
            libraryPage = page
        } catch {
            libraryErrorMessage = reset ? "Failed to load library submissions" : "Failed to load more library submissions"
        }
    }

    private func loadReports(reset: Bool) async {
        if reset {
            isLoadingReports = true
            reportErrorMessage = nil
        } else {
            isLoadingMoreReports = true
            reportErrorMessage = nil
        }
        defer {
            isLoadingReports = false
            isLoadingMoreReports = false
        }

        do {
            let page = reset ? 1 : reportPage + 1
            let response = try await apiClient.getContributionReports(page: page, pageSize: pageSize)
            if reset {
                reports = response.items
            } else {
                reports.append(contentsOf: response.items)
            }
            reportCount = response.pagination.total
            hasMoreReports = response.pagination.hasNext
            reportPage = page
        } catch {
            reportErrorMessage = reset ? "Failed to load reports" : "Failed to load more reports"
        }
    }

    private func loadPhotos(reset: Bool) async {
        if reset {
            isLoadingPhotos = true
            photoErrorMessage = nil
        } else {
            isLoadingMorePhotos = true
            photoErrorMessage = nil
        }
        defer {
            isLoadingPhotos = false
            isLoadingMorePhotos = false
        }

        do {
            let page = reset ? 1 : photoPage + 1
            let response = try await apiClient.getContributionPhotos(page: page, pageSize: pageSize)
            if reset {
                photos = response.items
            } else {
                photos.append(contentsOf: response.items)
            }
            photoCount = response.pagination.total
            hasMorePhotos = response.pagination.hasNext
            photoPage = page
        } catch {
            photoErrorMessage = reset ? "Failed to load community photos" : "Failed to load more community photos"
        }
    }

    private func loadFavourites(reset: Bool) async {
        if reset {
            isLoadingFavourites = true
            favouriteErrorMessage = nil
        } else {
            isLoadingMoreFavourites = true
            favouriteErrorMessage = nil
        }
        defer {
            isLoadingFavourites = false
            isLoadingMoreFavourites = false
        }

        do {
            let page = reset ? 1 : favouritePage + 1
            let response = try await apiClient.getFavourites(page: page, pageSize: pageSize)
            if reset {
                favourites = response.items
            } else {
                favourites.append(contentsOf: response.items)
            }
            favouriteCount = response.pagination.total
            hasMoreFavourites = response.pagination.hasNext
            favouritePage = page
        } catch {
            favouriteErrorMessage = reset ? "Failed to load favourites" : "Failed to load more favourites"
        }
    }
}
