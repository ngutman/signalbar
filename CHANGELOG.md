# Changelog

All notable changes to this project will be documented in this file.

The format is inspired by [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project follows semantic versioning once public release tags begin.

## [0.1.0] - 2026-03-29

### Added
- initial public-source prototype of the SignalBar macOS menu bar app
- live path, DNS, internet, and quality diagnosis model
- watched target support and service-specific issue distinction
- rolling in-memory history graphs and preview scenarios
- source-based packaging, signing, screenshot, notarization, and local release scripts
- a custom app icon asset set and packaged app icon generation
- local GitHub release publishing scripts for notarized builds
- public documentation for development, architecture, privacy, status, and release flow
- GitHub Actions CI, issue templates, PR template, and repo metadata scaffolding

### Changed
- refactored the app into smaller builders, stores, menu views, and snapshot helpers
- changed the default toolbar icon to segmented lines
- removed user-facing preview/debug controls from the app UI
- fixed the history metric menu resizing bug so the menu shrinks and grows with content
- added real pause/resume behavior and stale-state dimming
- extracted probe scheduling policy from `HealthEngine`

### Tested
- `swift build`
- `swift test`
- SwiftFormat / SwiftLint validation
- menu bar smoke launch via `run-menubar.sh`
- local signed release packaging and verification
- notarized public release packaging, stapling, Gatekeeper verification, and GitHub release publishing
