//
//  LocationService.swift
//  BookCorners
//
//  Created by Andrea Grandi on 15/03/26.
//

import CoreLocation

@Observable
class LocationService {
    private(set) var currentLocation: CLLocation?
    private var serviceSession: CLServiceSession?
    private var updatesTask: Task<Void, Never>?

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
