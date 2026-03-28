# SignalBar getting started

## Current state

SignalBar is an early but already usable macOS menu bar prototype.

The current build includes:
- a runnable macOS menu bar app
- live path monitoring via `NWPathMonitor`
- live DNS probing against default control targets
- live HTTPS probing for internet reachability
- derived quality signals from latency, jitter, and reliability
- rolling in-memory timeline history
- watched target support
- preview scenarios for icon and menu validation
- source-based packaging, signing, and local release verification scripts

## Build from source

From the repository root:

```bash
swift build
swift test
./scripts/lint.sh
```

## Run the menu bar app

```bash
./run-menubar.sh
```

Stop it with:

```bash
./stop-menubar.sh
```

## Build a local signed release

```bash
./scripts/release_local.sh
```

This writes artifacts under `dist/` and verifies the packaged bundle locally.

## Toolbar display modes

SignalBar currently supports two toolbar icon styles.

### Semantic bars
The default mode uses four fixed bars:
1. **Link**
2. **DNS**
3. **Internet**
4. **Quality**

Examples:
- healthy: all four bars filled
- DNS issue: link healthy, DNS failed, later bars unavailable
- internet issue: link and DNS healthy, internet failed, quality unavailable
- quality issue: first three healthy, quality degraded
- watched service issue: core bars healthy with a small badge

In live mode, bar fill reflects the **average quality of the past minute** rather than only the latest instant.

### Segmented pipeline
This mode keeps the same four layers but renders them as equal-height segments so the affected layer is easier to spot.

## Toolbar color styles

### Monochrome
- default
- system-style appearance
- lowest visual noise

### Muted accents
- healthy layers stay neutral
- degraded layers use restrained orange
- failed layers use restrained red
- watched-service badge uses blue

## What to expect

When the app launches:
- a menu bar icon appears
- the app uses **Live path** mode by default
- clicking the icon opens a diagnosis-first overview card
- configuration controls live under compact submenus
- the chosen source, display mode, color style, and paused state are persisted between launches

In **Preview** mode, the app includes these fake states:
- Healthy
- Offline
- DNS failure
- Internet failure
- Quality degraded
- Watched service issue
- Stale healthy

## History views

The menu currently includes these history modes:
- **Ping**
- **Jitter**
- **Reliability**
- **Overview**

### How to read Overview
`Overview` is a per-layer status timeline, not a numeric bar chart.

- each row is one layer: **Link**, **DNS**, **Internet**, or **Quality**
- the X-axis is time across the selected window
- green means healthy
- orange means degraded
- red means failed
- gray means pending or unavailable

This answers: **which layer changed first, and for how long?**

Available timeline ranges:
- **1m** (default)
- **5m**
- **15m**
- **60m**

## Watched target

SignalBar supports a basic watched-target flow from the menu.

You can:
- add a watched target URL
- edit the watched target
- remove the watched target

When the core internet path looks healthy but the watched target fails, SignalBar surfaces a **service-specific issue** and shows the watched-target badge in the toolbar.

## More docs

- [README](../README.md)
- [Development](development.md)
- [Architecture](architecture.md)
- [Privacy](privacy.md)
- [Status](status.md)
- [Releasing](releasing.md)
