# Learning Dashboard

A SwiftUI learning dashboard built as a focused mobile engineering assessment. The app demonstrates validated demo sign-in, asynchronous loading, course browsing, lesson completion, computed progress, and offline cache fallback.

## Run

Open `LearningDashboard.xcodeproj` in Xcode, select the **LearningDashboard** scheme, choose an iPhone simulator, and run. The project targets iOS 17 or later. No backend or credentials are required; sign in with any valid email address and a password of at least six characters.

## Architecture

SwiftUI views observe a `CourseDashboardViewModel`. The view model exposes loading, loaded, empty, and failure states. `CourseRepository` coordinates a `CourseService` and `CourseCache`; `Course` and `Lesson` are Codable models that calculate progress. The service is a deterministic mock API backed by bundled `courses.json` so the sample can run without a server.

## Offline support

The repository saves every successful course response and lesson change as Codable JSON in UserDefaults. Lesson completion changes are merged from the saved cache when refreshed course data arrives, so locally completed lessons are not reset by the bundled sample data. If loading the service fails, the repository returns the saved courses and the dashboard labels them as offline. If no saved copy exists, the dashboard displays an error state with retry. This small dataset is appropriate for UserDefaults; a production app should use SwiftData/Core Data or another local database and define cache expiry and sync conflict behavior.

## Security

Sign-in validation is local demo behavior; the app does not authenticate with a server or store a password. A production app should use TLS and keep refresh credentials in Keychain, with short-lived access tokens and secure refresh/logout handling.

## Scale and second platform

For a million users and large course catalogs, I would add paginated API endpoints, repository protocol-based dependency injection, a database-backed cache with sync rules, robust token refresh and authorization, and performance/operational monitoring with integration and UI tests. On Android, I would use Jetpack Compose, Navigation Compose, ViewModels with StateFlow, a repository backed by Retrofit/Ktor and Room, WorkManager for retryable sync, and Android Keystore-backed credential storage.

## Tests

The unit tests cover progress calculations (including an empty course), cache fallback on service failure, preservation of local lesson progress across refreshes, and persistence after lesson completion. Run them with **Product → Test** in Xcode.
