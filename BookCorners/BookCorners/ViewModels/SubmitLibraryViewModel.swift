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
                photoData = data
                if let uiImage = UIImage(data: data) {
                    photoThumbnail = Image(uiImage: uiImage)
                }
                // Extract EXIF coordinates
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
            guard let placemark = mapItems.first?.placemark else { return }

            if let street = placemark.thoroughfare {
                let number = placemark.subThoroughfare ?? ""
                address = number.isEmpty ? street : "\(street) \(number)"
            }
            if let placemarkCity = placemark.locality {
                city = placemarkCity
            }
            if let countryCode = placemark.countryCode {
                country = countryCode
            }
            if let placemarkPostalCode = placemark.postalCode {
                postalCode = placemarkPostalCode
            }
        } catch {
            // Reverse geocoding failed — user can fill address manually
        }
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
