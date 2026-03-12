//
//  KeychainServiceTests.swift
//  BookCornersTests
//

@testable import BookCorners
import Foundation
import Testing

@Suite(.serialized) struct KeychainServiceTests {
    let keychain: KeychainService
    let testKey = "test_key"

    init() {
        // Use a unique service name per test run to avoid collisions
        keychain = KeychainService(service: "it.andreagrandi.BookCorners.tests.\(UUID())")
    }

    @Test func `save and load round trip`() throws {
        try keychain.saveString("my-secret-token", forKey: testKey)
        let loaded = try keychain.loadString(forKey: testKey)
        #expect(loaded == "my-secret-token")
    }

    @Test func `overwrite existing value`() throws {
        try keychain.saveString("first-value", forKey: testKey)
        try keychain.saveString("second-value", forKey: testKey)
        let loaded = try keychain.loadString(forKey: testKey)
        #expect(loaded == "second-value")
    }

    @Test func `load missing key returns nil`() throws {
        let loaded = try keychain.loadString(forKey: "nonexistent_key")
        #expect(loaded == nil)
    }

    @Test func `delete removes item`() throws {
        try keychain.saveString("to-be-deleted", forKey: testKey)
        try keychain.delete(forKey: testKey)
        let loaded = try keychain.loadString(forKey: testKey)
        #expect(loaded == nil)
    }

    @Test func `delete missing key does not throw`() throws {
        try keychain.delete(forKey: "nonexistent_key")
    }

    @Test func `save and load raw data`() throws {
        let data = Data([0x01, 0x02, 0x03, 0xFF])
        try keychain.save(data: data, forKey: testKey)
        let loaded = try keychain.load(forKey: testKey)
        #expect(loaded == data)
    }

    @Test func `independent keys do not interfere`() throws {
        try keychain.saveString("value-a", forKey: testKey)
        try keychain.saveString("value-b", forKey: "other_key")

        #expect(try keychain.loadString(forKey: testKey) == "value-a")
        #expect(try keychain.loadString(forKey: "other_key") == "value-b")
    }
}
