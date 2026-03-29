# Project status

SignalBar is currently an **early public-source prototype**.

The repository is intended to be usable, buildable, and reviewable in public, but the project is still evolving.

## Implemented today

- live menu bar app for macOS 14+
- segmented-line toolbar icon by default, with semantic bars also available
- live path monitoring
- live DNS probing
- live internet reachability probing
- derived quality classification from latency, jitter, and reliability
- watched-target support with a dedicated settings window editor
- rolling in-memory history graphs
- refresh cadence presets plus a custom manual interval from the General settings pane
- pause/resume probing
- launch at login from the General settings pane
- stale-state dimming
- source-based packaging, signing, notarization, verification, and local GitHub release scripts

## Good enough for public review

The project is already in good shape for:
- architecture review
- refactoring collaboration
- SwiftUI/AppKit menu bar experimentation
- diagnosis model discussion
- source-based local builds and testing

## Still intentionally early

The following areas are still incomplete or expected to evolve:
- broader settings/preferences UI beyond the first dedicated settings window
- richer target configuration UX
- persistent history storage
- fully GitHub-hosted release automation without local operator involvement
- Low Power Mode cadence backoff and other more advanced scheduler/adaptive behavior
- broader documentation and user onboarding polish over time

## Near-term priorities

1. continue runtime orchestration cleanup
2. add Low Power Mode cadence backoff and more advanced adaptive scheduler behavior
3. add optional GitHub-hosted release automation later
4. add persistent history
5. continue UI and configuration polish

## What this repo is not claiming yet

SignalBar is not yet claiming to be:
- a fully polished consumer release
- a bandwidth test tool
- a privileged network diagnostic suite
- a persistent network-monitoring daemon

The current promise is narrower and more useful:

> SignalBar helps you understand whether the network is unhealthy right now, and which layer is likely failing first.
