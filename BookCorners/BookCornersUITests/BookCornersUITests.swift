//
//  BookCornersUITests.swift
//  BookCornersUITests
//
//  Created by Andrea Grandi on 10/03/26.
//

import Network
import XCTest

final class BookCornersUITests: XCTestCase {
    /// Generous because CI runners are slow; predicate waits return as soon as
    /// the condition is met, so passing runs are unaffected.
    private let uiTimeout: TimeInterval = 60

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
        guard waitForHittable(adminTab, timeout: uiTimeout) else {
            XCTFail("Admin tab did not become available. Requests: \(server.receivedRequestLines)")
            return
        }
        adminTab.tap()
        let libraryApprovalsButton = app.buttons["admin-library-approvals"]
        guard waitForHittable(libraryApprovalsButton, timeout: uiTimeout) else {
            XCTFail("Library approvals did not load. Requests: \(server.receivedRequestLines)")
            return
        }
        libraryApprovalsButton.tap()

        let pendingLibrary = app.descendants(matching: .any)["library-moderation-florence-corner-books"]
        guard pendingLibrary.waitForExistence(timeout: uiTimeout) else {
            XCTFail("Pending library did not load. Requests: \(server.receivedRequestLines)")
            return
        }

        let approveButton = app.buttons["approve-library-florence-corner-books"]
        guard waitForHittable(approveButton, timeout: uiTimeout) else {
            XCTFail("Approve button did not become hittable. Requests: \(server.receivedRequestLines)")
            return
        }
        approveButton.tap()

        let confirmation = app.alerts["Approve Library?"]
        let confirmApproveButton = confirmation.buttons["Approve"]
        guard waitForHittable(confirmApproveButton, timeout: uiTimeout) else {
            XCTFail("Approval confirmation did not appear. Requests: \(server.receivedRequestLines)")
            return
        }
        confirmApproveButton.tap()

        let emptyState = app.descendants(matching: .any)["library-moderation-empty"]
        XCTAssertTrue(emptyState.waitForExistence(timeout: uiTimeout))
        XCTAssertFalse(pendingLibrary.exists)
        let summary = app.descendants(matching: .any)["library-moderation-summary"]
        XCTAssertTrue(waitForLabel(summary, containing: "0 pending", timeout: uiTimeout))

        let nearbyTab = app.tabBars.buttons["Nearby"]
        nearbyTab.tap()

        let moderationButton = app.buttons["nearby-moderation-button"]
        XCTAssertTrue(waitForValue(
            moderationButton,
            equalTo: "No pending moderation work",
            timeout: uiTimeout,
        ))
    }

    @MainActor
    func testStaffModerationIndicatorShowsPendingWorkAndOpensAdminDashboard() throws {
        let server = try AdminModerationMockServer()
        let port = try server.start()
        defer { server.stop() }

        let app = XCUIApplication()
        app.launchEnvironment["API_BASE_URL"] = "http://127.0.0.1:\(port)/api/v1/"
        app.launchEnvironment["UI_TEST_ACCESS_TOKEN"] = "staff-access-token"
        app.launchEnvironment["UI_TEST_REFRESH_TOKEN"] = "staff-refresh-token"
        app.launch()

        let moderationButton = app.buttons["nearby-moderation-button"]
        guard waitForValue(
            moderationButton,
            equalTo: "Pending moderation work",
            timeout: uiTimeout,
        ) else {
            XCTFail("Pending moderation indicator did not appear. Requests: \(server.receivedRequestLines)")
            return
        }

        let pendingIndicatorScreenshot = XCTAttachment(screenshot: app.screenshot())
        pendingIndicatorScreenshot.name = "Nearby pending moderation indicator"
        pendingIndicatorScreenshot.lifetime = .keepAlways
        add(pendingIndicatorScreenshot)

        moderationButton.tap()

        let adminTab = app.tabBars.buttons["Admin"]
        XCTAssertTrue(adminTab.isSelected)
        XCTAssertTrue(app.navigationBars["Admin Dashboard"].waitForExistence(timeout: uiTimeout))
    }

    @MainActor
    func testAdminDashboardPrioritizesModerationQueueAndKeepsLinksAccessible() throws {
        let server = try AdminModerationMockServer()
        let port = try server.start()
        defer { server.stop() }

        let app = XCUIApplication()
        app.launchEnvironment["API_BASE_URL"] = "http://127.0.0.1:\(port)/api/v1/"
        app.launchEnvironment["UI_TEST_ACCESS_TOKEN"] = "staff-access-token"
        app.launchEnvironment["UI_TEST_REFRESH_TOKEN"] = "staff-refresh-token"
        app.launch()

        let moderationButton = app.buttons["nearby-moderation-button"]
        guard waitForValue(
            moderationButton,
            equalTo: "Pending moderation work",
            timeout: uiTimeout,
        ) else {
            XCTFail("Pending moderation indicator did not appear. Requests: \(server.receivedRequestLines)")
            return
        }
        moderationButton.tap()

        let header = app.descendants(matching: .any)["admin-dashboard-header"]
        let moderationHeading = app.staticTexts["MODERATION QUEUE"]
        let lastModerationLink = app.buttons["admin-report-moderation"]
        let firstStatistic = app
            .descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", "Total Libraries,"))
            .firstMatch
        let lastStatistic = app
            .descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", "Open Reports,"))
            .firstMatch
        let systemStatusHeading = app.staticTexts["SYSTEM STATUS"]

        XCTAssertTrue(header.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(moderationHeading.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(lastModerationLink.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(firstStatistic.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(lastStatistic.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(systemStatusHeading.waitForExistence(timeout: uiTimeout))
        XCTAssertLessThan(header.frame.maxY, moderationHeading.frame.minY)
        XCTAssertLessThan(lastModerationLink.frame.maxY, firstStatistic.frame.minY)
        XCTAssertLessThan(lastStatistic.frame.maxY, systemStatusHeading.frame.minY)

        let dashboardScreenshot = XCTAttachment(screenshot: app.screenshot())
        dashboardScreenshot.name = "Admin Dashboard moderation queue first"
        dashboardScreenshot.lifetime = .keepAlways
        add(dashboardScreenshot)

        let destinations = [
            ("admin-library-approvals", "Library Approvals"),
            ("admin-photo-approvals", "Submitted Photos"),
            ("admin-report-moderation", "User Reports"),
        ]
        for (identifier, title) in destinations {
            let link = app.buttons[identifier]
            guard waitForHittable(link, timeout: uiTimeout) else {
                XCTFail("\(title) link did not become available. Requests: \(server.receivedRequestLines)")
                return
            }
            link.tap()

            let navigationBar = app.navigationBars[title]
            XCTAssertTrue(navigationBar.waitForExistence(timeout: uiTimeout))
            navigationBar.buttons.firstMatch.tap()
            XCTAssertTrue(app.navigationBars["Admin Dashboard"].waitForExistence(timeout: uiTimeout))
        }
    }

    @MainActor
    func testModerationIndicatorIsHiddenForNonStaffUser() throws {
        let server = try AdminModerationMockServer(isStaffUser: false)
        let port = try server.start()
        defer { server.stop() }

        let app = XCUIApplication()
        app.launchEnvironment["API_BASE_URL"] = "http://127.0.0.1:\(port)/api/v1/"
        app.launchEnvironment["UI_TEST_ACCESS_TOKEN"] = "user-access-token"
        app.launchEnvironment["UI_TEST_REFRESH_TOKEN"] = "user-refresh-token"
        app.launch()

        XCTAssertTrue(app.navigationBars["Nearby"].waitForExistence(timeout: uiTimeout))
        XCTAssertFalse(app.buttons["nearby-moderation-button"].exists)
        XCTAssertFalse(app.tabBars.buttons["Admin"].exists)
    }

    @MainActor
    func testModerationIndicatorIsHiddenForSignedOutUser() throws {
        let server = try AdminModerationMockServer()
        let port = try server.start()
        defer { server.stop() }

        let app = XCUIApplication()
        app.launchEnvironment["API_BASE_URL"] = "http://127.0.0.1:\(port)/api/v1/"
        app.launch()

        XCTAssertTrue(app.navigationBars["Nearby"].waitForExistence(timeout: uiTimeout))
        XCTAssertFalse(app.buttons["nearby-moderation-button"].exists)
        XCTAssertFalse(app.tabBars.buttons["Admin"].exists)
    }

    @MainActor
    func testModerationSummaryFailureDoesNotBlockAdminDashboard() throws {
        let server = try AdminModerationMockServer(summaryShouldFail: true)
        let port = try server.start()
        defer { server.stop() }

        let app = XCUIApplication()
        app.launchEnvironment["API_BASE_URL"] = "http://127.0.0.1:\(port)/api/v1/"
        app.launchEnvironment["UI_TEST_ACCESS_TOKEN"] = "staff-access-token"
        app.launchEnvironment["UI_TEST_REFRESH_TOKEN"] = "staff-refresh-token"
        app.launch()

        let moderationButton = app.buttons["nearby-moderation-button"]
        guard waitForValue(
            moderationButton,
            equalTo: "No pending moderation work",
            timeout: uiTimeout,
        ) else {
            XCTFail("Staff moderation button did not appear. Requests: \(server.receivedRequestLines)")
            return
        }

        moderationButton.tap()

        XCTAssertTrue(app.navigationBars["Admin Dashboard"].waitForExistence(timeout: uiTimeout))
        let header = app.descendants(matching: .any)["admin-dashboard-header"]
        let errorBanner = app.descendants(matching: .any)["admin-dashboard-error"]
        let moderationHeading = app.staticTexts["MODERATION QUEUE"]
        XCTAssertTrue(header.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(errorBanner.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(moderationHeading.waitForExistence(timeout: uiTimeout))
        XCTAssertLessThan(header.frame.maxY, errorBanner.frame.minY)
        XCTAssertLessThan(errorBanner.frame.maxY, moderationHeading.frame.minY)
    }

    @MainActor
    func testLibrarySubmissionExplainsRequiredPhoto() throws {
        let server = try AdminModerationMockServer()
        let port = try server.start()
        defer { server.stop() }

        let app = XCUIApplication()
        app.launchEnvironment["API_BASE_URL"] = "http://127.0.0.1:\(port)/api/v1/"
        app.launchEnvironment["UI_TEST_ACCESS_TOKEN"] = "staff-access-token"
        app.launchEnvironment["UI_TEST_REFRESH_TOKEN"] = "staff-refresh-token"
        app.launch()

        let submitTab = app.tabBars.buttons["Submit"]
        guard waitForHittable(submitTab, timeout: uiTimeout) else {
            XCTFail("Submit tab did not become available. Requests: \(server.receivedRequestLines)")
            return
        }
        submitTab.tap()

        XCTAssertTrue(app.staticTexts["Photo (required)"].waitForExistence(timeout: uiTimeout))

        let requirement = app.staticTexts["submit-library-photo-requirement"]
        XCTAssertTrue(requirement.waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(requirement.label, "A clear photo is required to submit a library.")

        let submitButton = app.buttons["submit-library-button"]
        for _ in 0 ..< 6 {
            if submitButton.exists {
                break
            }
            app.swipeUp()
        }
        XCTAssertTrue(submitButton.waitForExistence(timeout: uiTimeout))
        XCTAssertFalse(submitButton.isEnabled)
    }

    @MainActor
    func testRegistrationRequiresAgreementAndPresentsFullText() throws {
        let server = try AdminModerationMockServer()
        let port = try server.start()
        defer { server.stop() }

        let app = XCUIApplication()
        app.launchEnvironment["API_BASE_URL"] = "http://127.0.0.1:\(port)/api/v1/"
        app.launchEnvironment["CONTRIBUTOR_AGREEMENT_URL"] = "http://127.0.0.1:\(port)/contributor-agreement/1.0/en/"
        app.launch()

        let submitTab = app.tabBars.buttons["Submit"]
        guard waitForHittable(submitTab, timeout: uiTimeout) else {
            XCTFail("Submit tab did not become available. Requests: \(server.receivedRequestLines)")
            return
        }
        submitTab.tap()

        XCTAssertTrue(app.navigationBars["Login"].waitForExistence(timeout: uiTimeout))
        XCTAssertFalse(app.buttons["contributor-agreement-acceptance"].exists)
        XCTAssertEqual(app.buttons["social-google-button"].label, "Sign in with Google")

        let registerMode = app.segmentedControls.buttons["Register"]
        XCTAssertTrue(waitForHittable(registerMode, timeout: uiTimeout))
        registerMode.tap()

        let agreementControl = app.buttons["contributor-agreement-acceptance"]
        for _ in 0 ..< 4 where !agreementControl.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(agreementControl.waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(agreementControl.value as? String, "Not accepted")

        let appleButton = app.buttons["social-apple-button"]
        let googleButton = app.buttons["social-google-button"]
        for _ in 0 ..< 4 where !googleButton.isHittable {
            app.swipeUp()
        }
        XCTAssertEqual(appleButton.label, "Sign up with Apple")
        XCTAssertEqual(googleButton.label, "Sign up with Google")
        XCTAssertFalse(appleButton.isEnabled)
        XCTAssertFalse(googleButton.isEnabled)

        let readAgreementButton = app.buttons["read-contributor-agreement"]
        XCTAssertTrue(waitForHittable(readAgreementButton, timeout: uiTimeout))
        readAgreementButton.tap()

        XCTAssertTrue(app.navigationBars["Contributor Agreement"].waitForExistence(timeout: uiTimeout))
        let agreementHeading = app.webViews.staticTexts["Contributor Agreement v1.0"]
        XCTAssertTrue(agreementHeading.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(app.webViews.staticTexts["Your contributions and rights"].exists)
        app.navigationBars["Contributor Agreement"].buttons.firstMatch.tap()

        for _ in 0 ..< 4 where !agreementControl.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(waitForHittable(agreementControl, timeout: uiTimeout))
        agreementControl.tap()
        XCTAssertTrue(waitForValue(agreementControl, equalTo: "Accepted", timeout: uiTimeout))
        XCTAssertTrue(appleButton.isEnabled)
        XCTAssertTrue(googleButton.isEnabled)
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
    private func waitForLabel(_ element: XCUIElement, containing text: String, timeout: TimeInterval) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND label CONTAINS %@", text),
            object: element,
        )
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    @MainActor
    private func waitForValue(_ element: XCUIElement, equalTo text: String, timeout: TimeInterval) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND value == %@", text),
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
    private let isStaffUser: Bool
    private let summaryShouldFail: Bool
    private var isLibraryApproved = false
    private var requestLines: [String] = []

    init(
        isStaffUser: Bool = true,
        summaryShouldFail: Bool = false,
    ) throws {
        self.isStaffUser = isStaffUser
        self.summaryShouldFail = summaryShouldFail
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
        let contentType = request.contains("GET /contributor-agreement/")
            ? "text/html; charset=utf-8"
            : "application/json"
        let responseHeaders = [
            "HTTP/1.1 200 OK",
            "Content-Type: \(contentType)",
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

        if method == "GET", path == "/contributor-agreement/1.0/en/" {
            return """
            <!doctype html>
            <html lang="en">
            <head><meta name="viewport" content="width=device-width, initial-scale=1"></head>
            <body>
              <h1>Contributor Agreement v1.0</h1>
              <h2>Your contributions and rights</h2>
              <p>This full agreement explains how Book Corners can use and share contributed data and images.</p>
              <p>You confirm that you have the rights needed to contribute the material.</p>
            </body>
            </html>
            """
        }
        if method == "GET", path == "/api/v1/auth/me" {
            return """
            {"id":44,"username":"test-user","email":"test@example.invalid","is_social_only":false,"is_staff":\(isStaffUser)}
            """
        }
        if method == "GET", path == "/api/v1/libraries/moderation/summary" {
            if summaryShouldFail {
                return "{}"
            }
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
