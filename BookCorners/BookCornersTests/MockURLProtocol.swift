//
//  MockURLProtocol.swift
//  BookCornersTests
//
//  Created by Andrea Grandi on 11/03/26.
//

import Foundation

class MockURLProtocol: URLProtocol {
    /// Tests set this to control what response comes back
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    /// "Can I handle this request?" — always yes
    override class func canInit(with _: URLRequest) -> Bool {
        true
    }

    /// "Should I modify the request?" — no, pass it through
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    /// "Execute the request" — call requestHandler, feed result back
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            // No handler set — this is a test bug
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }

        do {
            let (response, data) = try handler(request)
            // feed response and data back to URLSession...
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            // tell client about the error...
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    /// "Cancel the request" — nothing to do
    override func stopLoading() {}

    static var mockSession: URLSession {
        // create ephemeral config
        let config = URLSessionConfiguration.ephemeral
        // set protocolClasses
        config.protocolClasses = [MockURLProtocol.self]
        // return URLSession with that config
        return URLSession(configuration: config)
    }
}
