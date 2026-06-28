# Repository Guidelines

## Session Start Workflow

Before making code or documentation changes in this repo:

1. Switch back to `master`.
2. Pull the latest changes with `git pull --ff-only`.
3. Create a new branch with a short, descriptive name related to the feature being added or the bug being fixed.
4. Make the requested changes on that branch.

Do not start work from an old feature branch unless the user explicitly asks to continue that branch.

## Adding a Ticket, Issue, or Bug

When the user asks to add a "ticket", "issue", or "bug" to this repo, all of
the steps below are required — creating the GitHub issue alone is not enough.

**1. Create the issue** with the repo label and a type label:

```bash
gh issue create --repo andreagrandi/book-corners-ios \
  --title "<concise title>" \
  --body "<description>" \
  --label "book-corners-ios" \
  --label "<type>"
```

- Always apply the `book-corners-ios` label — every work item in this repo
  carries it.
- Pick one type label: `bug`, `enhancement`, or `documentation`. These are
  the only type labels in use on existing issues (see #9–#19).
- Do not invent new labels. Area is captured via the project's Area field
  (step 3), not via a label.

**2. Add the issue to the "Book Corners" project** and capture the item ID
(<https://github.com/users/andreagrandi/projects/2>):

```bash
ITEM_ID=$(gh project item-add 2 --owner andreagrandi \
  --url <issue-url> --format json --jq .id)
```

**3. Set Project, Priority, Area, and Status** on the project item. The
"Book Corners" board is shared by both `book-corners` and `book-corners-ios`,
so the Project field must be set to distinguish them.

- Project ID: `PVT_kwHOAAm1584BYNOT`
- Project (which repo) — field `PVTSSF_lAHOAAm1584BYNOTzhTUrB4`:
  book-corners `1e714f28`, book-corners-ios `5955c8f9`
- Priority — field `PVTSSF_lAHOAAm1584BYNOTzhTUrCA`:
  High `b925d2e0`, Medium `23f4e2d2`, Low `89b1cb1e`
- Area — field `PVTSSF_lAHOAAm1584BYNOTzhTUrB8`:
  API `c4e6b87d`, Admin `ba5fc051`, Search `82f936e5`, Map `97b54a1b`,
  Notifications `4ec3ad2e`, Operations `144b587b`, Testing `3aa57aae`,
  UX `9574e84e`
- Status — field `PVTSSF_lAHOAAm1584BYNOTzhTUq48`:
  Todo `f75ad846`, In Progress `47fc9ee4`, Done `98236657`

```bash
# Project — always set to book-corners-ios for issues from this repo
gh project item-edit --id "$ITEM_ID" --project-id PVT_kwHOAAm1584BYNOT \
  --field-id PVTSSF_lAHOAAm1584BYNOTzhTUrB4 \
  --single-select-option-id 5955c8f9

# Priority — always set it
gh project item-edit --id "$ITEM_ID" --project-id PVT_kwHOAAm1584BYNOT \
  --field-id PVTSSF_lAHOAAm1584BYNOTzhTUrCA \
  --single-select-option-id <priority-option-id>

# Area — pick the option that best matches the issue
gh project item-edit --id "$ITEM_ID" --project-id PVT_kwHOAAm1584BYNOT \
  --field-id PVTSSF_lAHOAAm1584BYNOTzhTUrB8 \
  --single-select-option-id <area-option-id>

# Status — new tickets start as Todo
gh project item-edit --id "$ITEM_ID" --project-id PVT_kwHOAAm1584BYNOT \
  --field-id PVTSSF_lAHOAAm1584BYNOTzhTUq48 \
  --single-select-option-id f75ad846
```

If the user does not state a priority or area, ask before creating the
issue. Follow the conventions of existing project issues — do not invent
new labels or fields.

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

Prefer XcodeBuildMCP for build and test verification when it is available. Use
it to list/select an available simulator and run the `BookCorners` scheme. If
XcodeBuildMCP is unavailable, disconnected, or cannot run the needed action,
fall back to the `xcodebuild` commands below.

```bash
# Build
xcodebuild -project BookCorners/BookCorners.xcodeproj -scheme BookCorners build \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'

# Run tests
xcodebuild -project BookCorners/BookCorners.xcodeproj -scheme BookCorners test \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'
```

When using the fallback, swap simulator name if unavailable. Use
`xcodebuild ... -quiet` to suppress noise. Always verify builds compile before
declaring work done.

## Research Before Implementing

Before using any Apple framework, SwiftUI API, or third-party library: **look
up the documentation first** using context7 (ctx7) to verify correct API names,
method signatures, and current best practices. Do not guess or rely on training
data — APIs change across OS versions. Always check Apple's recommended
patterns (e.g. prefer `@Observable` over `ObservableObject`, modern concurrency
over Combine, etc.).

## Coding Style

- **Swift 6.2**, SwiftUI, iOS 26+ deployment target
- 4-space indentation, trailing commas in multi-line parameters
- One primary type per file, `UpperCamelCase` for types, `lowerCamelCase` for properties/methods
- `@Observable` for ViewModels (not `ObservableObject`/`@Published`)
- `async/await` for concurrency (no Combine)
- **SwiftFormat** runs automatically via a git pre-commit hook on staged
  `.swift` files — do not run it manually or remind the user to do so

## Testing

- **Swift Testing** framework: `import Testing`, `@Test`, `@Suite`, `#expect`
- Network tests use `MockURLProtocol` with handler closures and a custom `mockSession`
- ViewModel tests use `StubAPIClient` (conforms to `APIClientProtocol`) with
  per-method handler closures
- Fixtures defined in `Fixtures.swift` as static JSON strings
- Network tests are marked `.serialized` (in `SerialNetworkTests`) to avoid
  `MockURLProtocol` handler conflicts
- Preview data uses `MockAPIClient` and `SampleData` in `Preview Content/`

## Changelog

- Whenever you make user-visible changes (features, fixes, polish), update
  `CHANGELOG.md` in the same PR that introduces them.
- Add the entry under the version section matching the bumped
  `MARKETING_VERSION`. Create the section if it does not exist yet.
- Group entries under `### Features`, `### Fixes`, or `### Polish` to match
  the existing format. Keep bullets short and user-facing — describe the
  observable change, not the implementation.

## Commit Guidelines

- Short imperative subjects: `Add ...`, `Fix ...`, `Update ...`
- Never run `git commit` or `git push` without explicit user approval
- Use `gh` for all GitHub operations; always include a PR description
- Never include personal email addresses in commits or PRs
- Never use `"Little Free Library"` — it's trademarked. Use "book-sharing
  library" or "library"
