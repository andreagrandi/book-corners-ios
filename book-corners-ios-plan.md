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

- [x] 3.5.1 Create `BookCornersTests/ModelDecodingTests.swift` with a `@Suite`: ✅
  - Set up a `JSONDecoder` with `.convertFromSnakeCase` and `.iso8601` in `init()`
  - Test decoding `Library` from `libraryJSON`
  - Test decoding `LibraryListResponse` from `libraryListJSON`
  - Test decoding `LatestLibrariesResponse` from `latestLibrariesJSON`
  - Test decoding `TokenPair` from `tokenPairJSON`
  - Test decoding `User` from `userJSON`
  - Test decoding `Statistics` from `statisticsJSON`
  - Test decoding `APIErrorResponse` from `apiErrorJSON`
  - For each: decode the JSON, then `#expect` specific field values match

- [x] 3.5.2 Test edge cases: ✅
  - Library with null `capacity`, `isIndoor`, `isLit` fields
  - Library with empty string fields (`name`, `photoUrl`, etc.)
  - Invalid JSON (missing required field) — expect decoding to throw

### 3.6 Write tests for APIClient methods

Test the `APIClient` with mocked network responses using `MockURLProtocol`.

- [x] 3.6.1 Create `BookCornersTests/APIClientTests.swift` with a `@Suite`: ✅
  - In `init()`, create an `APIClient` with the mock `URLSession`
  - Test `getLatestLibraries()` — set up `MockURLProtocol` to return valid JSON,
    verify the decoded result
  - Test `getLibrary(slug:)` — verify correct URL path is requested
  - Test `getLibraries()` with query parameters — verify query items in the URL

- [x] 3.6.2 Test error handling: ✅
  - 404 response → expect `APIClientError.httpError`
  - 401 response → expect `APIClientError.unauthorized`
  - 429 response with retry_after → expect `APIClientError.rateLimited`
  - Invalid JSON response → expect `APIClientError.decodingError`
  - Network failure → expect `APIClientError.networkError`

- [x] 3.6.3 Test auth header: ✅
  - When `accessToken` is set, verify the `Authorization` header is sent
  - When `accessToken` is nil, verify no `Authorization` header

### 3.7 Write tests for MultipartFormData

Test that the multipart encoder produces correct output.

- [x] 3.7.1 Create `BookCornersTests/MultipartFormDataTests.swift`: ✅
  - Test `addField` — verify the encoded body contains the field name and value
    with correct boundary separators
  - Test `addFile` — verify the encoded body contains filename, mime type, and data
  - Test `contentType` — verify it includes the boundary string
  - Test multiple fields + file — verify all parts are present and properly separated
  - Test `encode()` — verify the closing boundary is appended

### 3.8 Run all tests and verify

- [x] 3.8.1 Run all tests with `Cmd+U` ✅
- [x] 3.8.2 All tests should pass — fix any failures ✅
- [x] 3.8.3 Commit the test foundation ✅

---

## Step 4 — Authentication

**Goal:** Login, registration, secure token storage in Keychain, automatic token refresh,
and auth state management across the app. Email/password only for now — social login
(Google, Apple) deferred to Step 14 after backend support is added.

**Concepts:** Keychain Services API (`SecItemAdd/CopyMatching/Update/Delete`), `@Observable`
state, SwiftUI sheets, Swift 6.2 concurrency (`@concurrent` for background work, default
main actor isolation).

**Architecture overview:** Three layers, bottom to top:

```
┌─────────────────────────────────────────────┐
│  LoginView / RegisterView  (UI)             │  SwiftUI forms — collect input, show errors
├─────────────────────────────────────────────┤
│  AuthService  (@Observable)                 │  Single source of truth for auth state
├──────────────────┬──────────────────────────┤
│  KeychainService │  APIClient (existing)    │  Storage + Network
└──────────────────┴──────────────────────────┘
```

- **KeychainService** wraps the C-era Keychain API (`SecItemAdd` etc.) into a clean
  Swift interface. Stores JWT tokens (access + refresh) as encrypted data.
- **AuthService** is `@Observable` — it coordinates login/logout/refresh by calling
  `APIClient` and `KeychainService`, and exposes `isAuthenticated` / `currentUser`
  that views react to automatically.
- **LoginView / RegisterView** are SwiftUI forms presented as sheets. They call
  `AuthService` methods and display errors.

### 4.1 Create `KeychainService`

The iOS Keychain is a system-level encrypted database for storing small secrets — think
of it as Python's `keyring` library or a per-app credential vault. It persists across
app launches and survives app updates (but not uninstalls).

The API is C-era Apple code — you interact with it through dictionaries of `CFString`
keys and `Any` values, then call `SecItem*` functions that return `OSStatus` codes.
We'll wrap this ugliness in a clean Swift service.

**Python analogy:**
```python
keyring.set_password("bookcorners", "access_token", "eyJhb...")
token = keyring.get_password("bookcorners", "access_token")
keyring.delete_password("bookcorners", "access_token")
```

**Key concepts:**
- Each keychain item has a **class** (`kSecClassGenericPassword` for arbitrary secrets),
  a **service** name (our app identifier), and an **account** name (the key, e.g.
  `"access_token"`)
- `SecItemAdd` → create, `SecItemCopyMatching` → read, `SecItemUpdate` → update,
  `SecItemDelete` → delete
- All functions return `OSStatus` — check for `errSecSuccess`, `errSecItemNotFound`, etc.
- **Important:** `SecItemCopyMatching` blocks the calling thread. In Swift 6.2 (where
  code defaults to main actor), we mark the class `nonisolated` to opt it out of
  main actor isolation. (`@concurrent` only works on `async` methods — these are
  synchronous C calls, so `nonisolated` is the correct approach. Keychain ops are
  fast enough that the brief blocking is fine for our use case.)

- [x] 4.1.1 Create `Services/KeychainService.swift` ✅
- [x] 4.1.2 Define a `KeychainError` enum: `duplicateItem`, `itemNotFound`, ✅
  `unexpectedStatus(OSStatus)`, `dataConversionError`
- [x] 4.1.3 Implement `save(data:forKey:)` — builds a query dictionary with ✅
  `kSecClassGenericPassword`, service name, account (key), and value data.
  Calls `SecItemAdd`. If `errSecDuplicateItem`, falls through to update instead.
- [x] 4.1.4 Implement `load(forKey:) -> Data?` — builds a search query with ✅
  `kSecReturnData: true` and `kSecMatchLimit: kSecMatchLimitOne`. Calls
  `SecItemCopyMatching`. Returns nil for `errSecItemNotFound`.
- [x] 4.1.5 Implement `delete(forKey:)` — builds a query and calls `SecItemDelete`. ✅
  Ignores `errSecItemNotFound` (deleting something already gone is fine).
- [x] 4.1.6 Add convenience methods that work with `String` instead of `Data`: ✅
  `saveString(_:forKey:)` and `loadString(forKey:) -> String?`
- [x] 4.1.7 Mark the class `nonisolated` so Keychain I/O doesn't run on the main ✅
  actor (remember: Swift 6.2 defaults to main actor isolation; `@concurrent` is
  only for `async` methods, so `nonisolated` is correct for synchronous C calls)
- [x] 4.1.8 Define string constants for our keys: `"access_token"`, `"refresh_token"` ✅

> **Why not UserDefaults?** `UserDefaults` stores data as **plaintext** in a plist
> file — anyone with device access (or a backup) can read it. Keychain data is
> encrypted by the Secure Enclave. Never put tokens in UserDefaults.

### 4.2 Write tests for KeychainService

Test the Keychain wrapper before building on top of it. These tests will hit the
real Keychain (there's no good way to mock `SecItem*` functions), but that's fine —
the test runner has Keychain access.

- [x] 4.2.1 Create `BookCornersTests/KeychainServiceTests.swift` with a `@Suite` ✅
- [x] 4.2.2 Use `init()` to create a `KeychainService` with a unique test service ✅
  name (e.g. `"it.andreagrandi.BookCorners.tests.\(UUID())"`) so tests don't collide
- [x] 4.2.3 ~~Use `deinit` to clean up~~ — not needed; UUID-based service names ✅
  ensure no collisions between test runs
- [x] 4.2.4 Test save + load round-trip: save a string, load it back, `#expect` equal ✅
- [x] 4.2.5 Test overwrite: save a value, save a different value for the same key, ✅
  load should return the new value
- [x] 4.2.6 Test load missing key: `#expect` returns nil ✅
- [x] 4.2.7 Test delete: save a value, delete it, load should return nil ✅
- [x] 4.2.8 Test delete missing key: should not throw ✅

### 4.3 Create `AuthService` (`@Observable`)

The central auth coordinator. This is the **single source of truth** for "is the user
logged in?" across the entire app. Every view that cares about auth state reads from
this one object.

**Python analogy:** Like a Django middleware that checks the session on every request,
but reactive — any SwiftUI view reading `authService.isAuthenticated` automatically
re-renders when auth state changes.

**Go analogy:** Like a context value that's threaded through all handlers, but instead
of passing it explicitly, SwiftUI's environment system injects it automatically.

- [x] 4.3.1 Create `Services/AuthService.swift` as an `@Observable` class ✅
- [x] 4.3.2 Properties: ✅
  - `isAuthenticated: Bool` (computed: true when `accessToken` is non-nil)
  - `currentUser: User?` (the logged-in user's profile)
  - `isLoading: Bool` (true during login/register/restore operations)
  - `errorMessage: String?` (user-facing error for display in views)
  - `private(set) accessToken: String?`, `private refreshToken: String?`
- [x] 4.3.3 Dependencies (injected via init): ✅
  - `apiClient: APIClient` (for network calls)
  - `keychainService: KeychainService` (for token persistence)
- [x] 4.3.4 `setTokens(access:refresh:)` helper keeps `accessToken`, ✅
  `refreshToken`, and `apiClient.accessToken` in sync (`didSet` doesn't
  work with `@Observable` — the macro rewrites property storage)

> **`@Observable` vs `ObservableObject`:** `@Observable` (iOS 17+) is the modern
> replacement. With `ObservableObject`, you had to mark every property with `@Published`.
> With `@Observable`, **all** stored properties are automatically tracked — SwiftUI
> detects exactly which properties each view reads and only re-renders when those
> specific properties change. It's more efficient and less boilerplate.
>
> In Python terms: `ObservableObject` is like manually calling `self.notify_observers()`
> after each mutation. `@Observable` is like Python's `__setattr__` hook — the framework
> intercepts all writes automatically.

### 4.4 Implement login flow

The sequence: call API → save tokens to Keychain → set tokens on AuthService →
fetch user profile → update `currentUser`.

- [x] 4.4.1 Implement `login(username:password:) async`: ✅
  - Set `isLoading = true`, clear `errorMessage`
  - Call `apiClient.login(username:password:)` → get `TokenPair`
  - Save access + refresh tokens to Keychain via `keychainService`
  - Call `setTokens()` to update in-memory state + `apiClient`
  - Call `apiClient.getMe()` → get `User`, set `currentUser`
  - `defer { isLoading = false }` ensures cleanup on all paths
  - Wrapped in do/catch — on error, set `errorMessage` via `mapError()`
- [x] 4.4.2 `mapError()` helper maps API errors to user-friendly messages: ✅
  - `unauthorized` → "Invalid username or password"
  - `rateLimited` → "Too many attempts. Please try again later."
  - `networkError` → "Unable to connect. Check your internet connection."
  - Other → "Something went wrong. Please try again."

### 4.5 Implement registration flow

Similar to login, but with different validation errors from the backend.

- [x] 4.5.1 Implement `register(username:password:email:) async`: ✅
  - Same flow as login: call API → save tokens → fetch profile → update state
  - Use `apiClient.register(username:password:email:)`
- [x] 4.5.2 Map registration-specific errors: ✅
  - `httpError(400, message)` → pass through backend message directly
  - Other errors → same `mapError()` as login

### 4.6 Implement token refresh

When the access token expires, use the refresh token to get a new one. A concurrency
guard prevents multiple simultaneous refresh calls (imagine two API calls failing with
401 at the same time — without a guard, both would try to refresh).

**Go analogy:** Like `sync.Once` or a mutex — ensure the refresh operation runs exactly
once even if triggered from multiple goroutines.

- [x] 4.6.1 Add a private `refreshTask: Task<String, Error>?` property on `AuthService` ✅
  — this is the concurrency guard
- [x] 4.6.2 Implement `refreshAccessToken() async throws -> String`: ✅
  - If `refreshTask` already exists, `await` its result (piggyback)
  - Otherwise, create a new `Task` that:
    - `guard let` unwraps refreshToken (throws `.unauthorized` if nil)
    - Calls `apiClient.refreshToken(refreshToken:)`
    - Saves the new access token to Keychain
    - Calls `setTokens` with new access + existing refresh
    - Returns the new token string
  - `defer { refreshTask = nil }` clears on both success and failure
  - TODO: call `logout()` on refresh failure (will wire up after 4.8)

### 4.7 Add automatic 401 retry in `APIClient`

When an API call gets a 401, automatically attempt a token refresh and retry once.
This requires `APIClient` to know about `AuthService` — we'll use a callback/delegate
pattern to avoid a circular dependency.

- [x] 4.7.1 Define a `tokenRefresher` closure property on `APIClient`: ✅
  `var tokenRefresher: (() async throws -> String)?`
- [x] 4.7.2 Modify `request()` in `APIClient`: intercept 401 before the ✅
  existing guard, refresh token, rebuild request with new auth header,
  retry once, return retry result or throw
- [x] 4.7.3 Wire it up in `AuthService.init` with `[weak self]` to avoid ✅
  retain cycle (AuthService → APIClient → closure → AuthService)

> **Why a closure instead of a protocol?** A closure avoids introducing a new protocol
> and prevents a retain cycle (with `[weak self]`). It's the same pattern as passing
> a callback function in Python/Go. The APIClient doesn't need to know about AuthService
> at all — it just knows "here's a function I can call to get a new token."

### 4.8 Implement logout

- [x] 4.8.1 Implement `logout()`: ✅
  - `setTokens(access: nil, refresh: nil)` clears in-memory + apiClient
  - `currentUser = nil`
  - `try?` delete both tokens from Keychain (ignore errors)
  - Clear `errorMessage`

### 4.9 Restore session on app launch

When the app starts, check if we have saved tokens and try to resume the session.
This avoids making the user log in every time they open the app.

**Python analogy:** Like checking `request.session` for an existing session cookie on
each request, then validating it's still good.

- [x] 4.9.1 Implement `restoreSession() async`: ✅
  - Load tokens from Keychain with `try?` (ignore errors)
  - If either token missing, return silently
  - `setTokens` with loaded values
  - Nested do/catch: try `getMe()`, if fail try `refreshAccessToken()` +
    `getMe()`, if both fail `logout()`
  - `defer { isLoading = false }` for loading state

### 4.10 Build `LoginView`

A SwiftUI form presented as a sheet. Uses `SecureField` for the password (shows dots
instead of text, like `<input type="password">`).

**Key SwiftUI concepts:**
- `@State` — local view state (like a local variable that SwiftUI tracks). When it
  changes, the view re-renders. Unlike `@Observable` which is for shared state,
  `@State` is private to one view.
- `@Environment` — reads values from the SwiftUI environment (dependency injection).
  We'll use this to access `AuthService`.
- `Form` — a container that automatically styles its children as a settings-like form.
  In iOS 26, Form sections get Liquid Glass styling automatically.
- `SecureField` — a text field that hides input (for passwords).
- `.sheet` — presents a modal view that slides up from the bottom.

- [x] 4.10.1 Create `Views/Auth/LoginView.swift` ✅
- [x] 4.10.2 Add `@State` properties for `username` and `password` (local form state) ✅
- [x] 4.10.3 Access `AuthService` from the environment ✅
- [x] 4.10.4 Build the form: ✅
  - `TextField` for username (with `.textContentType(.username)` and
    `.autocorrectionDisabled()`)
  - `SecureField` for password (with `.textContentType(.password)`)
  - Login `Button` — disabled when fields are empty or `authService.isLoading`
  - Error display: show `authService.errorMessage` if present (red text)
  - Loading indicator: show `ProgressView` when `authService.isLoading`
- [x] 4.10.5 On login button tap: `Task { await authService.login(username:password:) }` ✅
- [x] 4.10.6 Dismiss the sheet on successful login (when `authService.isAuthenticated` ✅
  becomes true) — use `.onChange(of:)` modifier or `@Environment(\.dismiss)`
- [x] 4.10.7 Add a "Don't have an account? Register" link/button that navigates to ✅
  `RegisterView`

> **`.textContentType` hints:** These tell iOS what kind of data the field expects.
> With `.username` and `.password`, iOS offers to AutoFill from the Keychain and
> suggests saving new credentials. This is a free UX win.

### 4.11 Build `RegisterView`

Similar to `LoginView` but with additional fields and client-side validation.

- [x] 4.11.1 Create `Views/Auth/RegisterView.swift` ✅
- [x] 4.11.2 Add `@State` properties for `username`, `email`, `password`, ✅
  `confirmPassword`
- [x] 4.11.3 Client-side validation (before hitting the API): ✅
  - Username: not empty, reasonable length
  - Email: basic format check (contains `@`)
  - Password: not empty, minimum length (match backend requirements)
  - Confirm password: matches password
- [x] 4.11.4 Show inline validation messages (e.g. "Passwords don't match") ✅
- [x] 4.11.5 On register button tap: call `authService.register(username:password:email:)` ✅
- [x] 4.11.6 Dismiss on success, same pattern as LoginView ✅
- [x] 4.11.7 Add an "Already have an account? Login" link/button ✅

### 4.12 Inject `AuthService` into the SwiftUI environment

Wire everything together in the app entry point.

**Key concept: SwiftUI Environment.**
The environment is SwiftUI's dependency injection system. You create an object at the
top of the view hierarchy, and any descendant view can access it via `@Environment`.

**Python analogy:** Like Flask's `g` object or Django's request context — a bag of
objects available to all views/templates without explicitly passing them through every
layer.

**Go analogy:** Like `context.WithValue()` — attach a value to the context at the top,
read it anywhere below.

- [x] 4.12.1 In `BookCornersApp.swift`, create `AuthService` as a `@State` property ✅
- [x] 4.12.2 Pass it into the environment using `.environment(authService)` ✅
- [x] 4.12.3 Add a `.task` modifier on `ContentView` to call ✅
  `authService.restoreSession()` on app launch
- [ ] 4.12.4 Optionally show a loading/splash state while `authService.isLoading`
  during session restore

> **`@State` in the App struct:** We use `@State` to create the `AuthService` because
> the `App` struct owns its lifecycle. SwiftUI guarantees `@State` properties are
> created once and persist across `body` re-evaluations. This is different from
> `@State` in a View — same concept, but at the app level.

### 4.13 Write tests for AuthService

Test the auth flows with mocked dependencies.

- [x] 4.13.1 Create `BookCornersTests/AuthServiceTests.swift` with a `@Suite` ✅
- [x] 4.13.2 Create a mock `KeychainService` for testing (in-memory dictionary ✅
  instead of real Keychain) — or use a test-specific service name
- [x] 4.13.3 Test login success: mock API returns `TokenPair` + `User` → ✅
  `isAuthenticated` is true, `currentUser` is set, tokens saved
- [x] 4.13.4 Test login failure: mock API throws `unauthorized` → ✅
  `isAuthenticated` is false, `errorMessage` is set
- [x] 4.13.5 Test logout: after login, call logout → `isAuthenticated` is false, ✅
  `currentUser` is nil, tokens deleted from keychain
- [x] 4.13.6 Test session restore: tokens pre-saved in keychain, mock API returns ✅
  `User` → `isAuthenticated` is true after `restoreSession()`
- [x] 4.13.7 Test session restore with expired token: first `getMe()` throws 401, ✅
  refresh succeeds, second `getMe()` succeeds → ends up authenticated
- [x] 4.13.8 Test session restore with expired refresh: both calls fail → ✅
  ends up logged out, tokens cleared

### 4.14 Integration smoke test

Verify everything works end-to-end before moving on.

- [x] 4.14.1 Temporarily add a login button to `ContentView` that presents `LoginView` ✅
  as a sheet
- [x] 4.14.2 Build and run on simulator — test login with valid credentials against ✅
  the production API (use a test account)
- [x] 4.14.3 Verify: login succeeds, sheet dismisses, user info is available ✅
- [x] 4.14.4 Kill and relaunch the app — verify session restores automatically ✅
  (no login required)
- [x] 4.14.5 Test logout — verify state clears, next launch requires login ✅
- [x] 4.14.6 Test error cases: wrong password, empty fields, no network ✅
- [x] 4.14.7 Revert `ContentView` to its original state (login UI will be properly ✅
  integrated in Step 5)
- [x] 4.14.8 Run all tests with `Cmd+U` — all must pass ✅
- [ ] 4.14.9 Commit

---

## Step 5 — Tab Navigation

**Goal:** Set up the app's main tab-based navigation with placeholder views.

**Concepts:** `TabView` with `Tab` API, Liquid Glass tab bar (automatic in iOS 26), `Label`,
SF Symbols, `@State`/`@SceneStorage` for tab selection, `tabBarMinimizeBehavior`,
conditional UI based on auth state.

### 5.1 Understand `TabView` in iOS 26

iOS 26 introduced a new `TabView` API using the `Tab` type. Each tab has a title,
an SF Symbol icon, and a content view. The tab bar gets Liquid Glass styling
automatically — translucent, blurred background.

**SF Symbols** are Apple's icon library — thousands of vector icons built into iOS.
You reference them by name (e.g., `"books.vertical"`, `"map"`, `"plus.circle"`,
`"person"`). Browse them in the SF Symbols app (free download from Apple).

**Python analogy:** Think of `TabView` like a Django URL router — each "tab" maps
to a different view, and the tab bar is the navigation menu.

- [ ] 5.1.1 Research the iOS 26 `Tab` API — use the new `Tab("Title", systemImage:)` syntax
  rather than the older `tabItem` modifier
- [ ] 5.1.2 Plan four tabs: **Nearby** (book list), **Map** (map view),
  **Submit** (new library form), **Profile** (user info/login)

### 5.2 Create placeholder views for each tab

Before wiring up the tab bar, create simple placeholder views so each tab has
something to display.

- [ ] 5.2.1 Create `Views/Libraries/LibraryListView.swift` — placeholder with
  `Text("Nearby Libraries")` and a book icon
- [ ] 5.2.2 Create `Views/Map/MapTabView.swift` — placeholder with
  `Text("Map View")` and a map icon
- [ ] 5.2.3 Create `Views/Submit/SubmitLibraryView.swift` — placeholder with
  `Text("Submit Library")` and a plus icon

### 5.3 Build `ContentView` with `TabView`

Replace the "Hello, world!" ContentView with a proper tab-based layout.

- [ ] 5.3.1 Rewrite `ContentView` to use `TabView` with four `Tab` items:
  - **Nearby**: `Tab("Nearby", systemImage: "books.vertical")` → `LibraryListView()`
  - **Map**: `Tab("Map", systemImage: "map")` → `MapTabView()`
  - **Submit**: `Tab("Submit", systemImage: "plus.circle")` → `SubmitLibraryView()`
  - **Profile**: `Tab("Profile", systemImage: "person")` → `ProfileView()`
- [ ] 5.3.2 Add `@State private var selectedTab = 0` to track selection
- [ ] 5.3.3 Read `AuthService` from the environment in ContentView

### 5.4 Build `ProfileView`

The Profile tab shows different content depending on whether the user is logged in.

- [ ] 5.4.1 Create `Views/Tabs/ProfileView.swift`
- [ ] 5.4.2 When **authenticated**: show username, email, and a Logout button
- [ ] 5.4.3 When **not authenticated**: show a "Login" button and a "Register" button
  that present the respective sheets
- [ ] 5.4.4 Use `@Environment(AuthService.self)` to read auth state
- [ ] 5.4.5 Wrap in `NavigationStack` with `.navigationTitle("Profile")`

### 5.5 Handle auth-gated tabs

The Submit tab requires authentication. If the user taps it while logged out,
present the login sheet instead of the form.

- [ ] 5.5.1 In ContentView, detect when the Submit tab is selected while not
  authenticated
- [ ] 5.5.2 Present `LoginView` as a sheet and revert to the previous tab
- [ ] 5.5.3 If login succeeds, navigate to the Submit tab automatically

### 5.6 Tab bar configuration

- [ ] 5.6.1 Verify Liquid Glass styling applies automatically (no extra code needed)
- [ ] 5.6.2 Explore `tabBarMinimizeBehavior` — this iOS 26 feature lets the tab
  bar shrink when scrolling content, giving more screen space
- [ ] 5.6.3 Persist selected tab across app launches using `@SceneStorage("selectedTab")`
  — this saves the value to the system and restores it when the app relaunches

### 5.7 Smoke test and commit

- [ ] 5.7.1 Build and run on simulator — verify all four tabs appear with icons
- [ ] 5.7.2 Verify tab switching works
- [ ] 5.7.3 Verify Profile tab shows login/logout correctly
- [ ] 5.7.4 Verify Submit tab gate works (shows login if not authenticated)
- [ ] 5.7.5 Run all tests — all must pass
- [ ] 5.7.6 Commit

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
