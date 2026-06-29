//
//  PushNotificationTests.swift
//  BookCornersTests
//

@testable import BookCorners
import Foundation
import Testing

@MainActor
struct PushNotificationTests {
    @Test func `device token data converts to lowercase hex`() {
        let token = PushNotificationService.hexString(from: Data([0x00, 0x0F, 0xAB, 0xFF]))

        #expect(token == "000fabff")
    }

    @Test func `library moderation payload routes to library queue`() throws {
        let payload = try #require(PushNotificationPayload(userInfo: [
            "aps": ["alert": ["title": "New library submission"]],
            "data": [
                "type": "library.submitted",
                "library_id": 42,
            ],
        ]))

        #expect(payload.type == .librarySubmitted)
        #expect(payload.libraryID == 42)
        #expect(payload.adminRoute == .libraryQueue)
    }

    @Test func `library update payload routes to library queue`() throws {
        let payload = try #require(PushNotificationPayload(userInfo: [
            "data": [
                "type": "library.updated",
                "library_id": "43",
            ],
        ]))

        #expect(payload.type == .libraryUpdated)
        #expect(payload.libraryID == 43)
        #expect(payload.adminRoute == .libraryQueue)
    }

    @Test func `photo moderation payload routes to photo queue`() throws {
        let payload = try #require(PushNotificationPayload(userInfo: [
            "data": [
                "type": "photo.submitted",
                "photo_id": 12,
                "library_id": 42,
            ],
        ]))

        #expect(payload.type == .photoSubmitted)
        #expect(payload.photoID == 12)
        #expect(payload.libraryID == 42)
        #expect(payload.adminRoute == .photoQueue)
    }

    @Test func `report moderation payload routes to report queue`() throws {
        let payload = try #require(PushNotificationPayload(userInfo: [
            "data": [
                "type": "report.submitted",
                "report_id": "7",
                "library_id": "42",
            ],
        ]))

        #expect(payload.type == .reportSubmitted)
        #expect(payload.reportID == 7)
        #expect(payload.libraryID == 42)
        #expect(payload.adminRoute == .reportQueue)
    }

    @Test func `contributor library status payloads do not route to admin`() throws {
        let approvedPayload = try #require(PushNotificationPayload(userInfo: [
            "data": [
                "type": "library.approved",
                "library_id": 42,
            ],
        ]))
        let rejectedPayload = try #require(PushNotificationPayload(userInfo: [
            "type": "library.rejected",
            "library_id": "43",
        ]))

        #expect(approvedPayload.isContributorEvent == true)
        #expect(approvedPayload.adminRoute == nil)
        #expect(rejectedPayload.isContributorEvent == true)
        #expect(rejectedPayload.adminRoute == nil)
    }
}
