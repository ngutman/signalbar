# Privacy

SignalBar is designed to be lightweight, local-first, and respectful of user privacy.

## What SignalBar does

SignalBar continuously measures network health using small, explicit probes.

Current data sources:
- `NWPathMonitor` for local path/link state
- DNS resolution probes against configured control targets
- lightweight HTTPS probes against configured control targets
- optional watched-target probes when you configure a watched target

## Default control targets

By default, SignalBar uses:
- Apple — `https://www.apple.com/library/test/success.html`
- Cloudflare — `https://cp.cloudflare.com/generate_204`
- Google — `https://www.google.com/generate_204`

These are used to distinguish local problems from broader upstream or service-specific issues.

## What SignalBar does not do

SignalBar currently does **not**:
- collect telemetry
- send analytics to a backend
- capture packets
- inspect application traffic
- require root privileges
- run invasive background daemons
- perform bandwidth or speed tests

## Local storage

Today, SignalBar stores only lightweight local preferences such as:
- source mode
- display mode
- color mode
- selected history metric/window
- paused state
- optional watched target configuration

Current history is in-memory only and is not persisted across app restarts.

## Watched targets

Watched targets are opt-in.

If you add a watched target, SignalBar will probe it like any other configured endpoint so it can distinguish:
- general internet problems
- service-specific problems

## Permissions

SignalBar is built as a menu bar utility and currently relies on standard macOS networking capabilities.

It does not currently require special permissions such as:
- Accessibility
- Screen Recording
- Full Disk Access

## Current limitations

SignalBar is an early prototype and its privacy posture should be considered in that context. Future features such as packaging, updates, or persistent history will be documented here before public release artifacts are published.
