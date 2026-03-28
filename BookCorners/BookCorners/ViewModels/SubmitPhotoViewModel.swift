//
//  SubmitPhotoViewModel.swift
//  BookCorners
//

import Foundation
import Observation
import PhotosUI
import SwiftUI

@Observable
class SubmitPhotoViewModel {
    private let apiClient: APIClientProtocol
    private let librarySlug: String

    var selectedPhotoItem: PhotosPickerItem?
    var photoData: Data?
    var photoThumbnail: Image?
    var caption: String = ""

    var isSubmitting = false
    var errorMessage: String?
    var didSubmitSuccessfully = false

    var isValid: Bool {
        photoData != nil
    }

    init(apiClient: any APIClientProtocol, librarySlug: String) {
        self.apiClient = apiClient
        self.librarySlug = librarySlug
    }

    func loadPhoto() async {
        guard let item = selectedPhotoItem else { return }
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        guard let uiImage = UIImage(data: data) else { return }
        photoData = uiImage.jpegData(compressionQuality: 0.85)
        photoThumbnail = Image(uiImage: uiImage)
    }

    func setPhoto(image: UIImage) {
        photoData = image.jpegData(compressionQuality: 0.85)
        photoThumbnail = Image(uiImage: image)
        selectedPhotoItem = nil
    }

    func submit() async {
        guard let photoData else { return }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            _ = try await apiClient.addPhoto(
                slug: librarySlug,
                photo: photoData,
                caption: caption.isEmpty ? nil : caption,
            )
            didSubmitSuccessfully = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
