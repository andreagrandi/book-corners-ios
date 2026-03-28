//
//  LocationService.swift
//  BookCorners
//
//  Created by Andrea Grandi on 15/03/26.
//

import CoreLocation

@Observable
class LocationService: NSObject, CLLocationManagerDelegate {
    private(set) var currentLocation: CLLocation?
    private(set) var authorizationStatus: CLAuthorizationStatus
    private var serviceSession: CLServiceSession?
    private var updatesTask: Task<Void, Never>?
    private let locationManager = CLLocationManager()

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    override init() {
        authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }

    func startMonitoring() {
        serviceSession = CLServiceSession(authorization: .whenInUse)
        updatesTask = Task {
            do {
                for try await update in CLLocationUpdate.liveUpdates() {
                    if let location = update.location { currentLocation = location }
                }
            } catch {
                // Location updates ended — permission revoked or system error
            }
        }
    }

    func stopMonitoring() {
        updatesTask?.cancel()
        updatesTask = nil
        serviceSession = nil
    }
}
