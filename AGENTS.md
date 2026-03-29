# Repository Guidelines

## Project Structure & Source of Truth
- Read docs from both locations when relevant:
  - `docs/` for committed, application-facing docs such as release, usage, and configuration docs
  - `.local/docs/` for local working specs, implementation notes, feature plans, and progress tracking
- `.local/` is gitignored and is intentionally **not** for committed project docs.
- When working on a large feature, document the feature spec/progress in `.local/docs/` and keep it out of git unless the user explicitly asks to promote it into committed docs.
- Planned code layout:
  - `Sources/SignalBarCore`: path monitoring, DNS/HTTP probes, history, aggregation, diagnosis, snapshot building
  - `Sources/SignalBar`: app lifecycle, stores, status item, icon rendering, menus, settings
  - `Tests/SignalBarCoreTests`: domain, aggregation, diagnosis, probe classification tests
  - `Tests/SignalBarTests`: UI-state mapping and app-level behavior tests
- If implementation diverges from the docs, update the relevant local doc in the same change.
- Keep `docs/` reserved for relevant application documentation that should live in git long-term.
- New user-facing features should always add or update committed documentation in `docs/`.

## Product Guardrails
- The default toolbar visualization is **semantic layered bars**, not a generic score.
- The 4 semantic bars are fixed and always mean:
  1. `Link`
  2. `DNS`
  3. `Internet`
  4. `Quality`
- Preserve the distinction between:
  - **core internet health**
  - **watched-service health**
- A watched/custom target failure must **not** make the core internet bars look broken by default.
- Prefer lightweight, continuous diagnostics over heavy tests:
  - use path monitoring
  - use small DNS/HTTPS probes
  - avoid speed tests in v1
  - avoid packet capture or privileged tooling
- SignalBar is a diagnosis tool first. Raw numbers matter, but diagnosis quality matters more.

## Build, Test, Run
- When the Swift package exists, use SwiftPM first:
  - `swift build`
  - `swift test`
- If helper scripts are added later (for packaging or relaunching the menu bar app), prefer those documented scripts over ad-hoc commands.
- Before handoff on code changes, run the relevant checks that exist in the repo:
  - `swift build`
  - `swift test`
- To verify the current GitHub Actions CI job will pass locally, run the same categories of checks as `.github/workflows/ci.yml`:
  - `./scripts/lint.sh`
  - `bash -n run-menubar.sh`
  - `bash -n stop-menubar.sh`
  - `bash -n scripts/release_common.sh`
  - `bash -n scripts/check_release_prereqs.sh`
  - `bash -n scripts/setup_notarytool_profile.sh`
  - `bash -n scripts/package_app.sh`
  - `bash -n scripts/sign_release.sh`
  - `bash -n scripts/verify_release.sh`
  - `bash -n scripts/release_local.sh`
  - `bash -n scripts/release_public.sh`
  - `bash -n scripts/publish_github_release.sh`
  - `bash -n scripts/release_github_local.sh`
  - `bash -n scripts/render_screenshots.sh`
  - `swift build`
  - `swift test`
- For docs-only changes, build/test is optional unless the user asks for validation.

## Coding Style & Architecture
- Target **Swift 6 strict concurrency** where practical.
- Prefer small, typed, `Sendable` structs/enums and explicit domain models.
- Keep networking/diagnosis logic in `SignalBarCore`; keep UI/rendering logic in `SignalBar`.
- Use a dedicated mapping layer from domain snapshot to UI state. Do **not** mix diagnosis rules into the icon renderer.
- The icon renderer should render from a visual contract such as `ToolbarVisualState`, not from raw probe data.
- Prefer a SwiftUI + AppKit hybrid:
  - AppKit for `NSStatusItem` and menu hosting
  - SwiftUI for settings and menu content views
- Prefer modern Observation APIs (`@Observable`, `@Bindable`, `@State`) over legacy `ObservableObject` unless a specific integration requires otherwise.

## Probe & Diagnosis Rules
- `NWPathMonitor` is the always-on source for local path state.
- DNS health should come from explicit resolver probes plus supporting HTTP timing evidence.
- Internet health should come from lightweight HTTPS probes and `URLSessionTaskMetrics`.
- Quality should primarily reflect latency, jitter, spike behavior, and rolling reliability.
- Respect the layer precedence chain:
  1. Link
  2. DNS
  3. Internet
  4. Quality
- If an earlier layer fails, later layers should usually become **unavailable**, not automatically failed.
- Keep diagnosis logic mostly pure and easy to unit test.

## Defaults to Preserve
- Default control targets:
  - Apple: `https://www.apple.com/library/test/success.html`
  - Cloudflare: `https://cp.cloudflare.com/generate_204`
  - Google: `https://www.google.com/generate_204`
- Default display mode: semantic layered bars
- Default animation level: subtle
- Default probe approach: staggered lightweight probes, not burst sweeps
- Default history strategy in v1: in-memory rolling history, not persistent probe storage

## Testing Guidelines
- Add focused tests for new behavior.
- Prioritize tests for:
  - diagnosis classification
  - layer aggregation
  - success-rate / latency / jitter calculations
  - downstream-unavailable mapping
  - toolbar/menu view-state mapping
- When icon rendering exists, add coverage for key visual states:
  - healthy
  - offline
  - DNS failed
  - internet failed
  - quality degraded
  - watched-target badge
- Prefer deterministic fixtures over live-network tests.

## Commit Guidelines
- Follow conventional commit format:
  - `feat: ...`
  - `fix: ...`
  - `docs: ...`
  - `refactor: ...`
  - `test: ...`
  - `chore: ...`
- Keep commits scoped and descriptive.

## Agent Notes
- Read both `docs/` and `.local/docs/` before implementing features that touch UX, icon behavior, diagnosis, architecture, release flow, usage, or configuration.
- Prefer `.local/docs/` for active design work, feature specs, and progress notes.
- If you change the icon semantics, also update `.local/docs/ICON_STATES.md`.
- If you change runtime architecture or core types, also update `.local/docs/IMPLEMENTATION.md`.
- If you change product behavior or defaults, also update `.local/docs/SPEC.md`.
- When a feature is large or spans multiple sessions, create/update a feature-specific note in `.local/docs/`.
- If a feature changes what users can do, how they configure the app, or how the app behaves visibly, also add/update the relevant committed documentation in `docs/`.
- Do not add extra dependencies or new probe types without confirming they fit the product goals.
- Do not introduce persistent telemetry, background daemons, or invasive monitoring without explicit approval.
- Keep the app lightweight, local-first, and menu-bar-focused.
