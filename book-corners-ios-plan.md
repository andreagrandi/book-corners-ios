# Book Corners iOS — Implementation Plan

> A SwiftUI iOS client for [Book Corners](https://www.bookcorners.org): a community-driven directory
> of little free libraries. Users can discover nearby book exchange spots, submit new ones,
> report issues, and contribute photos.

**Approach:** Interactive tutorial. Each step below will be expanded into detailed sub-steps
(with code guidance) when we begin working on it. Steps are ordered by dependency — each
builds on the previous.

**Teaching protocol:** This is a learning project. For every step:

1. **Before starting:** Explain the key concepts we're about to use. Use Python/Go analogies.
   Don't rush into code — make sure the learner understands *why* before *how*.
2. **During:** Explain new syntax and patterns as they appear. Don't gloss over anything
   that would be unfamiliar to a Python/Go developer.
3. **After completing a step:** Recap what was built and the concepts covered. Ask the
   learner questions to check understanding (e.g., "What would happen if...?", "How is
   this different from...?", "Can you explain what X does?"). Don't move on until the
   learner confirms they understand.
4. **Pacing:** Never rush. One concept at a time. If the learner seems confused, stop
   and clarify before continuing.

**API strategy:** Use the production API (`https://bookcorners.org/api/v1/`) for read-only
steps (browsing, maps, search). Switch to the local backend when we reach write operations
(submit, report, photos) to avoid polluting production data. The `APIClient` will support
a configurable base URL.

---

## Tech Stack

| Layer | Choice | Rationale |
|---|---|---|
| Language | Swift 6.2 | Ships with Xcode 26; default main actor isolation, `@concurrent`, simpler Sendable |
| UI | SwiftUI | Declarative, Apple's recommended framework |
| Architecture | MVVM + `@Observable` | Clean separation; `@Observable` replaces older `ObservableObject`/`@Published` |
| Min iOS | 26.0 | Latest: Liquid Glass design, Foundation Models, Xcode 26 required for App Store from April 2026 |
| Design | Liquid Glass | iOS 26's translucent design language — applied automatically to native SwiftUI controls |
| Networking | `URLSession` + `async/await` | No third-party HTTP libs — learn the fundamentals first |
| Maps | MapKit (SwiftUI) | Apple Maps with `Map`, `Annotation`, `MapCameraPosition`; geocoding via `MKGeocodingRequest` |
| Geocoding | MapKit + GeoToolbox | `MKReverseGeocodingRequest` replaces deprecated `CLGeocoder`; `PlaceDescriptor` for place data |
| Location | CoreLocation | `CLLocationUpdate.liveUpdates()` async sequence (modern API, replaces delegate pattern) |
| Photos | PhotosUI | `PhotosPicker`, EXIF extraction via `CGImageSource` |
| Token storage | Keychain (Security framework) | Thin wrapper, no library — learn the platform |
| Testing | Swift Testing | Apple's modern test framework (`@Test`, `@Suite`, `#expect`) — replaces XCTest |
| Dependencies | None initially | Educational goal: understand Apple frameworks before adding libraries |
| Package manager | Swift Package Manager | Built into Xcode, no CocoaPods/Carthage |
| IDE | Xcode 26 | Required for iOS 26 SDK; mandatory for App Store submissions from April 2026 |

---

## Data Models (matching API responses)

| Model | Key Fields |
|---|---|
| `Library` | id, slug, name, description, photoURL, thumbnailURL, lat, lng, address, city, country, postalCode, wheelchairAccessible, capacity, isIndoor, isLit, website, contact, source, operator, brand, createdAt |
| `LibraryListResponse` | items: [Library], pagination: PaginationMeta |
| `PaginationMeta` | page, pageSize, total, totalPages, hasNext, hasPrevious |
| `TokenPair` | access, refresh |
| `AccessToken` | access |
| `User` | id, username, email |
| `Report` | id, reason, createdAt |
| `ReportReason` | enum: damaged, missing, incorrectInfo, inappropriate, other |
| `LibraryPhoto` | id, caption, status, createdAt |
| `Statistics` | totalApproved, totalWithImage, topCountries, cumulativeSeries |
| `APIError` | message, details |

---

## Project Structure

```
BookCorners/
  BookCornersApp.swift              -- @main entry point
  Info.plist                        -- permissions (location, camera, photo library)
  Assets.xcassets/                  -- app icon, colors, images
  Models/                          -- Codable structs matching API
  Services/                        -- APIClient, AuthService, LocationService, KeychainService
  ViewModels/                      -- one per major screen
  Views/
    Components/                    -- reusable: LibraryCard, LoadingView, ErrorView, EmptyState
    Tabs/                          -- ContentView (TabView container)
    Libraries/                     -- LibraryListView, LibraryDetailView
    Map/                           -- MapTabView
    Auth/                          -- LoginView, RegisterView
    Submit/                        -- SubmitLibraryView
    Report/                        -- ReportView
    Photos/                        -- AddPhotoView
    Admin/                         -- PendingLibrariesView, AdminDetailView
  Extensions/                      -- CLLocation+Distance, Date+Formatting, etc.
  Utilities/                       -- PhotonService, EXIFReader, GeocodingHelper
  Preview Content/                 -- mock data for SwiftUI previews
BookCornersTests/                  -- unit tests (Swift Testing framework)
```

---

## Backend API Gaps

Features that require new backend endpoints (not blocking Steps 1–13):

| iOS Feature | Missing Backend Work | When Needed |
|---|---|---|
| Google Sign-In | `POST /auth/google` — exchange Google ID token for JWT | Step 14 |
| Sign in with Apple | `POST /auth/apple` — exchange Apple identity token for JWT | Step 14 |
| List community photos | `GET /libraries/{slug}/photos` — list approved photos | Step 11 |
| Admin: list pending | `GET /admin/libraries/?status=pending` (staff-only) | Step 15 |
| Admin: approve/reject | `PATCH /admin/libraries/{slug}` — set status | Step 15 |
| User role exposure | `is_staff` field in `/auth/me` response | Step 15 |
| Push: device registration | `POST /devices/`, `DELETE /devices/{token}` | Step 16 |
| Push: server-side sending | APNs integration for approval/submission events | Step 16 |

---

## Step 1 — Project Setup

**Goal:** Create the Xcode project, establish folder structure, understand the SwiftUI app
lifecycle and MVVM pattern. Get "Hello World" running on the simulator.

**Concepts:** Xcode project creation, `@main`, `App` protocol, `Scene`, `WindowGroup`, project
navigator, simulator, MVVM in SwiftUI context, `@Observable` macro.

### 1.1 Create new Xcode project

Open Xcode and create a new project:

- [x] 1.1.1 Open Xcode → **File → New → Project** (or `Cmd+Shift+N`) ✅
- [x] 1.1.2 Choose **iOS → App** template, click Next ✅
- [x] 1.1.3 Fill in the project options: ✅
  - **Product Name:** `BookCorners`
  - **Organization Identifier:** something like `org.bookcorners` (this combines with the product
    name to form the **Bundle Identifier** — `org.bookcorners.BookCorners` — a unique ID for your
    app on the App Store, similar to a Java/Go package path)
  - **Interface:** SwiftUI
  - **Language:** Swift
  - **Storage:** None (we won't use SwiftData or Core Data for now)
  - **Include Tests:** check this box (we'll use the test target in Step 3)
- [x] 1.1.4 When prompted for a location, select the **existing** `book-corners-ios` directory. ✅
  Xcode will create a `BookCorners/` folder inside it. Make sure "Create Git repository" is
  **unchecked** (we already have one).

> **What just happened?** Xcode generated a minimal SwiftUI app with two key files:
> `BookCornersApp.swift` (the entry point) and `ContentView.swift` (the initial screen).
> Think of `BookCornersApp.swift` as your `main.go` or `if __name__ == "__main__"` — it's
> where the app starts.

### 1.2 Set deployment target to iOS 26.0

- [x] 1.2.1 In the **Project Navigator** (left sidebar), click the top-level **BookCorners** ✅
  project (the blue icon, not the folder)
- [x] 1.2.2 Select the **BookCorners** target under TARGETS ✅
- [x] 1.2.3 Go to the **General** tab ✅
- [x] 1.2.4 Under **Minimum Deployments**, set iOS to **26.0** ✅

> **Why iOS 26?** iOS 26 is the current release (shipped September 2025) and App Store
> submissions will **require** the iOS 26 SDK from April 2026. It brings **Liquid Glass** —
> a new translucent design language that automatically applies to native SwiftUI controls
> (tab bars, navigation bars, toolbars). It also includes the Foundation Models framework
> for on-device AI, new TabView modifiers (`tabViewBottomAccessory`, `tabBarMinimizeBehavior`),
> and refined MapKit APIs. The minimum device is iPhone 11 (A13 chip, 2019).

### 1.3 Create folder/group structure

Xcode organizes files using **folders** (in Xcode 26, the old "New Group" is now "New Folder").
Unlike Python packages or Go modules, folders are purely organizational — they don't affect
imports or namespacing. All Swift files in a target can see each other without explicit imports.

- [x] 1.3.1 In the Project Navigator, right-click the **BookCorners** folder (the blue folder ✅
  icon inside the top-level project) → **New Folder**. Create these folders:
  - `Models`
  - `Services`
  - `ViewModels`
  - `Views`
  - `Extensions`
  - `Utilities`
- [x] 1.3.2 Inside the `Views` folder, create sub-folders: ✅
  - `Components`
  - `Tabs`
  - `Libraries`
  - `Map`
  - `Auth`
  - `Submit`
  - `Report`
  - `Photos`
  - `Admin`
- [x] 1.3.3 Move `ContentView.swift` into `Views/Tabs/` (drag it in the navigator) ✅
- [x] 1.3.4 Verify the folder structure on disk matches what's in Xcode. ✅

> **Python comparison:** In Python you'd have `models/`, `services/`, `views/` packages with
> `__init__.py`. In Swift, there are no package boundaries within a target — every file can
> access every other file's public and internal types. The folder structure is purely for
> human organization.

### 1.4 Configure Info.plist permissions

When your app wants to access the camera, location, or photo library, iOS requires you to
declare **why** in advance, with a user-facing explanation string. These go in `Info.plist` —
a property list file that's roughly equivalent to `AndroidManifest.xml` or a `pyproject.toml`
for app metadata.

Modern Xcode projects manage most `Info.plist` keys through the target's **Info** tab rather
than editing the file directly.

- [x] 1.4.1 Select the **BookCorners** target → **Info** tab ✅
- [x] 1.4.2 Under **Custom iOS Target Properties**, add these keys (hover a row for `+` button): ✅
  - `Privacy - Location When In Use Usage Description` → `"Book Corners uses your location to show nearby libraries"`
  - `Privacy - Photo Library Usage Description` → `"Book Corners needs access to your photos to submit library pictures"`
  - `Privacy - Camera Usage Description` → `"Book Corners uses the camera to take photos of libraries"`

> **Important:** These strings are shown to the user in the permission dialog. Make them
> specific and honest — vague descriptions like "needs access to your data" get rejected
> during App Store review.

### 1.5 Understand the SwiftUI app lifecycle and MVVM

Before writing more code, let's understand how a SwiftUI app is structured.

**The App entry point:**

Open `BookCornersApp.swift`. You'll see something like:

```swift
import SwiftUI

@main
struct BookCornersApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

Breaking this down:
- `@main` marks this as the entry point (like `func main()` in Go)
- `App` is a protocol (like a Go interface) that requires a `body` property
- `Scene` describes a window configuration. `WindowGroup` creates a standard window
- `ContentView()` is the root view — what the user sees first

**MVVM in SwiftUI:**

MVVM stands for **Model-View-ViewModel**. If you've used Django, you can roughly map it:

| MVVM | Django equivalent | Go equivalent | Role |
|------|-------------------|---------------|------|
| **Model** | Django model / serializer | struct | Data structures, business rules |
| **View** | Template | Template / handler | What the user sees (UI) |
| **ViewModel** | View (the Python class) | Controller/handler logic | Prepares data for display, handles user actions |

In SwiftUI specifically:
- **Models** are plain `struct`s (often `Codable` for JSON, like Python dataclasses or Go structs)
- **Views** are SwiftUI `View` structs — declarative descriptions of UI
- **ViewModels** are `@Observable` classes that hold mutable state and business logic

The `@Observable` macro is the modern way to make SwiftUI react to state changes.
When a property on an `@Observable` class changes, any View reading that property
automatically re-renders — iOS 26 makes this even more efficient with granular property-level
tracking. This is similar to React's state management, or Django signals triggering template
updates — but built into the language.

> **Swift 6.2 note:** New Xcode 26 projects default to main actor isolation for all code.
> This means your code is single-threaded by default — safe and simple. When you explicitly
> need background work (network calls, heavy computation), you use `@concurrent` to opt in.
> This is the opposite of older Swift, where you had to opt *in* to thread safety.

```swift
// Example (don't add this yet — just for understanding):
@Observable
class LibraryListViewModel {
    var libraries: [Library] = []   // when this changes, the View updates
    var isLoading = false

    func loadLibraries() async {
        isLoading = true
        libraries = try await apiClient.getLibraries()
        isLoading = false
    }
}
```

- [x] 1.5.1 Read through `BookCornersApp.swift` and `ContentView.swift` to understand the ✅
  generated code
- [x] 1.5.2 Make sure you understand: `@main`, `App`, `Scene`, `WindowGroup`, `View`, `body` ✅

### 1.6 Run on simulator

- [x] 1.6.1 In the Xcode toolbar at the top, select a simulator device (e.g., **iPhone 16**) ✅
  from the device dropdown
- [x] 1.6.2 Press **Cmd+R** (or click the play button ▶) to build and run ✅
- [x] 1.6.3 The iOS Simulator should launch and display "Hello, world!" ✅
- [x] 1.6.4 Try **Cmd+B** (build without running) — useful to quickly check if your code ✅
  compiles without launching the simulator every time

> **Tip:** You can also use **SwiftUI Previews** — the canvas on the right side of Xcode that
> live-renders your view without running the full app. Press `Cmd+Option+Enter` to toggle
> the preview canvas. Previews are faster than launching the simulator for UI work.

### 1.7 Commit the initial project

- [x] 1.7.1 Review what Xcode generated — make sure no sensitive files are included ✅
- [x] 1.7.2 Check that `.gitignore` covers Xcode user data (`xcuserdata/`) ✅
- [x] 1.7.3 Stage all new files and commit ✅
- [x] 1.7.4 Push to remote ✅

---

## Step 2 — Networking Layer

**Goal:** Build a reusable API client that handles all HTTP communication with the Book Corners
backend. JSON encoding/decoding, error handling, and multipart form uploads.

**Concepts:** `URLSession`, `async/await`, `Codable`, `JSONDecoder` key strategies, generics,
`URLRequest`, `HTTPURLResponse`, custom error types, multipart/form-data encoding.

### 2.1 Define API model structs

Create `Codable` structs in `Models/` that match the JSON the API returns. In Swift, `Codable`
is like Python's `@dataclass` with built-in JSON serialization, or a Go struct with `json:` tags.
The compiler auto-generates the encoding/decoding — you just declare the fields.

We use `JSONDecoder.keyDecodingStrategy = .convertFromSnakeCase` so the API's `snake_case` fields
automatically map to Swift's `camelCase` properties (e.g., `photo_url` → `photoURL`).

- [x] 2.1.1 Create `Models/Library.swift` with the `Library` struct: ✅
  - Fields: `id` (Int), `slug` (String), `name` (String), `description` (String),
    `photoURL` (String), `thumbnailURL` (String), `lat` (Double), `lng` (Double),
    `address` (String), `city` (String), `country` (String), `postalCode` (String),
    `wheelchairAccessible` (String), `capacity` (Int?), `isIndoor` (Bool?),
    `isLit` (Bool?), `website` (String), `contact` (String), `source` (String),
    `operator_` (String — `operator` is a Swift reserved word, needs `CodingKeys`),
    `brand` (String), `createdAt` (Date)
  - Note: String fields are never null but may be empty `""`. Only `capacity`, `isIndoor`,
    `isLit` are nullable (use optionals). The `operator` field needs a `CodingKeys` enum
    because `operator` is a reserved word in Swift.

- [x] 2.1.2 Create `Models/LibraryListResponse.swift`: ✅
  - `LibraryListResponse`: `items` ([Library]), `pagination` (PaginationMeta)
  - `PaginationMeta`: `page` (Int), `pageSize` (Int), `total` (Int), `totalPages` (Int),
    `hasNext` (Bool), `hasPrevious` (Bool)

- [x] 2.1.3 Create `Models/LatestLibrariesResponse.swift`: ✅
  - `LatestLibrariesResponse`: `items` ([Library])

- [x] 2.1.4 Create `Models/AuthModels.swift` with auth-related structs: ✅
  - `TokenPair`: `access` (String), `refresh` (String)
  - `AccessToken`: `access` (String)
  - `User`: `id` (Int), `username` (String), `email` (String)
  - `LoginRequest`: `username` (String), `password` (String) — `Encodable` only
  - `RegisterRequest`: `username` (String), `password` (String), `email` (String) — `Encodable`
  - `RefreshRequest`: `refresh` (String) — `Encodable`

- [x] 2.1.5 Create `Models/Report.swift`: ✅
  - `ReportReason` enum: `damaged`, `missing`, `incorrectInfo`, `inappropriate`, `other`
    — conforms to `String, Codable, CaseIterable`
  - `Report`: `id` (Int), `reason` (String), `createdAt` (Date)

- [x] 2.1.6 Create `Models/LibraryPhoto.swift`: ✅
  - `LibraryPhoto`: `id` (Int), `caption` (String), `status` (String), `createdAt` (Date)

- [x] 2.1.7 Create `Models/Statistics.swift`: ✅
  - `Statistics`: `totalApproved` (Int), `totalWithImage` (Int),
    `topCountries` ([CountryCount]), `cumulativeSeries` ([CumulativeEntry]),
    `granularity` (String)
  - `CountryCount`: `countryCode` (String), `countryName` (String), `flagEmoji` (String),
    `count` (Int)
  - `CumulativeEntry`: `period` (String), `cumulativeCount` (Int)

- [x] 2.1.8 Create `Models/APIError.swift`: ✅
  - `APIErrorResponse`: `message` (String), `details` (optional — use `AnyCodable` or
    keep as raw JSON `[String: String]?` for simplicity)

> **Swift vs Python comparison:** A Swift `struct` with `Codable` is like a Python
> `@dataclass` combined with a Pydantic model. The key difference: Swift is statically typed,
> so the compiler checks all field types at compile time. If the JSON doesn't match, you get
> a runtime decoding error (which we'll handle in our `APIClient`).

### 2.2 Configure JSONDecoder

Set up a shared decoder that handles the API's snake_case keys and ISO 8601 dates.

- [x] 2.2.1 Create a shared `JSONDecoder` configured with: ✅
  - `.keyDecodingStrategy = .convertFromSnakeCase` — maps `photo_url` → `photoURL`
  - `.dateDecodingStrategy = .iso8601` — parses `"2025-06-15T14:30:00Z"` into `Date`
  - This will live inside `APIClient` as a property

> **Why `.convertFromSnakeCase`?** The Django backend uses Python's snake_case convention
> (`photo_url`, `created_at`). Swift convention is camelCase (`photoURL`, `createdAt`).
> Instead of writing a `CodingKeys` enum for every struct, this one-line decoder config
> handles the conversion automatically. It's like Go's `json:"photo_url"` tags but global.

### 2.3 Create APIClient

Build the central networking class that all views and view models will use.

- [x] 2.3.1 Create `Services/APIClient.swift` with: ✅
  - Stored properties: `baseURL` (URL), `accessToken` (String?), `session` (URLSession),
    `decoder` (JSONDecoder)
  - Initializer accepting `baseURL` (default: production URL) and optional `URLSession`
    (for testing — we'll inject a mock session in Step 3)
  - Default production URL: `https://bookcorners.org/api/v1/`

> **Why inject URLSession?** Same reason you'd pass a database connection in Python/Go
> tests — dependency injection. In Step 3, we'll create a mock `URLSession` that returns
> fake responses without hitting the network.

### 2.4 Implement generic request method

The core method that all endpoint methods call. Uses Swift generics (like Go generics or
Python's `TypeVar`) to decode any response type.

- [x] 2.4.1 Implement `request<T: Decodable>(path:method:body:queryItems:) async throws -> T`: ✅
  - Build `URL` from `baseURL` + path + query parameters
  - Create `URLRequest`, set HTTP method, headers (`Content-Type: application/json`,
    `Authorization: Bearer <token>` if logged in)
  - For POST/PUT/PATCH with a body: encode with `JSONEncoder` (also snake_case strategy)
  - Call `URLSession.shared.data(for: request)` with async/await
  - Check `HTTPURLResponse.statusCode` — throw typed errors for 401, 429, 4xx, 5xx
  - Decode response body with the configured `JSONDecoder`
  - Return the decoded `T`

> **`async/await` in Swift** works almost identically to Python's `async/await`. The
> `try await` combo means "this can both fail (throw) and suspend (await)". URLSession's
> `.data(for:)` is the async version of what would be `requests.get()` in Python or
> `http.Get()` in Go — but non-blocking.

> **Swift 6.2 concurrency note:** In Xcode 26, code defaults to main actor isolation
> (single-threaded, like being on the main/UI thread). URLSession handles threading
> internally — when you `await` a network call, the UI stays responsive. You don't need
> `@concurrent` or `Task.detached` for basic networking.

### 2.5 Define APIClientError

A custom error enum so callers can handle specific failure cases (like showing a login
screen on 401, or a "try again later" message on 429).

- [x] 2.5.1 Create `APIClientError` enum in `Services/APIClientError.swift`: ✅
  - Cases: `invalidURL`, `httpError(statusCode: Int, message: String)`,
    `unauthorized`, `rateLimited(retryAfter: Int?)`, `decodingError(Error)`,
    `networkError(Error)`
  - Conform to `Error` and `LocalizedError` (provides `.localizedDescription`)
  - Parse error body when possible to extract the API's `message` field

> **Swift enums with associated values** are like Rust's enums or a tagged union. Each case
> can carry different data. This is much more expressive than Python's exception classes or
> Go's `errors.New()`. Pattern matching with `switch` lets callers handle each case cleanly.

### 2.6 Add read-only endpoint methods

Convenience methods that wrap the generic `request()` for each API endpoint. These are
what view models will actually call.

- [x] 2.6.1 Add `getLibraries(page:pageSize:query:city:country:lat:lng:radiusKm:hasPhoto:) ✅
  async throws -> LibraryListResponse` — builds query parameters, calls `request()`
- [x] 2.6.2 Add `getLibrary(slug:) async throws -> Library` ✅
- [x] 2.6.3 Add `getLatestLibraries(limit:hasPhoto:) async throws -> LatestLibrariesResponse` ✅
- [x] 2.6.4 Add `getStatistics() async throws -> Statistics` ✅

### 2.7 Implement MultipartFormData helper

iOS has no built-in multipart encoder (unlike Python's `requests` library). We need to
manually construct the HTTP body with boundary-separated parts.

- [x] 2.7.1 Create `Services/MultipartFormData.swift`: ✅
  - A struct/class that accumulates form fields and file attachments
  - Method `addField(name:value:)` — adds a text field
  - Method `addFile(name:fileName:mimeType:data:)` — adds a file part
  - Property `contentType` — returns `"multipart/form-data; boundary=<boundary>"`
  - Method `encode() -> Data` — assembles the complete body with boundary separators

> **Multipart/form-data** is the HTTP encoding for file uploads — the same format a browser
> uses for `<form enctype="multipart/form-data">`. Each part is separated by a unique
> "boundary" string. It's like MIME encoding for email attachments. Python's `requests`
> hides this; in Swift we build it manually.

### 2.8 Add auth and write endpoint methods

Methods for endpoints that require authentication or use multipart encoding.

- [x] 2.8.1 Add `login(username:password:) async throws -> TokenPair` ✅
- [x] 2.8.2 Add `register(username:password:email:) async throws -> TokenPair` ✅
- [x] 2.8.3 Add `refreshToken(refreshToken:) async throws -> AccessToken` ✅
- [x] 2.8.4 Add `getMe() async throws -> User` ✅
- [x] 2.8.5 Add `submitLibrary(...)` method using `MultipartFormData` ✅
- [x] 2.8.6 Add `reportLibrary(slug:reason:details:photo:)` ✅
- [x] 2.8.7 Add `addPhoto(slug:photo:caption:)` ✅

### 2.9 Create mock/preview support

SwiftUI previews need data without hitting the network. Create sample data and a mock client.

- [x] 2.9.1 Create `Preview Content/SampleData.swift` with static sample `Library`, `User`, ✅
  etc. instances for use in SwiftUI previews
- [x] 2.9.2 Extract `APIClientProtocol` protocol from `APIClient` (lists all public methods) ✅
  — this enables dependency injection and mocking
- [x] 2.9.3 Create `Preview Content/MockAPIClient.swift` that conforms to `APIClientProtocol` ✅
  and returns sample data immediately

> **Protocols in Swift** are like Go interfaces — they define a set of methods without
> implementation. Any type that implements all the methods automatically conforms. This is
> how we swap a real `APIClient` for a mock in previews and tests.

### 2.10 Smoke test

Verify the networking layer works end-to-end before moving on.

- [x] 2.10.1 Temporarily modify `ContentView` to call `APIClient().getLatestLibraries()` ✅
  in a `.task` modifier and print the results to the console
- [x] 2.10.2 Build and run on simulator — verify library data prints in Xcode's console ✅
- [x] 2.10.3 Test error handling: try an invalid URL, check that errors are caught properly ✅
- [x] 2.10.4 Revert `ContentView` to its original state after verifying ✅
- [x] 2.10.5 Commit the networking layer ✅

---

## Step 3 — Testing Foundation

**Goal:** Set up the testing infrastructure, learn the Swift Testing framework,
and write tests for the networking layer built in Step 2.

**Concepts:** Swift Testing (`@Test`, `@Suite`, `#expect`, `#require`), test targets in
Xcode 26, mocking with protocols, `URLProtocol` for intercepting network requests, async
test patterns, parameterized tests.

> **Note:** We use **Swift Testing** exclusively — Apple's modern framework that replaces
> XCTest. It uses `@Test` instead of `test*` method naming, `#expect` instead of
> `XCTAssertEqual`, and structs instead of classes. From this point on, each step should
> include tests for new ViewModels and services.

### 3.1 Verify the test target exists

Xcode should have created a `BookCornersTests` target when we set up the project.

- [x] 3.1.1 Open the Test Navigator in Xcode (`Cmd+6`) — you should see the ✅
  `BookCornersTests` target with the stub test file
- [x] 3.1.2 Run the existing stub test with `Cmd+U` to verify the test infrastructure works ✅
- [x] 3.1.3 Check that `BookCornersTests.swift` uses `import Testing` and `@testable import ✅
  BookCorners` — `@testable` gives tests access to `internal` types (everything we wrote
  in Step 2 is internal by default)

### 3.2 Understand Swift Testing framework

Before writing tests, understand the key concepts. Swift Testing is Apple's modern replacement
for XCTest. If you've used `pytest`, many concepts will feel familiar.

**Key differences from XCTest (and comparisons to Python/Go):**

| Swift Testing | XCTest | pytest | Go testing |
|---|---|---|---|
| `@Test func anyName()` | `func testSomething()` | `def test_something():` | `func TestSomething(t)` |
| `@Suite struct` | `class: XCTestCase` | `class TestFoo:` | file-level |
| `#expect(a == b)` | `XCTAssertEqual(a, b)` | `assert a == b` | `if a != b { t.Error() }` |
| `#require(x)` | `XCTUnwrap(x)` | N/A | `t.Fatal()` |
| `init()` | `setUp()` | `setup_method()` | N/A |
| `deinit` | `tearDown()` | `teardown_method()` | `t.Cleanup()` |
| `@Test(arguments:)` | N/A | `@pytest.mark.parametrize` | table-driven tests |

- [x] 3.2.1 Read through the comparison table above ✅
- [x] 3.2.2 Understand `#expect` vs `#require`: ✅
  - `#expect(condition)` — records failure but continues (like pytest's `assert`)
  - `try #require(value)` — stops the test immediately if it fails (like unwrapping
    an optional — if nil, the test can't continue). Use when subsequent code depends
    on the value existing.
- [x] 3.2.3 Understand `init`/`deinit` for setup/teardown: ✅
  - Swift Testing creates a **new instance** of the test suite struct for each test
  - `init()` runs before each test — set up your test fixtures here
  - `deinit` runs after each test — clean up here (must be synchronous)
  - This is like pytest fixtures or Go's test helper setup

### 3.3 Create MockURLProtocol

To test `APIClient` without hitting the real network, we intercept HTTP requests using
`URLProtocol` — a Foundation class that lets you control what `URLSession` returns.

Think of it as monkey-patching `requests.Session` in Python, or replacing the HTTP
transport in Go's `http.Client`.

- [x] 3.3.1 Create `BookCornersTests/MockURLProtocol.swift`: ✅
  - Subclass `URLProtocol`
  - Add a static `requestHandler` property: a closure that receives a `URLRequest` and
    returns `(HTTPURLResponse, Data)` — this is what the test sets up to control responses
  - Override `canInit(with:)` to return `true` (intercept all requests)
  - Override `canonicalRequest(for:)` to return the request as-is
  - Override `startLoading()` to call `requestHandler` and feed the response/data
    back through `client?` methods
  - Override `stopLoading()` as empty

- [x] 3.3.2 Create a helper function or property to build a `URLSession` configured with ✅
  `MockURLProtocol`:
  - Use `URLSessionConfiguration.ephemeral` (no caching)
  - Set `config.protocolClasses = [MockURLProtocol.self]`
  - Create `URLSession(configuration: config)`

### 3.4 Create test JSON fixtures

Sample JSON strings that match real API responses, for testing decoding.

- [x] 3.4.1 Create `BookCornersTests/Fixtures.swift` with static JSON strings: ✅
  - `libraryJSON` — a single library object as the API returns it
  - `libraryListJSON` — a paginated list response with items and pagination
  - `latestLibrariesJSON` — a latest libraries response
  - `tokenPairJSON` — login/register response
  - `userJSON` — /auth/me response
  - `statisticsJSON` — statistics response
  - `apiErrorJSON` — error response with message and details
  - Use realistic field names and values matching the actual API

### 3.5 Write tests for JSON decoding

Test that our model structs correctly decode from JSON. These are the most basic tests —
if decoding is broken, nothing else works.

- [ ] 3.5.1 Create `BookCornersTests/ModelDecodingTests.swift` with a `@Suite`:
  - Set up a `JSONDecoder` with `.convertFromSnakeCase` and `.iso8601` in `init()`
  - Test decoding `Library` from `libraryJSON`
  - Test decoding `LibraryListResponse` from `libraryListJSON`
  - Test decoding `LatestLibrariesResponse` from `latestLibrariesJSON`
  - Test decoding `TokenPair` from `tokenPairJSON`
  - Test decoding `User` from `userJSON`
  - Test decoding `Statistics` from `statisticsJSON`
  - Test decoding `APIErrorResponse` from `apiErrorJSON`
  - For each: decode the JSON, then `#expect` specific field values match

- [ ] 3.5.2 Test edge cases:
  - Library with null `capacity`, `isIndoor`, `isLit` fields
  - Library with empty string fields (`name`, `photoUrl`, etc.)
  - Invalid JSON (missing required field) — expect decoding to throw

### 3.6 Write tests for APIClient methods

Test the `APIClient` with mocked network responses using `MockURLProtocol`.

- [ ] 3.6.1 Create `BookCornersTests/APIClientTests.swift` with a `@Suite`:
  - In `init()`, create an `APIClient` with the mock `URLSession`
  - Test `getLatestLibraries()` — set up `MockURLProtocol` to return valid JSON,
    verify the decoded result
  - Test `getLibrary(slug:)` — verify correct URL path is requested
  - Test `getLibraries()` with query parameters — verify query items in the URL

- [ ] 3.6.2 Test error handling:
  - 404 response → expect `APIClientError.httpError`
  - 401 response → expect `APIClientError.unauthorized`
  - 429 response with retry_after → expect `APIClientError.rateLimited`
  - Invalid JSON response → expect `APIClientError.decodingError`
  - Network failure → expect `APIClientError.networkError`

- [ ] 3.6.3 Test auth header:
  - When `accessToken` is set, verify the `Authorization` header is sent
  - When `accessToken` is nil, verify no `Authorization` header

### 3.7 Write tests for MultipartFormData

Test that the multipart encoder produces correct output.

- [ ] 3.7.1 Create `BookCornersTests/MultipartFormDataTests.swift`:
  - Test `addField` — verify the encoded body contains the field name and value
    with correct boundary separators
  - Test `addFile` — verify the encoded body contains filename, mime type, and data
  - Test `contentType` — verify it includes the boundary string
  - Test multiple fields + file — verify all parts are present and properly separated
  - Test `encode()` — verify the closing boundary is appended

### 3.8 Run all tests and verify

- [ ] 3.8.1 Run all tests with `Cmd+U`
- [ ] 3.8.2 All tests should pass — fix any failures
- [ ] 3.8.3 Commit the test foundation

---

## Step 4 — Authentication

**Goal:** Login, registration, secure token storage in Keychain, automatic token refresh,
and auth state management across the app. Email/password only for now — social login
(Google, Apple) deferred to Step 14 after backend support is added.

**Concepts:** Keychain Services API (`SecItemAdd/CopyMatching/Update/Delete`), `@Observable`
state, SwiftUI sheets, Swift 6.2 concurrency (`@concurrent` for background work, default
main actor isolation).

- [ ] 4.1 Create `KeychainService` — save/load/delete data in the iOS Keychain
- [ ] 4.2 Create `AuthService` (`@Observable`) — manages `isAuthenticated`, `currentUser`, tokens
- [ ] 4.3 Implement login flow (API call → save tokens → fetch /auth/me → update state)
- [ ] 4.4 Implement registration flow with error handling (username taken, weak password)
- [ ] 4.5 Implement token refresh with concurrency guard (prevent parallel refresh calls)
- [ ] 4.6 Add automatic 401 retry in `APIClient` (refresh token, retry request once)
- [ ] 4.7 Implement logout (clear Keychain, clear state)
- [ ] 4.8 Build `LoginView` — form with username/password, error display
- [ ] 4.9 Build `RegisterView` — form with username/email/password/confirm
- [ ] 4.10 Inject `AuthService` into SwiftUI environment
- [ ] 4.11 Restore session on app launch (load tokens from Keychain, verify with /auth/me)

---

## Step 5 — Tab Navigation

**Goal:** Set up the app's main tab-based navigation with placeholder views.

**Concepts:** `TabView` with `Tab` API, Liquid Glass tab bar (automatic in iOS 26), `Label`,
SF Symbols, `@State`/`@SceneStorage` for tab selection, `tabBarMinimizeBehavior`,
conditional UI based on auth state.

- [ ] 5.1 Create `ContentView` with `TabView` using `Tab` API (Nearby, Map, Submit, Profile)
- [ ] 5.2 Create placeholder views for each tab
- [ ] 5.3 Handle auth-gated tabs (Submit shows login sheet if unauthenticated)
- [ ] 5.4 Build `ProfileView` — conditional content based on auth state
- [ ] 5.5 Configure tab bar — Liquid Glass styling is automatic; explore `tabBarMinimizeBehavior`
- [ ] 5.6 Persist selected tab with `@SceneStorage`

---

## Step 6 — Library List (Nearby)

**Goal:** Display a proximity-sorted list of libraries based on user location, with pull-to-refresh
and pagination.

**Concepts:** `CLLocationUpdate.liveUpdates()` async sequence, `CLServiceSession` for
permissions, `List`, `LazyVStack`, `.task`, `.refreshable`, pagination, `AsyncImage`,
distance computation.

- [ ] 6.1 Create `LocationService` (`@Observable`) — use `CLLocationUpdate.liveUpdates()` async sequence, `CLServiceSession` for authorization
- [ ] 6.2 Inject `LocationService` into the environment
- [ ] 6.3 Create `LibraryListViewModel` — load/refresh/paginate libraries
- [ ] 6.4 Compute client-side distance (`CLLocation.distance(from:)`), sort by proximity
- [ ] 6.5 Build `LibraryCardView` — reusable row (thumbnail, name, city, distance)
- [ ] 6.6 Build `LibraryListView` — `List` with `.task` and `.refreshable`
- [ ] 6.7 Implement pagination (load more on scroll to bottom)
- [ ] 6.8 Handle location permission states (not determined, denied, authorized)
- [ ] 6.9 Handle empty state ("No book corners found nearby")
- [ ] 6.10 Handle loading and error states with reusable components

---

## Step 7 — Library Detail

**Goal:** Full detail view for a library — photo, description, address, mini map, metadata,
and action buttons.

**Concepts:** `NavigationStack`, `NavigationLink`, `.navigationDestination`, `ScrollView` layout,
inline `Map`, conditional sections.

- [ ] 7.1 Create `LibraryDetailViewModel` — load library by slug
- [ ] 7.2 Build `LibraryDetailView` — photo, name, description, address, mini map, metadata
- [ ] 7.3 Add navigation from list to detail (`NavigationLink` + `.navigationDestination`)
- [ ] 7.4 Add placeholder buttons (Get Directions, Report Issue, Add Photo)
- [ ] 7.5 Handle optional fields gracefully (show sections only when data exists)
- [ ] 7.6 Add `ShareLink` to share the library URL
- [ ] 7.7 Show action buttons conditionally (Report/Photo only when authenticated)

---

## Step 8 — Map View

**Goal:** Apple Maps with library pins. Tap pins to see details. Reload when the map moves.

**Concepts:** SwiftUI `Map` (`MapContentBuilder`), `Annotation`, `Marker`,
`MapCameraPosition`, `.onMapCameraChange`, `.mapControls`, Liquid Glass styling, clustering.

- [ ] 8.1 Create `MapViewModel` — load libraries for visible region, track camera position
- [ ] 8.2 Build `MapTabView` — `Map` with user location, controls (compass, scale, location button)
- [ ] 8.3 Add library annotations/markers with book icon
- [ ] 8.4 Handle annotation tap — show bottom sheet with library card + "View Details" button
- [ ] 8.5 Reload libraries when map region changes (debounced)
- [ ] 8.6 Handle location permission on map (default center if denied)
- [ ] 8.7 Navigate from map to library detail
- [ ] 8.8 Show user's location (blue dot)

---

## Step 9 — Submit Library

**Goal:** Form to submit a new library with photo, GPS extraction from EXIF, address autocomplete
(Photon), and reverse geocoding (Nominatim).

**Concepts:** `PhotosPicker`, `CGImageSource` (EXIF), multipart upload, `Form` with Liquid
Glass sections, input validation, debounced search, `MKReverseGeocodingRequest` (replaces
deprecated `CLGeocoder`).

- [ ] 9.1 Create `SubmitLibraryViewModel` — all form state + submission logic
- [ ] 9.2 Build photo picker with preview thumbnail
- [ ] 9.3 Extract GPS coordinates from photo EXIF data (`CGImageSource`)
- [ ] 9.4 Reverse geocode with `MKReverseGeocodingRequest` (iOS 26) or Nominatim API as fallback
- [ ] 9.5 Create `PhotonService` — address autocomplete with debouncing
- [ ] 9.6 Build the submission form (Photo, Location, Details, Accessibility sections)
- [ ] 9.7 Implement country picker (ISO 3166-1 codes)
- [ ] 9.8 Submit via multipart form-data
- [ ] 9.9 Handle submission result (success confirmation, error display)
- [ ] 9.10 Guard against unauthenticated access (present login sheet)

---

## Step 10 — Report Issue

**Goal:** Authenticated users report problems with a library (damaged, missing, incorrect info).

**Concepts:** `enum` with `Picker`, optional photo attachment, modal sheet presentation.

- [ ] 10.1 Create `ReportViewModel` — reason, details, optional photo, submission state
- [ ] 10.2 Build `ReportView` — form sheet with reason picker, text editor, optional photo
- [ ] 10.3 Validate and submit as multipart form-data
- [ ] 10.4 Handle success (dismiss + toast) and errors

---

## Step 11 — Community Photos

**Goal:** Authenticated users add photos to existing libraries.

**Concepts:** Reuse `PhotosPicker` pattern, caption input, photo upload.

- [ ] 11.1 Create `AddPhotoViewModel` — photo, caption, submission state
- [ ] 11.2 Build `AddPhotoView` — sheet with picker, preview, caption, submit
- [ ] 11.3 Submit photo via multipart form-data
- [ ] 11.4 Display community photos on detail view (blocked on backend `GET /libraries/{slug}/photos`)

---

## Step 12 — Directions

**Goal:** Open walking/driving directions to a library in the user's preferred maps app.

**Concepts:** `MKMapItem`, `openInMaps()`, URL schemes, `LSApplicationQueriesSchemes`,
`confirmationDialog`.

- [ ] 12.1 Create `DirectionsService` — open directions in Apple Maps via `MKMapItem`
- [ ] 12.2 Support Google Maps via URL scheme (optional, check if installed)
- [ ] 12.3 Show action sheet if multiple map apps available
- [ ] 12.4 Wire up "Get Directions" button in library detail

---

## Step 13 — Splash Screen

**Goal:** Branded launch screen while the app loads.

**Concepts:** Launch screen configuration in Info.plist, app icon asset catalog.

- [ ] 13.1 Configure launch screen via Info.plist (background color + logo)
- [ ] 13.2 Add app logo to Assets.xcassets
- [ ] 13.3 Optional: animated splash view while restoring session + getting location

---

## Step 14 — Social Login (deferred — blocked on backend)

**Goal:** Add Google Sign-In and Sign in with Apple as alternative auth methods.

**Requires backend:** `POST /auth/google` and `POST /auth/apple` endpoints that exchange
identity provider tokens for JWT pairs.

**Concepts:** `AuthenticationServices` framework (Apple Sign-In), Google Sign-In SDK (SPM),
identity token exchange, account linking.

- [ ] 14.1 Implement Sign in with Apple using `ASAuthorizationAppleIDProvider`
- [ ] 14.2 Add Google Sign-In SDK via SPM
- [ ] 14.3 Implement Google Sign-In flow
- [ ] 14.4 Exchange provider tokens for JWT via backend
- [ ] 14.5 Handle account linking (same email, different provider)
- [ ] 14.6 Update `LoginView` with social login buttons

---

## Step 15 — Admin Dashboard (blocked on backend)

**Goal:** Hidden admin section to review and approve/reject pending library submissions.

**Requires backend:** `GET /admin/libraries/?status=pending`, `PATCH /admin/libraries/{slug}`,
`is_staff` in `/auth/me` response.

- [ ] 15.1 Detect admin role from `/auth/me` response (`isStaff` field)
- [ ] 15.2 Show admin tab/section only for staff users
- [ ] 15.3 Create `AdminViewModel` — load pending libraries
- [ ] 15.4 Build `PendingLibrariesView` — list of submissions awaiting review
- [ ] 15.5 Build `AdminLibraryDetailView` — detail with Approve/Reject buttons
- [ ] 15.6 Implement approve/reject API calls with confirmation dialogs
- [ ] 15.7 Pull-to-refresh for new submissions

---

## Step 16 — Push Notifications (blocked on backend)

**Goal:** Notify users when their library is approved; notify admins of new submissions.

**Requires backend:** device token registration endpoint, server-side APNs integration.

- [ ] 16.1 Request notification permission (at appropriate moment, not on first launch)
- [ ] 16.2 Register for APNs via `@UIApplicationDelegateAdaptor`
- [ ] 16.3 Send device token to backend
- [ ] 16.4 Handle incoming notifications — deep link to library detail
- [ ] 16.5 Unregister device token on logout
- [ ] 16.6 Handle permission denied gracefully

---

## Step 17 — Polish and Production Readiness

**Goal:** Consistent error handling, loading states, accessibility, dark mode, app icon,
and App Store preparation.

- [ ] 17.1 Reusable `ErrorView(message:retryAction:)` everywhere
- [ ] 17.2 Loading indicators (initial load, pagination, refresh)
- [ ] 17.3 Reusable `EmptyStateView` for screens with no data
- [ ] 17.4 Accessibility: `.accessibilityLabel`, `.accessibilityHint`, VoiceOver testing
- [ ] 17.5 Dark mode support (semantic colors, test all views)
- [ ] 17.6 Network connectivity handling (`NWPathMonitor`, offline banner)
- [ ] 17.7 Image caching (if `AsyncImage` proves insufficient)
- [ ] 17.8 App icon (1024x1024 in Assets.xcassets)
- [ ] 17.9 Rate limit handling (user-friendly 429 messages)
- [ ] 17.10 Client-side input validation on all forms
- [ ] 17.11 Haptic feedback for key actions
- [ ] 17.12 App Store preparation (screenshots, description, privacy labels)

---

## Dependency Graph

```
Step 1 (Setup)
  │
Step 2 (Networking)
  │
Step 3 (Testing)
  │
Step 4 (Auth)
  │
Step 5 (Tabs)
  ├────────────────┐
Step 6 (List)      Step 8 (Map)
  │                  │
  └──── Step 7 (Detail) ───┘
           │
     ┌─────┼──────────┐
  Step 9   Step 10  Step 11
 (Submit) (Report) (Photos)
           │
        Step 12 (Directions)

Step 13 (Splash) ── independent, do anytime after Step 1
Step 14 (Social Login) ── blocked on backend, after Step 4
Step 15 (Admin) ── blocked on backend, after Step 7
Step 16 (Notifications) ── blocked on backend, after Step 4
Step 17 (Polish) ── continuous, finish last
```

Steps 1–5 are strictly sequential. After Step 5, Steps 6 and 8 can be built in either order.
Step 7 is shared by both list and map. Steps 9–11 require auth (Step 4) and the detail view
(Step 7). Steps 14–16 are blocked on backend work and should be deferred.

---

## Verification Strategy

After each step, verify by:

1. **Build & run** — the project must compile and run on simulator without warnings
2. **Tests pass** — all unit tests green (`Cmd+U` in Xcode)
3. **Visual check** — UI matches expectations on iPhone 16 simulator
4. **Console check** — no unexpected errors in Xcode console
5. **API check** — network calls return expected data (use Xcode Network Inspector or print)
6. **Edge cases** — test with location denied, no network, empty API results, expired tokens

**API targets:**
- **Steps 1–8** (read-only): use production API at `https://bookcorners.org/api/v1/`
- **Steps 9+** (write operations): switch to local backend to avoid polluting production data
