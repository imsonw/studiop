---
name: scrum
description: >
  AI Multi-Agent Scrum Framework for managing software sprints with PM/TL, Developer, and QA roles.
  Use this skill whenever the user mentions sprint, backlog, scrum, task planning, dev report, QA report,
  or asks to start/resume/continue a sprint. Also auto-loads on session start to detect and resume active
  sprint work — scan /.agents/artifacts/ before waiting for any instructions. Invoke for any request like
  "start sprint", "continue working", "what's next", "initialize project", "PM/TL create sprint plan",
  "DEV implement tasks", "QA run checks", or any reference to agents, artifacts, or the scrum system.
---

# AI Multi-Agent Scrum Framework

## Testing Policy

**Unit tests are turned off project-wide (user decision, 2026-07-16) to prioritize development
speed.** This changes both roles below:
- PM/TL must not add "write unit tests" tasks to a `sprint_plan`.
- DEV must not write or update `XCTest` files as part of implementing a task, and does not gate
  `status: completed` on any test run.
- QA does not run `xcodebuild test` and does not gate `release_ready` on tests. Existing tests in
  the repo may still be left in place, just don't add new ones or re-run the suite as a gate.
- If a task is safety/data-integrity critical, it's fine to flag to the user that tests might be
  worth reconsidering there — but default to skipping.

## On Every Session Start (Mandatory)

Before doing anything else, run the Auto-Resume Protocol:

1. Check if `/.agents/artifacts/` exists. If not, prompt user to initialize (Section: Starting a New Project).
2. Find the highest-numbered sprint folder (e.g. `sprint-005`).
3. Determine the current phase by checking which YAML files exist, then report and immediately begin work:

| Condition | Phase | Action |
|-----------|-------|--------|
| `sprint_plan@vN.yaml` exists, no `dev_report` | DEV start | Create `dev_report@v1.yaml` (`status: in_progress`), start implementing |
| `dev_report@vN.yaml` with `status: in_progress` | DEV resume | Read `tasks_in_progress`, pick up where left off |
| `dev_report@vN.yaml` `status: completed`, no `qa_report` | QA start | Create `qa_report@v1.yaml`, run QA checks |
| `qa_report@vN.yaml` with `release_ready: false` | DEV fix | Re-open dev phase, fix `bugs_found` |
| `qa_report@vN.yaml` with `release_ready: true` | Sprint done | Report to user, offer to start next sprint |

Report detected state: *"Detected Sprint 003, Developer phase in progress. Resuming TASK-3…"* then act immediately.

---

## Directory Structure

```
/.agents/artifacts/
  ├── product_backlog.yaml
  └── sprint-NNN/
      ├── sprint_plan@vN.yaml
      ├── dev_report@vN.yaml
      └── qa_report@vN.yaml
/docs/scrum/
  └── SCRUM_SYSTEM.md
```

All artifact writes must be **versioned** (never overwrite — increment `@vN`).

---

## Role: PM/TL

**Triggers:** "initialize project", "create sprint plan", "plan sprint N", "update backlog"

**Outputs:** `product_backlog.yaml` (once), `sprint_plan@vN.yaml` (each sprint)

### product_backlog.yaml schema
```yaml
project_name: STR
description: STR
sprints:
  - sprint: INT
    goal: STR
    status: pending|completed
    features:
      - id: STR          # e.g. F-001
        title: STR
        description: STR
```

### sprint_plan@vN.yaml schema
```yaml
sprint_goal: STR
backlog:
  - id: STR
    title: STR
    description: STR
    acceptance_criteria: [STR]
tasks:
  - id: STR              # e.g. TASK-1
    owner: DEV|QA
    description: STR
    depends_on: [STR]    # list of task IDs, empty if none
```

**Rules:**
- Break features into atomic tasks with clear dependencies.
- Tasks must have a single owner (DEV or QA).
- After QA signs off a sprint (`release_ready: true`), mark it `completed` in backlog and create the next `sprint_plan@v1.yaml`.

---

## Role: Developer (DEV)

**Triggers:** Sprint plan exists without a completed dev report; user says "implement", "code", "build"

**Inputs:** `sprint_plan@vN.yaml`
**Output:** Code + `dev_report@vN.yaml`

### dev_report@vN.yaml schema
```yaml
status: in_progress|completed
tasks_completed: [STR]
tasks_in_progress: [STR]
remaining_tasks: [STR]
notes: STR
```

**Rules:**
- Follow the task dependency order from `sprint_plan`.
- Update `dev_report` after completing each task (move IDs between arrays).
- Set `status: completed` only when all tasks are done. Do not write or update unit tests as
  part of a task, and do not gate completion on any test run (see Testing Policy above).
- Respect existing project conventions (see [CLAUDE.md](/CLAUDE.md)): Clean Architecture layering —
  Presentation → Domain (Entity/UseCase/Repository protocol) → Data (RepositoryImpl/DataSource) →
  Core (NetworkClient/Environment). Domain never imports networking, Firebase, or Ably. DI via
  swift-dependencies (`@Dependency`, one `DependencyKey` per Repository protocol) — never a manual
  composition root or container library. Backend host/URL lives only in the `Environment` config in
  Core. Auth token travels as a query param, never a header; there is no refresh-token endpoint —
  401/403 clears the session and routes to login.
- Before implementing a feature or network call, check scope against
  [docs/features.md](/docs/features.md) and confirm the exact request shape in
  [docs/api-reference.md](/docs/api-reference.md) — don't guess an endpoint or invent a field.
- Before an architectural/layering decision, check [docs/architecture.md](/docs/architecture.md) for
  open decisions already flagged there; surface it instead of picking silently.

---

## Role: QA Engineer

**Triggers:** `dev_report` exists with `status: completed`; user says "QA", "check", "analyze", "verify"

**Inputs:** `sprint_plan@vN.yaml`, `dev_report@vN.yaml`
**Output:** `qa_report@vN.yaml`

### qa_report@vN.yaml schema
```yaml
static_analysis_passed: BOOL
formatting_passed: BOOL
convention_audit_passed: BOOL
bugs_found: [STR]
release_ready: BOOL
```

**QA Checklist (run in order):**

1. **Static analysis** — `xcodebuild -scheme studiop -destination 'generic/platform=iOS Simulator' build`
   must succeed with no errors → `static_analysis_passed`. If a `.swiftlint.yml` exists, also run
   `swiftlint` and fold its result in; note in `notes` if no linter is configured yet.
2. **Formatting** — if `swiftformat`/`swift-format` is configured for the project, run its `--lint`
   (or equivalent check) mode → `formatting_passed`. If no formatter is set up yet, set
   `formatting_passed: true` and note "no formatter configured" in `notes` rather than failing the sprint on it.
3. **Convention audit** (`convention_audit_passed`) — check all of:
   - Layering respected: Presentation → Domain (Entity/UseCase/Repository protocol) → Data
     (RepositoryImpl/DataSource) → Core (NetworkClient/Environment)
   - Domain layer has zero imports of networking, Firebase, or Ably
   - New Repository protocols get exactly one `DependencyKey`, read via `@Dependency` — no manual
     composition root, singleton, or container library (Factory/Swinject)
   - No hardcoded backend domain/URL outside the `Environment` config in Core
   - Auth token passed as a query parameter (never a header); no refresh-token flow implemented
   - Every network call / Firebase path / Ably channel matches
     [docs/api-reference.md](/docs/api-reference.md) exactly — no invented endpoints or fields

**Rules:**
- If any check fails, list specific issues in `bugs_found`.
- Set `release_ready: true` only when all three booleans are `true` and `bugs_found` is empty.
- If `release_ready: false`, the DEV phase reopens automatically.

---

## Rejection Template

If asked to do something outside your defined role scope:

```yaml
status: rejected
reason: out_of_scope | missing_dependency | schema_violation
detail: STR
```

---

## Starting a New Project

1. User provides MVP roadmap.
2. PM/TL creates `/.agents/artifacts/product_backlog.yaml`.
3. PM/TL immediately creates `/.agents/artifacts/sprint-001/sprint_plan@v1.yaml`.
4. Copy this file to `/docs/scrum/SCRUM_SYSTEM.md` as project documentation.
5. Auto-Resume Protocol takes over from here.

---

## Sprint Lifecycle (DAG)

```
PM/TL: sprint_plan@vN  →  DEV: implement + dev_report@vN  →  QA: qa_report@vN
                                        ↑                              |
                                   (if bugs_found) ←──────────────────┘
                                                    release_ready: true → next sprint
```
