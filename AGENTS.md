# Repository Guidelines

## Project Overview
Book Corners is an iOS app for discovering and sharing community book-sharing libraries. The backend is a Django + Django Ninja API at `https://bookcorners.org/api/v1/`.

## Project Structure
The Xcode project is `BookCorners/BookCorners.xcodeproj`. App code lives in `BookCorners/BookCorners/`:

```
Models/          — Codable structs for API responses and domain objects
Services/        — Network, auth, location, keychain, and other service classes
ViewModels/      — @Observable classes managing view state and async operations
Views/
  Auth/          — Login, register, social sign-in
  Components/    — Reusable UI (cards, pickers, empty/error states)
  Libraries/     — Library list and detail screens
  Map/           — Map tab
  Photos/        — Photo submission
  Report/        — Library reporting
  Submit/        — Library submission
  Tabs/          — ContentView (tab coordinator), ProfileView
Preview Content/ — MockAPIClient and SampleData for SwiftUI previews
Extensions/      — Swift extensions (e.g. CLLocation+Distance)
Utilities/       — Helpers (e.g. EXIFReader)
```

Tests: `BookCorners/BookCornersTests/` (unit), `BookCorners/BookCornersUITests/` (UI).

## Architecture
- **MVVM** with `@Observable` (not Combine)
- **Dependency injection**: services created in `BookCornersApp.swift`, passed via `.environment()`. ViewModels receive `any APIClientProtocol` via constructor injection.
- **Networking**: `APIClient` (URLSession-based) implements `APIClientProtocol`. Handles JSON encoding/decoding with `convertFromSnakeCase` key strategy, auth token management, and automatic token refresh.
- **Auth**: `AuthService` manages login/register/social login flows and stores tokens via `KeychainService`.
- **External dependency**: GoogleSignIn (only third-party framework).

## Build & Test

```bash
# Build
xcodebuild -project BookCorners/BookCorners.xcodeproj -scheme BookCorners build \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'

# Run tests
xcodebuild -project BookCorners/BookCorners.xcodeproj -scheme BookCorners test \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'
```

Swap simulator name if unavailable. Use `xcodebuild ... -quiet` to suppress noise. Always verify builds compile before declaring work done.

## Research Before Implementing
Before using any Apple framework, SwiftUI API, or third-party library: **look up the documentation first** using context7 (ctx7) to verify correct API names, method signatures, and current best practices. Do not guess or rely on training data — APIs change across OS versions. Always check Apple's recommended patterns (e.g. prefer `@Observable` over `ObservableObject`, modern concurrency over Combine, etc.).

## Coding Style
- **Swift 6.2**, SwiftUI, iOS 26+ deployment target
- 4-space indentation, trailing commas in multi-line parameters
- One primary type per file, `UpperCamelCase` for types, `lowerCamelCase` for properties/methods
- `@Observable` for ViewModels (not `ObservableObject`/`@Published`)
- `async/await` for concurrency (no Combine)
- **SwiftFormat** runs automatically via a git pre-commit hook on staged `.swift` files — do not run it manually or remind the user to do so

## Testing
- **Swift Testing** framework: `import Testing`, `@Test`, `@Suite`, `#expect`
- Network tests use `MockURLProtocol` with handler closures and a custom `mockSession`
- ViewModel tests use `StubAPIClient` (conforms to `APIClientProtocol`) with per-method handler closures
- Fixtures defined in `Fixtures.swift` as static JSON strings
- Network tests are marked `.serialized` (in `SerialNetworkTests`) to avoid `MockURLProtocol` handler conflicts
- Preview data uses `MockAPIClient` and `SampleData` in `Preview Content/`

## Commit Guidelines
- Short imperative subjects: `Add ...`, `Fix ...`, `Update ...`
- Never run `git commit` or `git push` without explicit user approval
- Use `gh` for all GitHub operations; always include a PR description
- Never include personal email addresses in commits or PRs
- Never use `"Little Free Library"` — it's trademarked. Use "book-sharing library" or "library"
