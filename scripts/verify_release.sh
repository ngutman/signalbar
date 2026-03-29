#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/version.env"

DIST_DIR="$ROOT_DIR/dist"
APP_NAME="SignalBar"
APP_BUNDLE="$DIST_DIR/${APP_NAME}.app"
ZIP_PATH="$DIST_DIR/${APP_NAME}-${MARKETING_VERSION}.zip"
SUMMARY_PATH="$DIST_DIR/signing-summary.txt"
VERIFY_DIR="$DIST_DIR/verify"
EXTRACT_DIR="$VERIFY_DIR/extracted"
EXTRACTED_APP="$EXTRACT_DIR/${APP_NAME}.app"

if [[ ! -d "$APP_BUNDLE" || ! -f "$ZIP_PATH" ]]; then
  echo "ERROR: expected signed release artifacts are missing. Run scripts/sign_release.sh first." >&2
  exit 1
fi

rm -rf "$VERIFY_DIR"
mkdir -p "$VERIFY_DIR"

codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
codesign -dv --verbose=4 "$APP_BUNDLE" > "$VERIFY_DIR/codesign-details.txt" 2>&1 || true

SPCTL_EXIT=0
spctl --assess --type execute --verbose=4 "$APP_BUNDLE" > "$VERIFY_DIR/spctl.txt" 2>&1 || SPCTL_EXIT=$?
if [[ $SPCTL_EXIT -ne 0 ]]; then
  if [[ "${SIGNALBAR_EXPECT_GATEKEEPER:-0}" == "1" ]]; then
    echo "ERROR: spctl assessment failed. See $VERIFY_DIR/spctl.txt" >&2
    exit 1
  fi
  echo "WARN: spctl assessment did not pass. See $VERIFY_DIR/spctl.txt"
fi

if [[ "${SIGNALBAR_EXPECT_NOTARIZED:-0}" == "1" ]]; then
  xcrun stapler validate "$APP_BUNDLE" > "$VERIFY_DIR/stapler.txt" 2>&1
fi

ditto -x -k "$ZIP_PATH" "$EXTRACT_DIR"
codesign --verify --deep --strict --verbose=2 "$EXTRACTED_APP"

if [[ "${SIGNALBAR_EXPECT_NOTARIZED:-0}" == "1" ]]; then
  xcrun stapler validate "$EXTRACTED_APP" >> "$VERIFY_DIR/stapler.txt" 2>&1
fi

cleanup() {
  pkill -f "${APP_NAME}.app/Contents/MacOS/${APP_NAME}" 2>/dev/null || true
  pkill -x "$APP_NAME" 2>/dev/null || true
}
trap cleanup EXIT INT TERM
cleanup

"$EXTRACTED_APP/Contents/MacOS/${APP_NAME}" > "$VERIFY_DIR/smoke-launch.log" 2>&1 &
PID=$!
sleep 5
if ! kill -0 "$PID" 2>/dev/null; then
  echo "ERROR: extracted app failed to stay running during smoke launch. See $VERIFY_DIR/smoke-launch.log" >&2
  exit 1
fi
kill "$PID" 2>/dev/null || true
wait "$PID" 2>/dev/null || true

if [[ -f "$SUMMARY_PATH" ]]; then
  cp "$SUMMARY_PATH" "$VERIFY_DIR/signing-summary.txt"
fi

echo "Verified app bundle: $APP_BUNDLE"
echo "Verified zip artifact: $ZIP_PATH"
echo "Verification artifacts: $VERIFY_DIR"
