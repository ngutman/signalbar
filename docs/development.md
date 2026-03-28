# Development

## Requirements
- macOS 14+
- Xcode 26+ or a compatible Swift 6.2+ toolchain
- Homebrew packages recommended for linting:
  - `swiftformat`
  - `swiftlint`

Install lint tools with Homebrew if needed:
```bash
brew install swiftformat swiftlint
```

## Repository layout

```text
Sources/SignalBarCore   # path monitoring, probes, history, diagnosis
Sources/SignalBar       # app shell, stores, icon, menu UI
Tests/SignalBarCoreTests
Tests/SignalBarTests
docs/                   # committed user/developer docs
.local/docs/            # local-only working notes and specs
```

## Common commands

### Build and test
```bash
swift build
swift test
```

### Lint
```bash
./scripts/lint.sh
```

### Run the app locally
```bash
./run-menubar.sh
```

### Stop the app
```bash
./stop-menubar.sh
```

### Render docs screenshots
```bash
./scripts/render_screenshots.sh
```

### Build and verify a local signed release
```bash
./scripts/release_local.sh
```

## Validation checklist

Before handing off a change, run the relevant checks:
```bash
swift build
swift test
./scripts/lint.sh
bash -n run-menubar.sh
bash -n stop-menubar.sh
```

If launch behavior changed:
```bash
./run-menubar.sh
```

If release scripts changed:
```bash
bash -n scripts/package_app.sh
bash -n scripts/sign_release.sh
bash -n scripts/verify_release.sh
bash -n scripts/release_local.sh
```

## Coding guidelines

- Target Swift 6 strict concurrency where practical
- Keep diagnosis and probe logic in `SignalBarCore`
- Keep UI rendering logic in `SignalBar`
- Avoid networking or persistence logic inside SwiftUI view bodies
- Prefer dedicated builder/mapping layers from domain snapshots to UI state
- Preserve the four semantic bars contract: Link, DNS, Internet, Quality

## Docs rules

- use `docs/` for committed, public-facing project docs
- use `.local/docs/` for active design notes and refactoring logs
- when visible behavior changes, update committed docs in the same change

## Release notes for contributors

SignalBar includes source-first packaging and signing scripts. These are intended to make the repo reproducible and release-capable even before GitHub releases exist.

See [docs/releasing.md](releasing.md) for details.
