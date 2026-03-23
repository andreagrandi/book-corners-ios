//
//  ReportViewModel.swift
//  BookCorners
//
//  Created by Andrea Grandi on 23/03/26.
//

import Foundation
import Observation
import PhotosUI
import SwiftUI

@Observable
class ReportViewModel {
    private let apiClient: APIClientProtocol
    private let librarySlug: String

    var reason: ReportReason = .damaged
    var details: String = ""
    var photoData: Data?
    var selectedPhotoItem: PhotosPickerItem?

    var isSubmitting = false
    var errorMessage: String?
    var didSubmitSuccessfully = false

    init(apiClient: any APIClientProtocol, librarySlug: String) {
        self.apiClient = apiClient
        self.librarySlug = librarySlug
    }

    func loadPhoto() async {
        guard let item = selectedPhotoItem else { return }
        photoData = try? await item.loadTransferable(type: Data.self)
    }

    func submit() async {
        isSubmitting = true
        errorMessage = nil
        do {
            _ = try await apiClient.reportLibrary(
                slug: librarySlug,
                reason: reason.rawValue,
                details: details.isEmpty ? nil : details,
                photo: photoData,
            )
            didSubmitSuccessfully = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}
