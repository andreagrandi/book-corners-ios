//
//  PushNotificationModels.swift
//  BookCorners
//

import Foundation

nonisolated enum APNsEnvironment: String, Codable, Equatable {
    case sandbox
    case production

    static var current: APNsEnvironment {
        #if DEBUG
            .sandbox
        #else
            .production
        #endif
    }
}

nonisolated struct DeviceTokenRegistrationRequest: Encodable {
    let token: String
    let environment: APNsEnvironment
}

nonisolated struct DeviceTokenRegistrationResponse: Codable, Equatable {
    let token: String
    let environment: APNsEnvironment
    let isActive: Bool
}

nonisolated enum PushNotificationType: String, Codable, Equatable {
    case librarySubmitted = "library.submitted"
    case libraryUpdated = "library.updated"
    case reportSubmitted = "report.submitted"
    case photoSubmitted = "photo.submitted"
    case libraryApproved = "library.approved"
    case libraryRejected = "library.rejected"
}

nonisolated enum AdminNotificationRoute: String, Hashable, Identifiable {
    case libraryQueue
    case photoQueue
    case reportQueue

    var id: String {
        rawValue
    }
}

nonisolated struct AdminNotificationRouteRequest: Equatable, Identifiable {
    let id: UUID
    let route: AdminNotificationRoute

    init(id: UUID = UUID(), route: AdminNotificationRoute) {
        self.id = id
        self.route = route
    }
}

nonisolated struct PushNotificationPayload: Equatable {
    let type: PushNotificationType
    let libraryID: Int?
    let reportID: Int?
    let photoID: Int?

    var adminRoute: AdminNotificationRoute? {
        switch type {
        case .librarySubmitted, .libraryUpdated:
            .libraryQueue
        case .photoSubmitted:
            .photoQueue
        case .reportSubmitted:
            .reportQueue
        case .libraryApproved, .libraryRejected:
            nil
        }
    }

    var isContributorEvent: Bool {
        switch type {
        case .libraryApproved, .libraryRejected:
            true
        case .librarySubmitted, .libraryUpdated, .photoSubmitted, .reportSubmitted:
            false
        }
    }

    init(
        type: PushNotificationType,
        libraryID: Int? = nil,
        reportID: Int? = nil,
        photoID: Int? = nil,
    ) {
        self.type = type
        self.libraryID = libraryID
        self.reportID = reportID
        self.photoID = photoID
    }

    init?(userInfo: [AnyHashable: Any]) {
        guard let rootPayload = Self.stringKeyedDictionary(from: userInfo) else {
            return nil
        }
        let dataPayload = Self.stringKeyedDictionary(from: rootPayload["data"])
        let payload = dataPayload ?? rootPayload

        guard
            let rawType = payload["type"] as? String,
            let type = PushNotificationType(rawValue: rawType)
        else {
            return nil
        }

        self.type = type
        libraryID = Self.intValue(from: payload["library_id"])
        reportID = Self.intValue(from: payload["report_id"])
        photoID = Self.intValue(from: payload["photo_id"])
    }

    private static func stringKeyedDictionary(from value: Any?) -> [String: Any]? {
        if let dictionary = value as? [String: Any] {
            return dictionary
        }

        if let dictionary = value as? [AnyHashable: Any] {
            return dictionary.reduce(into: [String: Any]()) { result, element in
                result[String(describing: element.key)] = element.value
            }
        }

        if let jsonString = value as? String,
           let data = jsonString.data(using: .utf8),
           let object = try? JSONSerialization.jsonObject(with: data),
           let dictionary = object as? [String: Any]
        {
            return dictionary
        }

        return nil
    }

    private static func intValue(from value: Any?) -> Int? {
        if let value = value as? Int {
            return value
        }

        if let value = value as? NSNumber {
            return value.intValue
        }

        if let value = value as? String {
            return Int(value)
        }

        return nil
    }
}
