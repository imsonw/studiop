# Architecture — Studiop

Studiop is an iOS/Swift rebuild of an existing Flutter live-commerce app: a two-sided live-commerce
app (viewers bid in live streams, sellers broadcast and sell) plus a full e-commerce core (catalog,
cart, checkout, orders, reviews), mini-games (Blackjack, Lucky Wheel), and a feature-flagged
community layer (Forum, Marketplace) that is off by default in the source app.

Plan: **reuse the existing backend as-is** (see [api-reference.md](./api-reference.md) for every
endpoint and realtime path), rebuilt behind a Clean Architecture boundary so the API, the realtime
transport (Firebase RTDB / Ably), or even the backend itself can be swapped by changing one binding,
not by touching use cases or views. The backend's domain/host is not hardcoded anywhere outside the
`Environment` config (see api-reference.md → Base configuration) — switching to a self-built backend
later is a one-line edit.

## Confirmed by the project scaffold already in this repo

- **SwiftUI** — `studiopApp.swift` / `ContentView.swift` are the default SwiftUI+SwiftData template.
- **iOS 18.5** deployment target, **Swift 5.0** language mode (`project.pbxproj`).
- SwiftData is present in the template (`Item.swift`, `ModelContainer` in `studiopApp.swift`) but is
  throwaway demo code — decide per-feature whether SwiftData is the local persistence story or
  whether a simpler cache (e.g. plain Keychain/UserDefaults + in-memory) is enough; don't assume the
  template's model container is meant to be built on directly.

## Layers

```
Presentation   SwiftUI Views + ViewModel (@Observable) + Coordinator (navigation)
                    │ depends on
                    ▼
Domain         Entity (plain Swift structs) + UseCase + Repository *protocol*
                    ▲ implemented by
                    │
Data           RepositoryImpl + DataSource (REST / Firebase RTDB / Ably) + DTO↔Entity mapping
                    │ built on
                    ▼
Core           NetworkClient protocol, Environment, Keychain token store, DI via swift-dependencies
```

Dependency rule: Domain has zero imports of networking/Firebase/Ably/UIKit. Presentation and Data both
depend on Domain; Domain depends on nothing. This is what makes "change the API any time" cheap —
swapping a repository implementation, or the environment it points at, never requires touching a
use case or a view.

### Why this is a from-scratch layer, not a refactor

The Flutter source has **no repository abstraction at all** (`grep -r "repository"` across its
`lib/` returns nothing) and **no DI container** — screens call a Cubit, which calls a static
`Service` class directly, which calls Dio/Firebase directly. The `services/*.dart` files map cleanly
onto what will become `RepositoryImpl`s here (one class per domain, see api-reference.md), but the
`Repository` protocols and the use-case layer above them are net-new work, not a port of existing
code.

## Suggested module layout

```
Studiop/
  Core/            NetworkClient, Environment, KeychainStore
  Domain/
    Entities/       one file per entity (User, LiveStream, Product, Order, ...)
    Repositories/    one protocol per domain from api-reference.md
    UseCases/
  Data/
    Network/        RemoteXRepository implementations (REST)
    Firebase/        FirebaseLiveRoomDataSource, FirebaseReactionDataSource, ...
    Ably/            AblyChatDataSource
    DTOs/
    DependencyKeys/  one swift-dependencies `DependencyKey` + `DependencyValues` extension per
                     repository protocol, wiring it to its live implementation (and a `.testValue`/
                     `.previewValue` for SwiftUI previews and tests)
  Features/
    Auth/ Home/ Live/ Stream/ Store/ Cart/ Order/ Chat/ ...
      View, ViewModel (reads dependencies via `@Dependency`), (feature-local) Coordinator
```

Split Core/Domain/Data into local Swift Package targets if the team wants compiler-enforced
layering (importing Data from a View simply won't compile); a single target with folder discipline
is a reasonable starting point if that's too much ceremony for the team size.

## Gap analysis vs. the Flutter source

| Aspect | Flutter today | Needed for Clean Architecture |
|---|---|---|
| State/Presentation | Cubit (flutter_bloc); two state-authoring styles (hand-written vs. `freezed`) coexist | ViewModel + UseCase; view never calls a repository directly |
| Repository | None — services are static classes called directly from Cubits | Protocol in Domain + Impl in Data, wrapping the REST/Firebase/Ably calls in api-reference.md |
| Dependency Injection | Manual singletons (`factory ApiClient()`); `MultiBlocProvider` only injects state, not services | swift-dependencies: a `DependencyKey` per repository protocol, read in ViewModels via `@Dependency` |
| Navigation | Navigator 1.0, ~146 direct `Navigator.push` call sites, no route table | Coordinator/Router per feature — so changing a flow is a localized edit |
| Config/Environment | Constants in `config.dart`, overridden at runtime by Firebase Remote Config | `Environment` struct injected at the composition root; re-resolved after a remote-config fetch |
| Auth token | Query param, no refresh endpoint, 401/403 clears session | Replicate exactly — don't invent a refresh flow the backend doesn't support |

## Roadmap

1. **Core infra** — `NetworkClient` protocol + URLSession implementation (token as query param, `lang`
   header, `device_fw` query param, 401/403 → clear session), `Environment` struct, Keychain token
   storage, add the `swift-dependencies` package.
2. **Domain layer** — Entities + Repository protocols for every domain in api-reference.md (Auth,
   User, Address, Notification, Stream, Studio, Game, Store, Order, Payment, Review). This is a
   direct translation of that file's section headers — no new discovery needed.
3. **Data layer** — implement each Repository: REST via NetworkClient; Firebase RTDB via the
   Firebase iOS SDK for the paths listed under "Realtime layer" in api-reference.md; Ably via the
   Ably Swift SDK for order/support chat. Register each with a `DependencyKey` (`liveValue` = the real
   implementation, `testValue` = a fake for unit tests, `previewValue` for SwiftUI previews).
4. **Vertical slice** — wire Auth end-to-end (login → Keychain → `/users/info` → empty Home) purely
   to prove the four layers talk to each other correctly before building out features.
5. **Feature build-out, by priority**: Store/Cart/Order (highest business value, least technical
   risk) → Live/Stream (most differentiated, most complex — one player per source: RTMP, TikTok,
   Twitch, YouTube, Castr) → Chat/Notification → mini-games → Forum/Marketplace (deferred; off by
   flag even in the source app).
6. **Cross-cutting** — Coordinator navigation, localization (11 locales in the source app), theming,
   feature flags (mirror the Flutter `FeatureFlag` enum).

## Decided

- **DI: [swift-dependencies](https://github.com/pointfreeco/swift-dependencies)** (Point-Free). Each
  Repository protocol gets a `DependencyKey` with a `liveValue` (real implementation), `testValue`,
  and `previewValue`; ViewModels/UseCases read it via `@Dependency(\.xRepository)`. No manual
  composition root, no reflection-based container.

## Open decisions (not yet answered)

- Is RTMP broadcasting (the seller/streamer side) in scope for v1, or does v1 ship viewer/bidding
  only first?
- Forum and Marketplace: confirm with stakeholders whether they're in scope at all, given they're
  off by default in the source app.
