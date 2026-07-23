# Senior iOS Skills Roadmap

Studiop is not only a feature rebuild — it's the vehicle for leveling up from "Mobile Developer"
(current CV title) to Senior iOS Developer, given that the last ~4 years of day-to-day work
(Webkom Studio, Soteco, Hill Tech) has been predominantly Flutter/cross-platform with only native
"bridge module" work (RTMP camera plugin patches, platform-channel media players, signature
verification, SSL pinning) rather than full native Swift/SwiftUI ownership. The last period of deep
native Swift work (Axon Active, 2018–2021) is 4+ years stale. This document records which senior-
level techniques the 15-sprint feature roadmap (`product_backlog.yaml`) doesn't naturally exercise
on its own, where each one gets deliberately injected, and why that specific spot was chosen —
confirmed with the user 2026-07-16.

**Principle:** don't pad the app with unrelated past skills (ARKit, deep MapKit/Core Location) just
to "use" them — studiop's actual feature set (per [features.md](features.md)) doesn't have a
natural home for most of those, and inventing scope for that reason alone is resume-padding, not
engineering judgment. Every addition below is justified by something the app genuinely needs or a
decision already left open — never a bolt-on.

## Gap analysis

Source: CV (`_NguyenNgocSon_CV_ios.pdf`) claims these skills; a friend's interview-prep questions
(GCD/Operation, dispatch semaphore, data race, actor/MainActor, CoreData vs Realm, private/main
context, SSL pinning, Crashlytics) are the concrete signal for what's actually being tested for.
Cross-checked against the project: none of the topics below appear anywhere in `docs/` as of
2026-07-16 — the 15-sprint roadmap up to this point is pure feature-parity work.

| Skill | CV signal | Last exercised | Studiop status before this doc |
|---|---|---|---|
| GCD / `OperationQueue` / `DispatchSemaphore` | Listed, but recent roles are Flutter | Axon Active era (pre-2021) | Not used — project is 100% `async`/`await` so far |
| Data races, `actor`/`@MainActor` | Implicit (Swift Concurrency listed) | This project (Sprint 4's `@MainActor` fix) | Understood in isolation, never exercised against a *real* concurrent-write bug |
| CoreData vs Realm, private/main context | Listed (Core Data) | Axon Active era | Not used — local persistence explicitly left open in `architecture.md` |
| SSL Pinning | Listed (from Flutter/native-bridge work at Hill Tech) | Native-bridge context, not a full Swift `URLSession` implementation | Not used — `NetworkClient` has no pinning |
| Crashlytics | Not listed at all | — | Not used — no crash reporting in the app |
| CI/CD, Fastlane | Listed (tools) | Likely Flutter-side CI | Not used — no pipeline for this project |
| Xcode Instruments (Leaks, Allocations, Time Profiler) | Listed | Axon Active era | Not used — no profiling pass has been run |
| ARKit, deep MapKit/Core Location | Listed, strong past depth (VibeARMap, Lucerne/Zurich Lake apps) | Axon Active era | **No natural fit** — studiop has no AR feature; only a bare `location` string field on `Address` |

## Where each gap gets closed

### 1. GCD / `OperationQueue` / `DispatchSemaphore` → Sprint 7 (Store/Catalog), product images

Product grids/carousels (F-017/F-018) are exactly the classic "download N images concurrently"
interview scenario. Plan: implement it twice, side by side, when Sprint 7 is actually planned —
(a) a `DispatchSemaphore`-gated `DispatchQueue.concurrentPerform`/GCD version (the version that
answers the interview question from memory), and (b) the version that actually ships in the app,
using a `TaskGroup`/actor-based image cache. Comparing both in the same sprint's dev notes is the
point — not shipping the legacy GCD version.

### 2. Data races & `actor`/`@MainActor` → Sprint 10 (Live streaming)

This is the **only** sprint with genuine concurrent writers: Firebase RTDB pushes chat messages,
reactions, and bid updates continuously into shared UI state, from callbacks that are not
guaranteed to land on the main thread. Sprint 4 already fixed one `@MainActor`-shaped bug
reactively (see `learning-notes-sprint-004.md` §7); Sprint 10 is the chance to reason about it
*proactively* — design the RTDB listener boundary so it hops to `@MainActor` deliberately, and (for
the learning value) deliberately reproduce the race once without it before fixing it, rather than
only ever seeing the fixed version.

### 3. Local persistence: **SwiftData**, deliberately, on Order history → Sprint 8

`architecture.md`'s open decision ("SwiftData vs. a simpler cache, decide per-feature") gets
resolved for this one feature: **Order history** (F-023) gets a SwiftData-backed local cache so
already-placed orders stay visible offline. Chosen over Product catalog because it's a
self-contained vertical (list/detail, no fast-changing price/stock fields to reconcile), moderate
enough complexity to actually exercise `@Model`, `ModelContainer`/`ModelContext`, and
background-context inserts/fetches without turning into its own sub-project.

**Caveat worth knowing, not a blocker:** the friend's interview question was specifically about
*CoreData's* `NSManagedObjectContext` (private queue vs. main queue context) — SwiftData's
`ModelContext` is a related but distinct API (SwiftData is often backed by Core Data under the
hood, but you don't write `NSManagedObjectContext` code directly). Building this in SwiftData
teaches SwiftData well — genuinely valuable, Apple's current direction — but doesn't by itself
rehearse the exact CoreData vocabulary that question used. If that specific question matters for an
upcoming interview, it's worth a short *reading* pass on classic Core Data context types
separately; no need to build a second, parallel Core Data feature just to tick that box.

Other features keep whatever simpler cache they already use (Keychain for the token,
`UserProfileCache` for the profile) — this decision is scoped to Order history, not a blanket
"replace everything with SwiftData."

### 4. SSL Pinning → Sprint 14 (new — see below), extending `NetworkClient`

Added to the `URLSessionNetworkClient` built in Sprint 1, via `URLSessionDelegate`
(`urlSession(_:didReceive:completionHandler:)`) validating the server's certificate/public key
against a pinned value. Realistic senior narrative: ship functionality fast first, harden
transport security before a release — not a green-field requirement from day one.

### 5. Crashlytics → Sprint 14

Firebase already enters the project in Sprint 10 (RTDB) — adding Crashlytics alongside it in the
hardening sprint is a small marginal step, and worth understanding *how* it actually works (dSYM
upload, symbolication, uncaught-exception/signal handlers) rather than just dropping in the SDK.

### 6. CI/CD & Fastlane → Sprint 14

A Fastlane lane (build → archive → TestFlight) plus a CI config (GitHub Actions) running static
analysis on every push. This is the one item here with zero code-level "senior technique" depth by
itself, but it's a real gap versus the CV's claimed tooling, and a portfolio project with a working
pipeline reads very differently from one that doesn't.

### 7. Instruments profiling checkpoints → end of Sprint 7 and end of Sprint 10

Rather than one profiling pass bolted on at the very end of the whole roadmap, two checkpoints at
the two heaviest sprints for memory/allocations: Sprint 7 (image-heavy product grids/carousels) and
Sprint 10 (video playback + continuous RTDB writes — the two realistic places a retain cycle or
runaway allocation would actually show up). Leaks, Allocations, and Time Profiler each get one
deliberate pass, findings recorded in that sprint's `dev_report`/`qa_report`.

### 8. Testing & Quality → new Sprint 14 renamed, RTMP/Community pushed to 15/16

Feature sprints keep the "no unit tests" policy (`.claude/skills/scrum/SKILL.md`'s Testing Policy —
unchanged, still about build speed). But the CV's own "XCTest, 70%+ coverage" bullet means a
portfolio project with *zero* tests anywhere invites an obvious interview question with a weak
answer. Resolution: a dedicated **Sprint 14 — Testing & Quality Hardening**, inserted right after
Sprint 13 (Cross-cutting hardening) rather than at the literal tail end — RTMP broadcasting and the
Forum/Marketplace community layer are already flagged low-priority/deferred/go-no-go-pending in the
backlog, so putting the testing chapter *before* them (not after) makes it far more likely to
actually get done, and it packages better as "the core product plus its hardening story," with the
two optional/deferred feature areas trailing after. Scope: purposeful tests for Domain UseCases
(pure logic, cheapest to test, highest signal) and 1–2 of the more complex ViewModels (Live
streaming's concurrent-write handling from item 2 above is a strong candidate) — not blanket
coverage of every screen.

### Explicitly not forced in

- **ARKit** — no AR feature anywhere in the source app's feature inventory; already a proven skill
  from Axon Active, doesn't need re-proving in an app with no camera/AR use case.
- **Deep MapKit/Core Location** — beyond the one deliberate addition below, the app has no
  navigation/mapping feature. The one exception (next section) is justified by an existing field,
  not invented from scratch.
- **AI-powered feature (smart search / chatbot, à la the Soteco role)** — the source Flutter app has
  no such feature in `features.md`; adding one would be scope invention against the "rebuild
  fidelity" goal of this project, not a rebuild of something real. If wanted as a portfolio
  differentiator, treat it as a clearly-separate side project, not a studiop backlog item.

### 9. MapKit location picker → Sprint 6, F-014 (Address book) — approved scope-add

`Address.location` already exists as a plain string field (Sprint 2). Sprint 6's address-book
create/edit form gains a "pick on map" affordance (iOS 17+ `Map`/`MapReader` API +
`CLGeocoder`/`CLLocationManager` for reverse-geocoding and current-location) alongside the manual
text field — refreshes MapKit/Core Location against the modern SwiftUI `Map` API (different surface
than the UIKit-era `MKMapView` this CV's past experience used). See
`.agents/artifacts/sprint-006/sprint_plan@v1.yaml` (F-014, TASK-5) for the concrete acceptance
criteria — this is the only sprint plan detailed enough yet to encode it directly; the others
above are recorded here and will be expanded into each sprint's own `sprint_plan@v1.yaml` task list
when that sprint is actually started, same as every prior sprint in this project.

## Summary table — sprint → senior-skill addition

| Sprint | Feature-roadmap content (unchanged) | Senior-skill addition |
|---|---|---|
| 6 | Biometric, Profile & address book, Account deletion | MapKit location picker (F-014) |
| 7 | Store/Catalog + Cart/Checkout | GCD/Semaphore vs. TaskGroup image-loading comparison; Instruments checkpoint |
| 8 | Orders, Payment, Reviews | SwiftData-backed offline cache for Order history (F-023) |
| 9 | Home/Dashboard, bottom tab shell | — |
| 10 | Live viewing & bidding | Deliberate data-race case study → `actor`/`@MainActor` fix; Instruments checkpoint |
| 11 | Chat & Notifications | — |
| 12 | Mini-games | — |
| 13 | Cross-cutting hardening (nav, localization, theming, feature flags) | — (unchanged) |
| **14 (new)** | **Testing & Quality Hardening** | SSL Pinning, Crashlytics, CI/CD+Fastlane, purposeful test suite |
| 15 (was 14) | Streaming (seller/broadcaster side) — deferred | — |
| 16 (was 15) | Community layer (Forum, Marketplace) — pinned last | — |
