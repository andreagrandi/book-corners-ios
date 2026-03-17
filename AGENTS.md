# Repository Guidelines

## Tutorial-First Workflow
This repository is a learning project, not a speed-run implementation. Treat [book-corners-ios-plan.md](/Users/andrea/Projects/book-corners-ios/book-corners-ios-plan.md) as the source of truth for scope, order, and pacing. When helping here, act like a teacher: explain the concept before the code, use Python/Go analogies where useful, guide one small step at a time, explain unfamiliar Swift/SwiftUI syntax as it appears, and recap after each step. Do not jump ahead until the learner confirms understanding. For API work, use the production API for read-only steps and switch to the local backend for write flows.

## Project Structure & Module Organization
The Xcode project is [BookCorners/BookCorners.xcodeproj](/Users/andrea/Projects/book-corners-ios/BookCorners/BookCorners.xcodeproj). App code lives in [BookCorners/BookCorners](/Users/andrea/Projects/book-corners-ios/BookCorners/BookCorners): `Models/`, `Services/`, `ViewModels/`, `Views/`, `Extensions/`, `Utilities/`, and `Preview Content/`. Keep screen code under the matching `Views/` subfolder such as `Tabs/`, `Auth/`, `Libraries/`, `Map/`, or `Submit/`. Unit tests live in [BookCorners/BookCornersTests](/Users/andrea/Projects/book-corners-ios/BookCorners/BookCornersTests); UI tests live in [BookCorners/BookCornersUITests](/Users/andrea/Projects/book-corners-ios/BookCorners/BookCornersUITests).

## Build, Test, and Development Commands
Use `open BookCorners/BookCorners.xcodeproj` for day-to-day work in Xcode. Build from the CLI with `xcodebuild -project BookCorners/BookCorners.xcodeproj -scheme BookCorners build`. Run tests with `xcodebuild -project BookCorners/BookCorners.xcodeproj -scheme BookCorners test -destination 'platform=iOS Simulator,name=iPhone 16'` and swap in an installed simulator if needed. In Xcode, prefer `Cmd+B` for quick compile checks and `Cmd+R` for step-by-step simulator runs.

## Coding Style & Naming Conventions
This app uses Swift 6.2, SwiftUI, MVVM, and `@Observable`. Follow the existing style: 4-space indentation, one primary type per file, `UpperCamelCase` for types, and `lowerCamelCase` for properties and methods. Keep changes boring and incremental. Add new models to `Models/`, service code to `Services/`, and view state to `ViewModels/`. Avoid third-party dependencies unless the tutorial explicitly introduces them.

## Testing Guidelines
Prefer Swift Testing for unit coverage: `import Testing`, `@Test`, and `#expect`. Keep network tests deterministic with `MockURLProtocol` and fixtures. Reserve XCTest for UI behavior in `BookCornersUITests`. Add or update tests with each meaningful behavior change so every tutorial step still builds and passes cleanly.

## Commit & Pull Request Guidelines
Match recent history with short imperative commit subjects such as `Add ProfileView...` or `Fix missing paren...`; include step references like `(Step 5.4)` when they help. Never guess JIRA IDs. Do not run `git commit` or `git push` without explicit user approval. Use `gh` for GitHub operations, include a real PR description, and attach screenshots for visible UI changes.

