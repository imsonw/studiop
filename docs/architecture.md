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
  template's model container is meant to be built on directly. **Order history (Sprint 8, F-023) is
  now the one confirmed exception** — see "Decided" below; every other feature is still an open
  per-feature call.

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
    Auth/          Entities/ Repositories/ UseCases/<Sub-domain>/  (Auth, Biometric, User, Address,
                   Notification) — UseCases/ further split one level by sub-domain/Repository
                   once it reached 23 files (2026-07-16): UseCases/Auth/, UseCases/User/,
                   UseCases/Biometric/, UseCases/Address/, UseCases/Notification/. NOT split by
                   screen like Presentation below — a UseCase isn't 1:1 with one screen (e.g.
                   FetchUserInfoUseCase is called from both Login and Biometric-login), so its
                   natural grouping key is which Repository it wraps, not which View calls it.
                   Entities/ and Repositories/ stay flat for now — still small (~2 and ~5 files).
    Live/          Entities/ Repositories/ UseCases/  (Stream, Studio)
    Games/         Entities/ Repositories/ UseCases/  (Blackjack, Lucky Wheel)
    Commerce/      Entities/ Repositories/ UseCases/  (Store, Order, Payment, Review)
    Chat/          Entities/ Repositories/ UseCases/  (Chat, Media, StaticContent, Location)
  Data/
    Shared/
      DTOs/           Feature-agnostic wrappers reused across domains — e.g. `DataResponseDTO<T>`
                      for this backend's general `{"data": ...}` success envelope (confirmed
                      Sprint 4, see api-reference.md's Auth mechanism section). Anything that
                      doesn't mention a specific domain's fields belongs here, not in a feature
                      folder.
    <Feature>/
      Network/       RemoteXRepository implementations (REST)
      Firebase/       FirebaseLiveRoomDataSource, FirebaseReactionDataSource, ... (Live only)
      Ably/           AblyChatDataSource (Chat only)
      DTOs/
      DependencyKeys/ one swift-dependencies `DependencyKey` + `DependencyValues` extension per
                      repository protocol, wiring it to its live implementation (and a `.testValue`/
                      `.previewValue` for SwiftUI previews and tests)
  Features/
    Auth/ Home/ Live/ Stream/ Store/ Cart/ Order/ Chat/ ...
      <Screen>/    View + ViewModel co-located per screen/flow (e.g. Auth/Login/,
                   Auth/DeleteAccount/) — reads dependencies via `@Dependency`, (feature-local)
                   Coordinator. Cross-screen shared files (e.g. AuthValidationError+Localized.swift)
                   stay at the feature root, not inside any one screen's folder.
```

**Presentation is organized by screen within a feature, not by `View`/`ViewModel` type** (revised
2026-07-16, once `Features/Auth/` grew to ~14 View files and ~14 ViewModel files across very
different screens — Login and DeleteAccount have nothing to do with each other beyond both living
under "Auth"). Same reasoning as the Domain revision below: grouping by type doesn't scale as a
feature accumulates screens, and it forces you to visit two far-apart folders to see one screen's
whole implementation. Each screen/flow (Login, Register, VerifyAccount, ResetPassword,
CollectEmail, Biometric, AddressBook, Profile, DeleteAccount, ...) is its own subfolder holding
both its View(s) and ViewModel; a file genuinely shared across multiple screens within the feature
(validation-error localization, a credential value type used by more than one screen) stays at the
feature's root instead of being forced into one screen's folder. Apply this same per-screen
grouping to other `Features/<X>/` folders once they grow past a handful of screens — no need to
retrofit ones that are still small.

**Domain is organized by feature, not by type** (revised after Sprint 2 — originally this doc
suggested a flat `Domain/Entities/`, `Domain/Repositories/`, `Domain/UseCases/` split across all 16
repository domains at once). Reasoning: the architectural rule Clean Architecture actually enforces
is dependency *direction* (Domain imports nothing from Data/Core), not folder layout — grouping by
type vs by feature are equally valid under that rule. By-type was fine for Sprint 2's one-shot,
parallel build of all 16 domains at once, but a single flat `UseCases/` folder was already at 92
files after just one sprint; grouping by feature keeps each folder's file count bounded as more
sprints add to it, and gives each feature a natural boundary for a future local Swift Package if the
team wants compiler-enforced isolation between features later. `Data/` should follow the same
per-feature grouping once Sprint 3 builds it, for consistency.

**Within a feature, `UseCases/` further splits by sub-domain/Repository once it's large enough**
(applied to `Domain/Auth/UseCases/` 2026-07-16 at 23 files: `UseCases/Auth/`, `UseCases/User/`,
`UseCases/Biometric/`, `UseCases/Address/`, `UseCases/Notification/`). This is a **different**
grouping key than Presentation's per-screen split above, deliberately: a UseCase is not 1:1 with
one screen the way a View+ViewModel pair is — `FetchUserInfoUseCase`, for example, is called from
both the Login and Biometric-login flows. Grouping UseCases by screen would be the wrong
abstraction; grouping by which Repository protocol they wrap is the boundary that actually matches
how they're reused. `Entities/` and `Repositories/` stay flat for now (only ~2 and ~5 files) —
split them the same way if they ever grow large enough to warrant it.

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
- **Local persistence for Order history (Sprint 8, F-023): SwiftData** — confirmed with the user
  2026-07-16, resolving the "SwiftData vs. simpler cache, decide per-feature" question below *for
  this one feature specifically*, not as a blanket replacement. Chosen deliberately (over a
  simpler UserDefaults/in-memory cache) as this project's hands-on SwiftData deep-dive — see
  [senior-skills-roadmap.md](./senior-skills-roadmap.md) §3 for the full reasoning, including a
  caveat: this teaches SwiftData's `@Model`/`ModelContext`, not classic Core Data's
  `NSManagedObjectContext` (private/main queue context) vocabulary, if that specific distinction
  matters for an interview. Every other feature keeps deciding its own persistence need
  independently, per the item below — Keychain for secrets (auth token, and Sprint 6's biometric
  device_id/token pairing), `UserProfileCache` for the profile, and so on.

## Open decisions (not yet answered)

- Is RTMP broadcasting (the seller/streamer side) in scope for v1, or does v1 ship viewer/bidding
  only first?
- Forum and Marketplace: confirm with stakeholders whether they're in scope at all, given they're
  off by default in the source app.
- Local persistence for every feature *other than* Order history (see "Decided" above) — still a
  genuine per-feature call, not resolved wholesale by the Order history decision.

## Senior-skills roadmap (added 2026-07-16)

Alongside feature-parity with the Flutter source, this project is also the user's deliberate vehicle
for leveling up to Senior iOS — full gap analysis (CV vs. current project vs. interview-prep
questions) and exactly where each technique gets injected into the sprint plan lives in
[senior-skills-roadmap.md](./senior-skills-roadmap.md). Summary of what it added to this roadmap:
MapKit location picker (Sprint 6), a GCD/Semaphore-vs-TaskGroup image-loading comparison +
Instruments checkpoint (Sprint 7), the SwiftData decision above (Sprint 8), a deliberate data-race
→ `actor`/`@MainActor` case study + second Instruments checkpoint (Sprint 10), SSL Pinning +
Crashlytics + CI/CD-Fastlane (Sprint 13), and a new dedicated Sprint 14 for a purposeful test suite
(Domain UseCases + 1-2 complex ViewModels) — inserted before the already-deferred RTMP-streaming and
Community sprints (now 15 and 16) rather than after them.
