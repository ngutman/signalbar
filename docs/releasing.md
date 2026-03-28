# Releasing SignalBar

SignalBar is currently a **source-first** project, but the repository includes scripts to produce a local signed release artifact.

## Release posture

Today, SignalBar supports:
- packaging a `.app` bundle from SwiftPM output
- signing the app bundle and release zip
- verifying the signed bundle and zip locally
- optional notarization hooks when appropriate credentials are available

This is enough for local release validation before any GitHub release process exists.

## Version metadata

Version information lives in `version.env`.

## End-to-end local release

Create, sign, and verify a local release artifact:
```bash
./scripts/release_local.sh
```

Artifacts are written to `dist/`.

## Individual steps

### 1. Package the app bundle
```bash
./scripts/package_app.sh
```

### 2. Sign the packaged bundle
```bash
./scripts/sign_release.sh
```

### 3. Verify the signed release
```bash
./scripts/verify_release.sh
```

## Signing identities

`sign_release.sh` prefers identities in this order:
1. `Developer ID Application:`
2. `Apple Distribution:`
3. `Apple Development:`
4. ad-hoc signing fallback

You can override the identity with:
```bash
APP_IDENTITY="Your Signing Identity" ./scripts/sign_release.sh
```

## Notarization

For real public macOS distribution, the ideal flow is:
- `Developer ID Application` signing
- notarization via `notarytool`
- staple the ticket to the app

The current scripts are structured so notarization can be added or enabled once the required credentials are available.

## Verification expectations

`verify_release.sh` performs local validation such as:
- `codesign --verify --deep --strict`
- signature inspection
- zip extraction checks
- smoke launch of the packaged app bundle

Gatekeeper / notarization checks may depend on which signing identity is available on the current machine.

## Typical release prerequisites for future public artifacts

- stable version in `version.env`
- updated `CHANGELOG.md`
- green `swift build`
- green `swift test`
- green lint checks
- a valid signing identity
- optional notarization credentials for public distribution
