//
//  APIClient+Devices.swift
//  BookCorners
//

import Foundation

extension APIClient {
    func registerDeviceToken(
        token: String,
        environment: APNsEnvironment,
    ) async throws -> DeviceTokenRegistrationResponse {
        try await request(
            path: "auth/devices",
            method: "POST",
            body: DeviceTokenRegistrationRequest(token: token, environment: environment),
        )
    }

    func unregisterDeviceToken(token: String) async throws {
        try await requestVoid(path: "auth/devices/\(token)", method: "DELETE")
    }
}
