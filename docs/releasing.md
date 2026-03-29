# Releasing SignalBar

SignalBar is currently a **source-first** project, but the repository includes scripts to produce both a local signed release artifact and a real notarized public-release artifact when the required Apple credentials are available.

## Release posture

Today, SignalBar supports:
- packaging a `.app` bundle from SwiftPM output
- signing the app bundle and release zip
- verifying the signed bundle and zip locally
- notarization and stapling when a valid `notarytool` keychain profile is available

This is enough for local release validation before any GitHub release process exists.

## Version metadata

Version information lives in `version.env`.

## End-to-end local release

Create, sign, and verify a local release artifact:
```bash
./scripts/release_local.sh
```

Create a Gatekeeper-ready public release artifact:
```bash
SIGNALBAR_NOTARY_PROFILE=signalbar-notary ./scripts/release_public.sh
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

### 4. Store notarytool credentials in the keychain
```bash
./scripts/setup_notarytool_profile.sh signalbar-notary /path/to/AuthKey_XXXXXXX.p8 KEYID ISSUERID
```

### 5. Check public release prerequisites
```bash
SIGNALBAR_NOTARY_PROFILE=signalbar-notary ./scripts/check_release_prereqs.sh
```

## Signing identities

`sign_release.sh` prefers identities in this order:
1. `Developer ID Application:`
2. `Apple Distribution:`
3. `Apple Development:`
4. ad-hoc signing fallback

For a real public GitHub-distributed macOS release, you should use **`Developer ID Application`** plus notarization.

You can override the identity with:
```bash
APP_IDENTITY="Your Signing Identity" ./scripts/sign_release.sh
```

## Notarization

For real public macOS distribution, the required flow is:
- `Developer ID Application` signing
- notarization via `notarytool`
- staple the ticket to the app
- package the final distributable zip from the stapled app bundle

The repository now provides:
- `scripts/setup_notarytool_profile.sh` to store credentials in the keychain
- `scripts/check_release_prereqs.sh` to validate local readiness
- `scripts/release_public.sh` to run the package → sign → notarize → staple → verify flow

## Verification expectations

`verify_release.sh` performs local validation such as:
- `codesign --verify --deep --strict`
- signature inspection
- zip extraction checks
- smoke launch of the packaged app bundle
- optional `stapler validate`
- optional `spctl --assess` hard-fail mode for public releases

Gatekeeper / notarization checks depend on a notarized `Developer ID Application` build.

## Typical release prerequisites for future public artifacts

- stable version in `version.env`
- updated `CHANGELOG.md`
- green `swift build`
- green `swift test`
- green lint checks
- a valid signing identity
- optional notarization credentials for public distribution
