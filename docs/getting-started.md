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
- a dedicated settings window for display, targets, and app-level preferences
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

### Segmented lines
The default mode uses four equal-height segments:
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

In live mode, segment fill reflects the **average quality of the past minute** rather than only the latest instant.

### Semantic bars
This alternative mode uses ascending heights for the same four layers.

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
- the app uses live path monitoring by default
- clicking the icon opens a diagnosis-first overview card
- persistent preferences live under `Settings…`
- the chosen display mode, color style, watched target, and paused state are persisted between launches

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

SignalBar supports a basic watched-target flow from `Settings… -> Targets`.

You can:
- add a watched target URL
- edit the watched target
- remove the watched target

When the core internet path looks healthy but the watched target fails, SignalBar surfaces a **service-specific issue** and shows the watched-target badge in the toolbar.

## Settings window

The current settings window includes:
- **General** — pause probing and app behavior notes
- **Display** — toolbar icon and color style
- **Targets** — watched-target configuration
- **About** — app links and build/version information

## More docs

- [README](../README.md)
- [Development](development.md)
- [Architecture](architecture.md)
- [Privacy](privacy.md)
- [Status](status.md)
- [Releasing](releasing.md)
