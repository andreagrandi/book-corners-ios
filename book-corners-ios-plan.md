# Book Corners iOS — Implementation Plan

> A SwiftUI iOS client for [Book Corners](https://www.bookcorners.org): a community-driven directory
> of little free libraries. Users can discover nearby book exchange spots, submit new ones,
> report issues, and contribute photos.

**Approach:** Interactive tutorial. Each step below will be expanded into detailed sub-steps
(with code guidance) when we begin working on it. Steps are ordered by dependency — each
builds on the previous.

**API strategy:** Use the production API (`https://bookcorners.org/api/v1/`) for read-only
steps (browsing, maps, search). Switch to the local backend when we reach write operations
(submit, report, photos) to avoid polluting production data. The `APIClient` will support
a configurable base URL.

---

## Tech Stack

| Layer | Choice | Rationale |
|---|---|---|
| Language | Swift 6 | Latest stable, strict concurrency |
| UI | SwiftUI | Declarative, Apple's recommended framework |
| Architecture | MVVM + `@Observable` | Clean separation; `@Observable` replaces older `ObservableObject`/`@Published` |
| Min iOS | 18.0 | Latest APIs: new `Tab` syntax for `TabView`, refined MapKit, `@Observable` improvements |
| Networking | `URLSession` + `async/await` | No third-party HTTP libs — learn the fundamentals first |
| Maps | MapKit (SwiftUI) | Apple Maps with `Map`, `Annotation`, `MapCameraPosition` |
| Location | CoreLocation | `CLLocationManager` with async wrapper |
| Photos | PhotosUI | `PhotosPicker`, EXIF extraction via `CGImageSource` |
| Token storage | Keychain (Security framework) | Thin wrapper, no library — learn the platform |
| Testing | XCTest + Swift Testing | Unit tests for networking, ViewModels; learn both frameworks |
| Dependencies | None initially | Educational goal: understand Apple frameworks before adding libraries |
| Package manager | Swift Package Manager | Built into Xcode, no CocoaPods/Carthage |

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
  Utilities/                       -- NominatimService, PhotonService, EXIFReader
  Preview Content/                 -- mock data for SwiftUI previews
BookCornersTests/                  -- unit tests (XCTest + Swift Testing)
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

- [ ] 1.1 Create new Xcode project (App template, SwiftUI, Swift)
- [ ] 1.2 Set deployment target to iOS 18.0
- [ ] 1.3 Create folder/group structure (Models, Services, ViewModels, Views, Extensions, Utilities)
- [ ] 1.4 Configure Info.plist permissions (location, photo library, camera)
- [ ] 1.5 Understand MVVM and how it maps to SwiftUI (`@Observable` classes as ViewModels)
- [ ] 1.6 Run on simulator — verify "Hello, world!" appears
- [ ] 1.7 Commit the initial project

---

## Step 2 — Networking Layer

**Goal:** Build a reusable API client that handles all HTTP communication with the Book Corners
backend. JSON encoding/decoding, error handling, and multipart form uploads.

**Concepts:** `URLSession`, `async/await`, `Codable`, `JSONDecoder` key strategies, generics,
`URLRequest`, `HTTPURLResponse`, custom error types, multipart/form-data encoding.

- [ ] 2.1 Define all API model structs (`Library`, `TokenPair`, `User`, etc.) with `Codable`
- [ ] 2.2 Configure shared `JSONDecoder` (`.convertFromSnakeCase`, `.iso8601` date strategy)
- [ ] 2.3 Create `APIClient` class with configurable `baseURL` and optional `accessToken`
- [ ] 2.4 Implement generic `request<T: Decodable>()` method
- [ ] 2.5 Define `APIClientError` enum (httpError, unauthorized, rateLimited, decodingError, etc.)
- [ ] 2.6 Add convenience methods for each endpoint (getLibraries, getLibrary, getLatest, getStats)
- [ ] 2.7 Implement `MultipartFormData` helper for photo uploads
- [ ] 2.8 Add auth endpoint methods (login, register, refresh, getMe)
- [ ] 2.9 Create mock/preview support for SwiftUI previews
- [ ] 2.10 Smoke test — temporary view that fetches latest libraries and prints to console

---

## Step 3 — Testing Foundation

**Goal:** Set up the testing infrastructure, learn XCTest and Swift Testing frameworks,
and write tests for the networking layer built in Step 2.

**Concepts:** XCTest vs Swift Testing (`@Test`, `#expect`), test targets in Xcode, mocking
with protocols, `URLProtocol` for intercepting network requests, async test patterns.

- [ ] 3.1 Add a test target to the Xcode project (if not already present)
- [ ] 3.2 Understand XCTest basics (test classes, `setUp`/`tearDown`, assertions)
- [ ] 3.3 Understand Swift Testing framework (`@Test`, `@Suite`, `#expect`, `#require`)
- [ ] 3.4 Extract `APIClientProtocol` from `APIClient` for testability
- [ ] 3.5 Create `MockURLProtocol` to intercept and stub network requests
- [ ] 3.6 Write tests for JSON decoding (Library, TokenPair, etc. from sample JSON)
- [ ] 3.7 Write tests for `APIClient` methods (success, error, 401 handling)
- [ ] 3.8 Write tests for `MultipartFormData` encoding
- [ ] 3.9 Establish test patterns (fixtures, helpers) for reuse in later steps

> **Note:** From this point on, each step should include tests for new ViewModels and services.
> Tests won't be listed as separate sub-steps, but are expected as part of the work.

---

## Step 4 — Authentication

**Goal:** Login, registration, secure token storage in Keychain, automatic token refresh,
and auth state management across the app. Email/password only for now — social login
(Google, Apple) deferred to Step 14 after backend support is added.

**Concepts:** Keychain Services API (`SecItemAdd/CopyMatching/Update/Delete`), `@Observable`
state, SwiftUI sheets, `actor` for thread-safe token refresh.

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

**Concepts:** `TabView` with iOS 18 `Tab` API, `Label`, SF Symbols, `@State`/`@SceneStorage`
for tab selection, conditional UI based on auth state.

- [ ] 5.1 Create `ContentView` with `TabView` using iOS 18 `Tab` API (Nearby, Map, Submit, Profile)
- [ ] 5.2 Create placeholder views for each tab
- [ ] 5.3 Handle auth-gated tabs (Submit shows login sheet if unauthenticated)
- [ ] 5.4 Build `ProfileView` — conditional content based on auth state
- [ ] 5.5 Configure tab bar appearance and tint color
- [ ] 5.6 Persist selected tab with `@SceneStorage`

---

## Step 6 — Library List (Nearby)

**Goal:** Display a proximity-sorted list of libraries based on user location, with pull-to-refresh
and pagination.

**Concepts:** `CLLocationManager`, location permissions, `List`, `LazyVStack`, `.task`,
`.refreshable`, pagination, `AsyncImage`, distance computation.

- [ ] 6.1 Create `LocationService` (`@Observable`) — request authorization, expose current location
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
`MapCameraPosition`, `.onMapCameraChange`, `.mapControls`, clustering.

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

**Concepts:** `PhotosPicker`, `CGImageSource` (EXIF), multipart upload, `Form` with sections,
input validation, debounced search.

- [ ] 9.1 Create `SubmitLibraryViewModel` — all form state + submission logic
- [ ] 9.2 Build photo picker with preview thumbnail
- [ ] 9.3 Extract GPS coordinates from photo EXIF data (`CGImageSource`)
- [ ] 9.4 Create `NominatimService` — reverse geocode coordinates to address
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
