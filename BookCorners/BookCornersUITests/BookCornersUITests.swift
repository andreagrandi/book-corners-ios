//
//  BookCornersUITests.swift
//  BookCornersUITests
//
//  Created by Andrea Grandi on 10/03/26.
//

import Network
import XCTest

final class BookCornersUITests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testApprovingLibraryRemovesItFromPendingQueueWhenRefreshReturnsStaleData() throws {
        let server = try AdminModerationMockServer()
        let port = try server.start()
        defer { server.stop() }

        let baseURL = "http://127.0.0.1:\(port)/api/v1/"

        let app = XCUIApplication()
        app.launchEnvironment["API_BASE_URL"] = baseURL
        app.launchEnvironment["UI_TEST_ACCESS_TOKEN"] = "staff-access-token"
        app.launchEnvironment["UI_TEST_REFRESH_TOKEN"] = "staff-refresh-token"
        app.launch()

        let adminTab = app.tabBars.buttons["Admin"]
        guard waitForHittable(adminTab, timeout: 10) else {
            XCTFail("Admin tab did not become available. Requests: \(server.receivedRequestLines)")
            return
        }
        adminTab.tap()
        let libraryApprovalsButton = app.buttons["admin-library-approvals"]
        guard waitForHittable(libraryApprovalsButton, timeout: 10) else {
            XCTFail("Library approvals did not load. Requests: \(server.receivedRequestLines)")
            return
        }
        libraryApprovalsButton.tap()

        let pendingLibrary = app.staticTexts["Corner Books"]
        XCTAssertTrue(pendingLibrary.waitForExistence(timeout: 10))
        app.buttons["Approve"].firstMatch.tap()

        let confirmation = app.alerts["Approve Library?"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
        confirmation.buttons["Approve"].tap()

        XCTAssertTrue(app.staticTexts["No Library Submissions"].waitForExistence(timeout: 10))
        XCTAssertFalse(pendingLibrary.exists)
        XCTAssertTrue(
            app.descendants(matching: .any)
                .matching(NSPredicate(format: "label CONTAINS %@", "0 pending"))
                .firstMatch
                .exists,
        )
    }

    @MainActor
    private func waitForHittable(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND hittable == true"),
            object: element,
        )
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    @MainActor
    func testLaunchPerformance() {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}

private final class AdminModerationMockServer: @unchecked Sendable {
    private let listener: NWListener
    private let queue = DispatchQueue(label: "AdminModerationMockServer")
    private let stateLock = NSLock()
    private var isLibraryApproved = false
    private var requestLines: [String] = []

    init() throws {
        listener = try NWListener(using: .tcp, on: .any)
    }

    func start() throws -> UInt16 {
        let ready = DispatchSemaphore(value: 0)
        listener.stateUpdateHandler = { state in
            switch state {
            case .ready, .failed:
                ready.signal()
            default:
                break
            }
        }
        listener.newConnectionHandler = { [weak self] connection in
            self?.accept(connection)
        }
        listener.start(queue: queue)

        guard ready.wait(timeout: .now() + 3) == .success,
              let port = listener.port?.rawValue
        else {
            throw AdminModerationMockServerError.failedToStart
        }
        return port
    }

    func stop() {
        listener.cancel()
    }

    var receivedRequestLines: [String] {
        stateLock.withLock { requestLines }
    }

    private func accept(_ connection: NWConnection) {
        connection.start(queue: queue)
        receiveRequest(on: connection, accumulatedData: Data())
    }

    private func receiveRequest(on connection: NWConnection, accumulatedData: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, _ in
            guard let self else {
                connection.cancel()
                return
            }

            var requestData = accumulatedData
            if let data {
                requestData.append(data)
            }

            if isComplete || isCompleteRequest(requestData) {
                sendResponse(for: requestData, on: connection)
            } else {
                receiveRequest(on: connection, accumulatedData: requestData)
            }
        }
    }

    private func isCompleteRequest(_ data: Data) -> Bool {
        let headerSeparator = Data("\r\n\r\n".utf8)
        guard let separatorRange = data.range(of: headerSeparator),
              let headers = String(data: data[..<separatorRange.lowerBound], encoding: .utf8)
        else {
            return false
        }

        let contentLength = headers
            .components(separatedBy: "\r\n")
            .first { $0.lowercased().hasPrefix("content-length:") }
            .flatMap { Int($0.split(separator: ":", maxSplits: 1)[1].trimmingCharacters(in: .whitespaces)) } ?? 0
        return data.count >= separatorRange.upperBound + contentLength
    }

    private func sendResponse(for requestData: Data, on connection: NWConnection) {
        let request = String(data: requestData, encoding: .utf8) ?? ""
        let responseBody = responseBody(for: request)
        let responseData = Data(responseBody.utf8)
        let responseHeaders = [
            "HTTP/1.1 200 OK",
            "Content-Type: application/json",
            "Content-Length: \(responseData.count)",
            "Cache-Control: no-store",
            "Connection: close",
            "",
            "",
        ].joined(separator: "\r\n")
        var payload = Data(responseHeaders.utf8)
        payload.append(responseData)

        connection.send(
            content: payload,
            contentContext: .finalMessage,
            isComplete: true,
            completion: .contentProcessed { _ in
                connection.cancel()
            },
        )
    }

    private func responseBody(for request: String) -> String {
        let requestLine = request.components(separatedBy: "\r\n").first ?? ""
        stateLock.withLock {
            requestLines.append(requestLine)
        }
        let requestParts = requestLine.split(separator: " ")
        let method = requestParts.first.map(String.init) ?? ""
        let target = requestParts.count > 1 ? String(requestParts[1]) : ""
        let path = target.split(separator: "?", maxSplits: 1).first.map(String.init) ?? ""

        if method == "GET", path == "/api/v1/auth/me" {
            return """
            {"id":44,"username":"moderator","email":"moderator@example.invalid","is_social_only":false,"is_staff":true}
            """
        }
        if method == "GET", path == "/api/v1/libraries/moderation/summary" {
            let pendingCount = libraryIsApproved ? 0 : 1
            return """
            {"pending_libraries_count":\(pendingCount),"open_reports_count":0,"pending_photos_count":0,"total_pending":\(pendingCount),"total_libraries":350,"total_users":128}
            """
        }
        if method == "PATCH", path == "/api/v1/libraries/moderation/florence-corner-books" {
            stateLock.withLock {
                isLibraryApproved = true
            }
            return moderationLibraryJSON(status: "approved")
        }
        if method == "GET", path == "/api/v1/libraries/moderation" {
            return """
            {"items":[\(moderationLibraryJSON(status: "pending"))],"pagination":{"page":1,"page_size":20,"total":1,"total_pages":1,"has_next":false,"has_previous":false}}
            """
        }
        if method == "GET", path == "/api/v1/libraries/moderation/florence-corner-books" {
            return moderationLibraryJSON(status: libraryIsApproved ? "approved" : "pending")
        }
        if method == "GET", path == "/api/v1/libraries/" {
            return """
            {"items":[],"pagination":{"page":1,"page_size":20,"total":0,"total_pages":0,"has_next":false,"has_previous":false}}
            """
        }
        return "{}"
    }

    private var libraryIsApproved: Bool {
        stateLock.withLock { isLibraryApproved }
    }

    private func moderationLibraryJSON(status: String) -> String {
        """
        {"id":42,"slug":"florence-corner-books","name":"Corner Books","description":"A book-sharing library near the park entrance.","photo_url":"","thumbnail_url":"","lat":43.7696,"lng":11.2558,"address":"Via Rosina 15","city":"Florence","country":"IT","postal_code":"50123","wheelchair_accessible":"","capacity":null,"is_indoor":null,"is_lit":null,"website":"","contact":"","source":"user","operator":"Book Club Florence","brand":"","created_at":"2026-06-15T14:30:00Z","is_favourited":false,"status":"\(status)","rejection_reason":"","created_by":{"id":1,"username":"janedoe"}}
        """
    }
}

private enum AdminModerationMockServerError: Error {
    case failedToStart
}
