# SignalBar architecture

SignalBar is split into two main Swift modules:

- `SignalBarCore` — domain models, path monitoring, probing, aggregation, history, and diagnosis
- `SignalBar` — app lifecycle, store layer, status item integration, toolbar icon rendering, and menu UI

This keeps probing and diagnosis testable while letting the app layer stay focused on state mapping and presentation.

## Module layout

```text
Sources/
  SignalBarCore/
    Engine/
    History/
    Models/
    Path/
    Probing/
    Snapshot/
  SignalBar/
    App/
    Icon/
    Menu/
    StatusItem/
    Store/
Tests/
  SignalBarCoreTests/
  SignalBarTests/
```

## Runtime flow

```text
NWPathMonitor
   ↓
PathMonitorService
   ↓
HealthEngine (actor)
   ├─ DNSProbeRunner
   ├─ HTTPProbeRunner
   ├─ ProbeScheduler
   └─ ProbeHistoryStore
   ↓
HealthSnapshot
   ↓
HealthStore (@MainActor, @Observable)
   ├─ ToolbarVisualStateBuilder
   └─ MenuPresentationBuilder
   ↓
StatusItemController / SwiftUI menu views / IconRenderer
```

## Design rules

### 1. Four semantic bars are fixed
The toolbar bars always mean:
1. Link
2. DNS
3. Internet
4. Quality

### 2. Core internet health and watched-service health are separate
A watched target failure should not make the core internet bars look broken when the control targets still look healthy.

### 3. UI should not talk directly to probing primitives
SwiftUI views and status item code should consume derived state such as:
- `HealthSnapshot`
- `ToolbarVisualState`
- `StatusPresentation`

### 4. Diagnosis rules should stay testable
Layer evaluation, diagnosis precedence, metric thresholds, and history aggregation are kept in pure or nearly-pure helpers under `SignalBarCore` where practical.

## Key app-layer pieces

### `HealthStore`
The main observable store that:
- starts the engine
- consumes `AsyncStream<HealthSnapshot>`
- persists lightweight settings via `SettingsStore`
- derives stale state and preview/live behavior
- exposes actions like refresh, pause, and resume

### `StatusItemController`
Owns the `NSStatusItem`, menu rebuilds, and menu actions.

### `ToolbarVisualStateBuilder`
Maps domain snapshots and one-minute history into the compact toolbar icon contract.

### `MenuPresentationBuilder`
Maps a domain snapshot into user-facing menu copy and row state.

## Key core-layer pieces

### `HealthEngine`
An actor that coordinates:
- path updates
- DNS sweeps
- HTTP sweeps
- history recording
- snapshot emission

### `ProbeScheduler`
Tracks which probe targets are due for DNS and HTTP work.

### Snapshot builders / helpers
SignalBar currently composes snapshots from smaller helpers such as:
- `PathDNSHealthSnapshotBuilder`
- `PathOnlyHealthSnapshotBuilder`
- `LayerStatusEvaluator`
- `LayerSnapshotFactory`
- `DiagnosisResolver`
- `SnapshotStatistics`
- `TargetHealthFactory`

## Testing strategy

The repository emphasizes deterministic tests around:
- diagnosis precedence
- layer aggregation
- stale state behavior
- history calculations
- store persistence
- toolbar/menu mapping
- menu rendering size expectations

See `Tests/SignalBarCoreTests` and `Tests/SignalBarTests` for current coverage.
