//
//  ContributionCenterView.swift
//  BookCorners
//

import SwiftUI

struct ContributionCenterView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.apiClient) private var apiClient

    @State private var viewModel: ContributionCenterViewModel?

    private var summaryColumns: [GridItem] {
        let columnCount = horizontalSizeClass == .regular ? 3 : 3
        return Array(
            repeating: GridItem(.flexible(), spacing: 12),
            count: columnCount,
        )
    }

    var body: some View {
        ScrollView {
            if let viewModel {
                content(for: viewModel)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 320)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Contribution Center")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel == nil {
                viewModel = ContributionCenterViewModel(client: apiClient)
            }
            await viewModel?.loadInitialIfNeeded()
        }
        .refreshable {
            await viewModel?.refresh()
        }
    }

    private func content(for viewModel: ContributionCenterViewModel) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            ContributionCenterHeader()

            LazyVGrid(columns: summaryColumns, spacing: 12) {
                ForEach(summaryItems(for: viewModel)) { item in
                    ContributionSummaryCard(item: item)
                }
            }

            librarySubmissionsSection(for: viewModel)
            reportsSection(for: viewModel)
            photosSection(for: viewModel)
            favouritesSection(for: viewModel)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
    }

    private func summaryItems(for viewModel: ContributionCenterViewModel) -> [ContributionSummaryItem] {
        [
            ContributionSummaryItem(
                title: "Library submissions",
                value: formattedCount(viewModel.librarySubmissionCount),
                systemImage: "books.vertical",
                tint: .blue,
            ),
            ContributionSummaryItem(
                title: "Reports",
                value: formattedCount(viewModel.reportCount),
                systemImage: "flag",
                tint: .red,
            ),
            ContributionSummaryItem(
                title: "Community photos",
                value: formattedCount(viewModel.photoCount),
                systemImage: "photo.on.rectangle",
                tint: .purple,
            ),
        ]
    }

    private func formattedCount(_ value: Int?) -> String {
        guard let value else { return "—" }
        return value.formatted()
    }

    private func librarySubmissionsSection(for viewModel: ContributionCenterViewModel) -> some View {
        ContributionCenterSection(
            title: "My library submissions",
            subtitle: "Libraries you added, with their current moderation status.",
        ) {
            ContributionSectionStateView(
                isLoading: viewModel.isLoadingLibraries,
                isEmpty: viewModel.librarySubmissions.isEmpty,
                errorMessage: viewModel.libraryErrorMessage,
                emptyTitle: "No Library Submissions",
                emptyMessage: "Libraries you submit will appear here after they are sent to moderation.",
                emptyIcon: "books.vertical",
                retryAction: {
                    Task {
                        await viewModel.retryLibrarySubmissions()
                    }
                },
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    if let errorMessage = viewModel.libraryErrorMessage {
                        ContributionInlineErrorBanner(message: errorMessage)
                    }

                    librarySubmissionRows(viewModel.librarySubmissions)

                    if viewModel.hasMoreLibraries {
                        ContributionLoadMoreButton(
                            title: "Load more submissions",
                            isLoading: viewModel.isLoadingMoreLibraries,
                            action: {
                                Task {
                                    await viewModel.loadMoreLibrarySubmissions()
                                }
                            },
                        )
                    }
                }
            }
        }
    }

    private func reportsSection(for viewModel: ContributionCenterViewModel) -> some View {
        ContributionCenterSection(
            title: "My reports",
            subtitle: "Issues you reported and whether they are open, resolved, or dismissed.",
        ) {
            ContributionSectionStateView(
                isLoading: viewModel.isLoadingReports,
                isEmpty: viewModel.reports.isEmpty,
                errorMessage: viewModel.reportErrorMessage,
                emptyTitle: "No Reports",
                emptyMessage: "Reports you send for libraries will appear here.",
                emptyIcon: "flag",
                retryAction: {
                    Task {
                        await viewModel.retryReports()
                    }
                },
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    if let errorMessage = viewModel.reportErrorMessage {
                        ContributionInlineErrorBanner(message: errorMessage)
                    }

                    reportRows(viewModel.reports)

                    if viewModel.hasMoreReports {
                        ContributionLoadMoreButton(
                            title: "Load more reports",
                            isLoading: viewModel.isLoadingMoreReports,
                            action: {
                                Task {
                                    await viewModel.loadMoreReports()
                                }
                            },
                        )
                    }
                }
            }
        }
    }

    private func photosSection(for viewModel: ContributionCenterViewModel) -> some View {
        ContributionCenterSection(
            title: "My community photos",
            subtitle: "Photos you shared for existing libraries and their review status.",
        ) {
            ContributionSectionStateView(
                isLoading: viewModel.isLoadingPhotos,
                isEmpty: viewModel.photos.isEmpty,
                errorMessage: viewModel.photoErrorMessage,
                emptyTitle: "No Community Photos",
                emptyMessage: "Photos you add to libraries will appear here while they are reviewed.",
                emptyIcon: "photo.on.rectangle",
                retryAction: {
                    Task {
                        await viewModel.retryPhotos()
                    }
                },
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    if let errorMessage = viewModel.photoErrorMessage {
                        ContributionInlineErrorBanner(message: errorMessage)
                    }

                    photoRows(viewModel.photos)

                    if viewModel.hasMorePhotos {
                        ContributionLoadMoreButton(
                            title: "Load more photos",
                            isLoading: viewModel.isLoadingMorePhotos,
                            action: {
                                Task {
                                    await viewModel.loadMorePhotos()
                                }
                            },
                        )
                    }
                }
            }
        }
    }

    private func favouritesSection(for viewModel: ContributionCenterViewModel) -> some View {
        ContributionCenterSection(
            title: "My favourites",
            subtitle: "Book-sharing libraries you saved for later.",
        ) {
            ContributionSectionStateView(
                isLoading: viewModel.isLoadingFavourites,
                isEmpty: viewModel.favourites.isEmpty,
                errorMessage: viewModel.favouriteErrorMessage,
                emptyTitle: "No Favourites Yet",
                emptyMessage: "Libraries you favourite will appear here.",
                emptyIcon: "heart",
                retryAction: {
                    Task {
                        await viewModel.retryFavourites()
                    }
                },
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    if let errorMessage = viewModel.favouriteErrorMessage {
                        ContributionInlineErrorBanner(message: errorMessage)
                    }

                    favouriteRows(viewModel.favourites)

                    if viewModel.hasMoreFavourites {
                        ContributionLoadMoreButton(
                            title: "Load more favourites",
                            isLoading: viewModel.isLoadingMoreFavourites,
                            action: {
                                Task {
                                    await viewModel.loadMoreFavourites()
                                }
                            },
                        )
                    }
                }
            }
        }
    }

    private func librarySubmissionRows(_ libraries: [ContributionLibrary]) -> some View {
        VStack(spacing: 0) {
            ForEach(libraries) { library in
                librarySubmissionRow(library)

                if library.id != libraries.last?.id {
                    Divider()
                        .padding(.leading, 92)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16, style: .continuous))
        .clipShape(.rect(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private func librarySubmissionRow(_ library: ContributionLibrary) -> some View {
        if library.status == .approved {
            NavigationLink {
                LibraryDetailLoaderView(slug: library.slug)
            } label: {
                LibrarySubmissionRow(library: library, showsNavigation: true)
            }
            .buttonStyle(.plain)
        } else {
            LibrarySubmissionRow(library: library, showsNavigation: false)
        }
    }

    private func reportRows(_ reports: [ContributionReport]) -> some View {
        VStack(spacing: 0) {
            ForEach(reports) { report in
                reportRow(report)

                if report.id != reports.last?.id {
                    Divider()
                        .padding(.leading, 92)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16, style: .continuous))
        .clipShape(.rect(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private func reportRow(_ report: ContributionReport) -> some View {
        if report.library.status == .approved {
            NavigationLink {
                LibraryDetailLoaderView(slug: report.library.slug)
            } label: {
                ReportContributionRow(report: report, showsNavigation: true)
            }
            .buttonStyle(.plain)
        } else {
            ReportContributionRow(report: report, showsNavigation: false)
        }
    }

    private func photoRows(_ photos: [ContributionPhoto]) -> some View {
        VStack(spacing: 0) {
            ForEach(photos) { photo in
                photoRow(photo)

                if photo.id != photos.last?.id {
                    Divider()
                        .padding(.leading, 92)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16, style: .continuous))
        .clipShape(.rect(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private func photoRow(_ photo: ContributionPhoto) -> some View {
        if photo.library.status == .approved {
            NavigationLink {
                LibraryDetailLoaderView(slug: photo.library.slug)
            } label: {
                PhotoContributionRow(photo: photo, showsNavigation: true)
            }
            .buttonStyle(.plain)
        } else {
            PhotoContributionRow(photo: photo, showsNavigation: false)
        }
    }

    private func favouriteRows(_ favourites: [Library]) -> some View {
        VStack(spacing: 0) {
            ForEach(favourites) { library in
                NavigationLink {
                    LibraryDetailView(library: library)
                } label: {
                    FavouriteContributionRow(library: library)
                }
                .buttonStyle(.plain)

                if library.id != favourites.last?.id {
                    Divider()
                        .padding(.leading, 92)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16, style: .continuous))
        .clipShape(.rect(cornerRadius: 16, style: .continuous))
    }
}

private struct ContributionCenterHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Contribution center")
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)

            Text("Track every library, report, and photo you have sent to moderation.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct ContributionSummaryItem: Identifiable {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var id: String {
        title
    }
}

private struct ContributionSummaryCard: View {
    let item: ContributionSummaryItem

    @ScaledMetric(relativeTo: .headline) private var iconContainerSize = 36.0
    @ScaledMetric(relativeTo: .headline) private var iconSize = 20.0

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: item.systemImage)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(item.tint)
                .frame(width: iconContainerSize, height: iconContainerSize)
                .background(item.tint.opacity(0.12), in: .rect(cornerRadius: 10, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.value)
                    .font(.title.bold())
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.7)

                Text(item.title)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title), \(item.value)")
    }
}

private struct ContributionCenterSection<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 4)
            .accessibilityElement(children: .combine)

            content
        }
    }
}

private struct ContributionSectionStateView<Content: View>: View {
    let isLoading: Bool
    let isEmpty: Bool
    let errorMessage: String?
    let emptyTitle: String
    let emptyMessage: String
    let emptyIcon: String
    let retryAction: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        if isLoading, isEmpty {
            ContributionStateCard {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            }
        } else if let errorMessage, isEmpty {
            ContributionStateCard {
                ErrorView(message: errorMessage, retryAction: retryAction)
            }
        } else if isEmpty {
            ContributionStateCard {
                EmptyStateView(message: emptyMessage, title: emptyTitle, icon: emptyIcon)
                    .padding(.vertical, 16)
            }
        } else {
            content
        }
    }
}

private struct ContributionStateCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16, style: .continuous))
    }
}

private struct ContributionInlineErrorBanner: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.orange)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.orange.opacity(0.12), in: .rect(cornerRadius: 12, style: .continuous))
            .accessibilityElement(children: .combine)
    }
}

private struct ContributionLoadMoreButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        if isLoading {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        } else {
            Button(title, action: action)
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
        }
    }
}

private struct LibrarySubmissionRow: View {
    let library: ContributionLibrary
    let showsNavigation: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ContributionThumbnail(url: library.fullThumbnailUrl, systemImage: "books.vertical", size: 64)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(library.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 8)

                    ModerationStatusChip(status: library.status)
                }

                Text(locationText(city: library.city, country: library.country))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if library.status == .rejected, !library.rejectionReason.isEmpty {
                    Text(library.rejectionReason)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if showsNavigation {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 24)
                    .accessibilityHidden(true)
            }
        }
        .padding(16)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

private struct ReportContributionRow: View {
    let report: ContributionReport
    let showsNavigation: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ContributionIcon(systemImage: "flag", tint: report.status.tint)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(report.reason.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Spacer(minLength: 8)

                    ReportModerationStatusChip(status: report.status)
                }

                Text(report.library.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(report.createdAt, style: .date)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if showsNavigation {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 24)
                    .accessibilityHidden(true)
            }
        }
        .padding(16)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

private struct PhotoContributionRow: View {
    let photo: ContributionPhoto
    let showsNavigation: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ContributionThumbnail(url: photo.fullThumbnailUrl, systemImage: "photo", size: 64)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(photo.displayCaption)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 8)

                    PhotoModerationStatusChip(status: photo.status)
                }

                Text(photo.library.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(photo.createdAt, style: .date)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if showsNavigation {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 24)
                    .accessibilityHidden(true)
            }
        }
        .padding(16)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

private struct FavouriteContributionRow: View {
    let library: Library

    var body: some View {
        HStack(spacing: 8) {
            LibraryCardView(library: library, distance: nil)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(16)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

private struct ContributionThumbnail: View {
    let url: URL?
    let systemImage: String
    let size: CGFloat

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        placeholder
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(.rect(cornerRadius: 10, style: .continuous))
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.gray.opacity(0.12))

            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ContributionIcon: View {
    let systemImage: String
    let tint: Color

    @ScaledMetric(relativeTo: .body) private var iconContainerSize = 64.0
    @ScaledMetric(relativeTo: .body) private var iconSize = 24.0

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: iconSize, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: iconContainerSize, height: iconContainerSize)
            .background(tint.opacity(0.12), in: .rect(cornerRadius: 10, style: .continuous))
            .accessibilityHidden(true)
    }
}

private func locationText(city: String, country: String) -> String {
    [city, country]
        .filter { !$0.isEmpty }
        .joined(separator: ", ")
}

#Preview {
    NavigationStack {
        ContributionCenterView()
    }
    .environment(\.apiClient, APIClient())
}
