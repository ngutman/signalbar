# Changelog

All notable changes to this project will be documented in this file.

The format is inspired by [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project follows semantic versioning once public release tags begin.

## [0.1.0] - 2026-03-28

### Added
- initial public-source prototype of the SignalBar macOS menu bar app
- live path, DNS, internet, and quality diagnosis model
- watched target support and service-specific issue distinction
- rolling in-memory history graphs and preview scenarios
- source-based packaging, signing, screenshot, and local release scripts
- public documentation for development, architecture, privacy, status, and release flow
- GitHub Actions CI, issue templates, PR template, and repo metadata scaffolding

### Changed
- refactored the app into smaller builders, stores, menu views, and snapshot helpers
- added real pause/resume behavior and stale-state dimming
- extracted probe scheduling policy from `HealthEngine`

### Tested
- `swift build`
- `swift test`
- SwiftFormat / SwiftLint validation
- menu bar smoke launch via `run-menubar.sh`
- local signed release packaging and verification
