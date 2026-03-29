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
- watched-target support
- rolling in-memory history graphs
- pause/resume probing
- stale-state dimming
- source-based packaging, signing, and verification scripts

## Good enough for public review

The project is already in good shape for:
- architecture review
- refactoring collaboration
- SwiftUI/AppKit menu bar experimentation
- diagnosis model discussion
- source-based local builds and testing

## Still intentionally early

The following areas are still incomplete or expected to evolve:
- broader settings/preferences UI
- richer target configuration UX
- persistent history storage
- public release distribution and notarization polish
- more advanced scheduler/backoff behavior
- broader documentation and user onboarding polish over time

## Near-term priorities

1. continue runtime orchestration cleanup
2. improve scheduler/backoff behavior
3. improve packaging/release ergonomics
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
