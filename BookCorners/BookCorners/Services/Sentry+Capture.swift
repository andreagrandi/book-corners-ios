//
//  Sentry+Capture.swift
//  BookCorners
//
//  Created by Andrea Grandi on 06/05/26.
//

import Foundation
import Sentry

enum ErrorReporter {
    static func capture(_ error: Error) {
        SentrySDK.capture(error: error)
    }

    static func capture(message: String) {
        SentrySDK.capture(message: message)
    }

    static func setUser(id: String) {
        let user = Sentry.User()
        user.userId = id
        SentrySDK.setUser(user)
    }

    static func clearUser() {
        SentrySDK.setUser(nil)
    }
}
