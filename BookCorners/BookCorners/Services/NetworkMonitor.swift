//
//  NetworkMonitor.swift
//  BookCorners
//

import Foundation
import Network
import Observation

@Observable
class NetworkMonitor {
    private(set) var isConnected = true
    private let monitor = NWPathMonitor()

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: DispatchQueue(label: "NetworkMonitor"))
    }
}
