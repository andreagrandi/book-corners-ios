//
//  SubmitLibraryViewModel.swift
//  BookCorners
//

import CoreLocation
import Foundation
import MapKit
import Observation
import PhotosUI
import SwiftUI

@Observable
class SubmitLibraryViewModel {
    private let apiClient: APIClientProtocol

    // MARK: - Photo state

    var selectedPhotoItem: PhotosPickerItem?
    var photoData: Data?
    var photoThumbnail: Image?

    // MARK: - Location

    var latitude: Double?
    var longitude: Double?
    var hasCoordinatesFromEXIF = false

    var hasCoordinates: Bool {
        latitude != nil && longitude != nil
    }

    // MARK: - Required address fields

    var address: String = ""
    var city: String = ""
    var country: String = ""

    // MARK: - Optional fields

    var name: String = ""
    var libraryDescription: String = ""
    var postalCode: String = ""
    var wheelchairAccessible: String = ""
    var capacity: Int?
    var isIndoor: Bool?
    var isLit: Bool?
    var website: String = ""
    var contact: String = ""
    var operatorName: String = ""
    var brand: String = ""

    // MARK: - Submission state

    var isSubmitting = false
    var errorMessage: String?
    var submittedLibrary: Library?

    // MARK: - Address autocomplete

    var addressSuggestions: [PhotonFeature] = []
    private var autocompleteTask: Task<Void, Never>?
    private let photonService = PhotonService()

    // MARK: - Validation

    var isValid: Bool {
        photoData != nil
            && !address.isEmpty
            && !city.isEmpty
            && !country.isEmpty
            && hasCoordinates
    }

    init(client: any APIClientProtocol) {
        apiClient = client
    }

    // MARK: - Photo loading

    func loadPhoto() async {
        guard let item = selectedPhotoItem else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                if let uiImage = UIImage(data: data) {
                    photoData = uiImage.jpegData(compressionQuality: 0.85)
                    photoThumbnail = Image(uiImage: uiImage)
                }
                // Extract EXIF coordinates from original data (before JPEG conversion strips it)
                if let coordinate = EXIFReader.extractCoordinates(from: data) {
                    latitude = coordinate.latitude
                    longitude = coordinate.longitude
                    hasCoordinatesFromEXIF = true
                    await reverseGeocode(coordinate: coordinate)
                }
            }
        } catch {
            errorMessage = "Failed to load photo"
        }
    }

    func setPhoto(image: UIImage) {
        photoData = image.jpegData(compressionQuality: 0.85)
        photoThumbnail = Image(uiImage: image)
        selectedPhotoItem = nil
    }

    // MARK: - Address autocomplete

    func searchAddress(_ query: String) {
        guard !hasCoordinatesFromEXIF else { return }

        autocompleteTask?.cancel()
        autocompleteTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(500))
                try Task.checkCancellation()
                let results = try await photonService.search(query: query)
                addressSuggestions = results
            } catch is CancellationError {
                // Debounce cancelled
            } catch {
                addressSuggestions = []
            }
        }
    }

    func selectSuggestion(_ feature: PhotonFeature) {
        let props = feature.properties
        var streetAddress = ""
        if let street = props.street {
            if let number = props.housenumber {
                streetAddress = "\(street) \(number)"
            } else {
                streetAddress = street
            }
        }
        address = streetAddress
        city = props.city ?? ""
        country = props.countrycode ?? ""
        postalCode = props.postcode ?? ""
        latitude = feature.coordinate.latitude
        longitude = feature.coordinate.longitude
        addressSuggestions = []
    }

    // MARK: - Reverse geocoding

    func reverseGeocode(coordinate: CLLocationCoordinate2D) async {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let request = MKReverseGeocodingRequest(location: location) else { return }

        do {
            let mapItems = try await request.mapItems
            guard let mapItem = mapItems.first else { return }

            // Use addressRepresentations for city (iOS 26 non-deprecated API)
            if let cityName = mapItem.addressRepresentations?.cityName {
                city = cityName
            }

            // MKAddress only has fullAddress/shortAddress — no individual fields for
            // street, countryCode, postalCode. Use placemark until Apple provides
            // proper replacements. TODO: update when iOS 27 adds individual fields.
            let components = extractAddressComponents(from: mapItem)
            if let street = components.street { address = street }
            if let countryCode = components.countryCode { country = countryCode }
            if let postal = components.postalCode { postalCode = postal }
        } catch {
            // Reverse geocoding failed — user can fill address manually
        }
    }

    @available(iOS, deprecated: 26.0, message: "Remove when Apple provides individual address fields on MKMapItem")
    private func extractAddressComponents(from mapItem: MKMapItem) -> (street: String?, countryCode: String?, postalCode: String?) {
        let pm = mapItem.placemark
        var street: String?
        if let thoroughfare = pm.thoroughfare {
            let number = pm.subThoroughfare ?? ""
            street = number.isEmpty ? thoroughfare : "\(thoroughfare) \(number)"
        }
        return (street: street, countryCode: pm.countryCode, postalCode: pm.postalCode)
    }

    // MARK: - Submit

    func submit() async {
        guard isValid, let photoData, let latitude, let longitude else { return }

        isSubmitting = true
        errorMessage = nil

        do {
            let library = try await apiClient.submitLibrary(
                address: address,
                city: city,
                country: country,
                latitude: latitude,
                longitude: longitude,
                photo: photoData,
                name: name.isEmpty ? nil : name,
                description: libraryDescription.isEmpty ? nil : libraryDescription,
                postalCode: postalCode.isEmpty ? nil : postalCode,
                wheelchairAccessible: wheelchairAccessible.isEmpty ? nil : wheelchairAccessible,
                capacity: capacity,
                isIndoor: isIndoor,
                isLit: isLit,
                website: website.isEmpty ? nil : website,
                contact: contact.isEmpty ? nil : contact,
                operatorName: operatorName.isEmpty ? nil : operatorName,
                brand: brand.isEmpty ? nil : brand,
            )
            submittedLibrary = library
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }

    func reset() {
        selectedPhotoItem = nil
        photoData = nil
        photoThumbnail = nil
        latitude = nil
        longitude = nil
        hasCoordinatesFromEXIF = false
        address = ""
        city = ""
        country = ""
        name = ""
        libraryDescription = ""
        postalCode = ""
        wheelchairAccessible = ""
        capacity = nil
        isIndoor = nil
        isLit = nil
        website = ""
        contact = ""
        operatorName = ""
        brand = ""
        isSubmitting = false
        errorMessage = nil
        submittedLibrary = nil
        addressSuggestions = []
        autocompleteTask?.cancel()
    }
}
