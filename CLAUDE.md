# CLAUDE.md

Studiop is an iOS/Swift rebuild of an existing Flutter live-commerce app, reusing its current backend
API as-is. The backend's actual domain/host lives in exactly one place — the `Environment` config in
Core (see docs/api-reference.md → Base configuration) — so pointing at a self-hosted backend later is
a one-line change, not a rename across the codebase. Clean Architecture: Presentation → Domain
(Entity/UseCase/Repository protocol) → Data (RepositoryImpl/DataSource) → Core
(NetworkClient/Environment). Domain must never import networking, Firebase, or Ably.

DI is [swift-dependencies](https://github.com/pointfreeco/swift-dependencies), not a manual
composition root or a container library (Factory/Swinject) — one `DependencyKey` per Repository
protocol, read via `@Dependency` in ViewModels/UseCases.

- **Before assuming a feature is in scope**, read [docs/features.md](docs/features.md) — the full
  feature inventory from the source app, independent of what's actually scheduled to ship. It is not
  a scope/priority list; don't build something just because it's listed there without confirming
  scope with the user first.
- **Before implementing any feature or network call**, read [docs/api-reference.md](docs/api-reference.md)
  — it is the source of truth for every REST endpoint, Firebase Realtime Database path, and Ably
  channel this app talks to, with the exact request shape and which `Repository` protocol each one
  belongs to. Don't guess an endpoint or invent a field — if it's not in that file, check with the
  user before assuming it exists.
- **Before making an architectural or layering decision**, read [docs/architecture.md](docs/architecture.md)
  — layer diagram, module layout, the gap analysis against the Flutter source, and the build-out
  roadmap. It also lists open decisions that are not yet settled — flag it instead of picking silently
  if a task depends on one of those.
- Auth quirk to preserve exactly: the backend takes the token as a **query parameter**, not a header,
  and has **no refresh-token endpoint** — 401/403 means clear the session and go to login. Do not add
  a refresh flow the backend doesn't support.
- The project scaffold already fixes SwiftUI, iOS 18.5, and Swift 5.0 — don't reopen those.
