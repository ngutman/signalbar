#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/version.env"

DIST_DIR="$ROOT_DIR/dist"
APP_NAME="SignalBar"
APP_BUNDLE="$DIST_DIR/${APP_NAME}.app"
APP_EXECUTABLE="$APP_BUNDLE/Contents/MacOS/${APP_NAME}"
ZIP_PATH="$DIST_DIR/${APP_NAME}-${MARKETING_VERSION}.zip"
SUMMARY_PATH="$DIST_DIR/signing-summary.txt"

if [[ ! -d "$APP_BUNDLE" ]]; then
  "$ROOT_DIR/scripts/package_app.sh"
fi

find_identity() {
  local pattern="$1"
  security find-identity -p codesigning -v 2>/dev/null | awk -F '"' -v pattern="$pattern" '$2 ~ pattern { print $2; exit }'
}

SIGNING_MODE="identity"
IDENTITY="${APP_IDENTITY:-}"

if [[ -z "$IDENTITY" ]]; then
  IDENTITY="$(find_identity '^Developer ID Application:')"
fi
if [[ -z "$IDENTITY" ]]; then
  IDENTITY="$(find_identity '^Apple Distribution:')"
fi
if [[ -z "$IDENTITY" ]]; then
  IDENTITY="$(find_identity '^Apple Development:')"
fi
if [[ -z "$IDENTITY" ]]; then
  SIGNING_MODE="adhoc"
  IDENTITY="-"
fi

sign_path() {
  local path="$1"
  if [[ "$SIGNING_MODE" == "adhoc" ]]; then
    codesign --force --sign - "$path"
  else
    codesign --force --timestamp --options runtime --sign "$IDENTITY" "$path"
  fi
}

sign_path "$APP_EXECUTABLE"
sign_path "$APP_BUNDLE"

rm -f "$ZIP_PATH" "$ZIP_PATH.sha256"
ditto -c -k --keepParent --sequesterRsrc "$APP_BUNDLE" "$ZIP_PATH"
shasum -a 256 "$ZIP_PATH" > "$ZIP_PATH.sha256"

{
  echo "signing_mode=$SIGNING_MODE"
  echo "identity=$IDENTITY"
  echo "app_bundle=$APP_BUNDLE"
  echo "zip=$ZIP_PATH"
} > "$SUMMARY_PATH"

if [[ "${SIGNALBAR_NOTARIZE:-0}" == "1" ]]; then
  if [[ "$IDENTITY" != Developer\ ID\ Application:* ]]; then
    echo "ERROR: notarization requires a Developer ID Application identity." >&2
    exit 1
  fi
  if [[ -z "${SIGNALBAR_NOTARY_PROFILE:-}" ]]; then
    echo "ERROR: set SIGNALBAR_NOTARY_PROFILE to a notarytool keychain profile name." >&2
    exit 1
  fi
  xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$SIGNALBAR_NOTARY_PROFILE" --wait
  xcrun stapler staple "$APP_BUNDLE"
fi

echo "Signed app bundle: $APP_BUNDLE"
echo "Signed zip artifact: $ZIP_PATH"
echo "Signing summary: $SUMMARY_PATH"
