# Contributing

Thanks for your interest in SignalBar.

## Before you change code

Please read:
- [README.md](README.md)
- [docs/development.md](docs/development.md)
- [docs/architecture.md](docs/architecture.md)
- [docs/privacy.md](docs/privacy.md)
- [docs/status.md](docs/status.md)

## Development principles

SignalBar should remain:
- menu-bar-first
- lightweight
- privacy-respecting
- diagnosis-focused
- explicit about the difference between **core internet health** and **watched-service health**

The four semantic bars always mean:
1. Link
2. DNS
3. Internet
4. Quality

Please preserve that contract unless the project explicitly decides to change it.

## Preferred workflow

Validate locally before opening a pull request:
```bash
swift build
swift test
./scripts/lint.sh
bash -n run-menubar.sh
bash -n stop-menubar.sh
./run-menubar.sh
```

If packaging or release scripts changed, also run:
```bash
bash -n scripts/package_app.sh
bash -n scripts/sign_release.sh
bash -n scripts/verify_release.sh
bash -n scripts/release_local.sh
```

## Style

- Swift 6 strict concurrency where practical
- small typed models and pure domain helpers where possible
- keep networking and diagnosis in `SignalBarCore`
- keep UI rendering and menu behavior in `SignalBar`
- keep business logic out of SwiftUI view bodies
- prefer dedicated mapping/builders from domain state to UI state

## Docs

If a change affects visible behavior, defaults, or user workflow, update the relevant committed docs under `docs/` in the same change.

## Commit messages

Use conventional commits:
```text
type(scope): short description
```

Examples:
- `feat: add local release packaging script`
- `docs: document privacy posture`
- `fix(store): refresh on stale menu open`
