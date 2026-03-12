//
//  MultipartFormDataTests.swift
//  BookCornersTests
//
//  Created by Andrea Grandi on 12/03/26.
//

@testable import BookCorners
import Foundation
import Testing

struct MultipartFormDataTests {
    @Test func `content type includes boundary`() {
        let multipart = MultipartFormData()
        #expect(multipart.contentType.starts(with: "multipart/form-data; boundary="))
    }

    @Test func `add field encodes correctly`() throws {
        var multipart = MultipartFormData()
        multipart.addField(name: "city", value: "Berlin")

        let encoded = String(data: multipart.encode(), encoding: .utf8)
        let body = try #require(encoded)

        #expect(body.contains("Content-Disposition: form-data; name=\"city\""))
        #expect(body.contains("Berlin"))
    }

    @Test func `add file encodes correctly`() throws {
        var multipart = MultipartFormData()
        let fileData = Data("fake image bytes".utf8)
        multipart.addFile(name: "photo", fileName: "photo.jpg", mimeType: "image/jpeg", data: fileData)

        let encoded = String(data: multipart.encode(), encoding: .utf8)
        let body = try #require(encoded)

        #expect(body.contains("Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpg\""))
        #expect(body.contains("Content-Type: image/jpeg"))
        #expect(body.contains("fake image bytes"))
    }

    @Test func `multiple fields and file encode correctly`() throws {
        var multipart = MultipartFormData()
        multipart.addField(name: "address", value: "Alexanderplatz 1")
        multipart.addField(name: "city", value: "Berlin")
        let fileData = Data("image data".utf8)
        multipart.addFile(name: "photo", fileName: "test.jpg", mimeType: "image/jpeg", data: fileData)

        let encoded = String(data: multipart.encode(), encoding: .utf8)
        let body = try #require(encoded)

        #expect(body.contains("name=\"address\""))
        #expect(body.contains("Alexanderplatz 1"))
        #expect(body.contains("name=\"city\""))
        #expect(body.contains("Berlin"))
        #expect(body.contains("filename=\"test.jpg\""))
    }

    @Test func `encode appends closing boundary`() throws {
        var multipart = MultipartFormData()
        multipart.addField(name: "test", value: "value")

        let encoded = String(data: multipart.encode(), encoding: .utf8)
        let body = try #require(encoded)

        // Closing boundary has -- suffix
        let boundary = multipart.contentType.replacingOccurrences(of: "multipart/form-data; boundary=", with: "")
        #expect(body.contains("--\(boundary)--"))
    }
}
