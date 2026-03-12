//
//  MultipartFormData.swift
//  BookCorners
//
//  Created by Andrea Grandi on 11/03/26.
//

import Foundation

struct MultipartFormData {
    private let boundary: String
    private var body = Data()

    init() {
        boundary = UUID().uuidString
    }

    var contentType: String {
        "multipart/form-data; boundary=\(boundary)"
    }

    mutating func addField(name: String, value: String) {
        body.append(Data("--\(boundary)\r\nContent-Disposition: form-data; name=\"\(name)\"\r\n\r\n\(value)\r\n".utf8))
    }

    mutating func addFile(name: String, fileName: String, mimeType: String, data: Data) {
        let header = "--\(boundary)\r\n"
            + "Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n"
            + "Content-Type: \(mimeType)\r\n"
            + "\r\n"
        body.append(Data(header.utf8))
        body.append(data)
        body.append(Data("\r\n".utf8))
    }

    func encode() -> Data {
        let bodyCopy = body
        return bodyCopy + Data("--\(boundary)--\r\n".utf8)
    }
}
