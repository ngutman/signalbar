#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/version.env"

CONFIGURATION="${1:-release}"
DIST_DIR="$ROOT_DIR/dist"
APP_NAME="SignalBar"
APP_BUNDLE="$DIST_DIR/${APP_NAME}.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
EXECUTABLE_PATH="$APP_CONTENTS/MacOS/${APP_NAME}"

ARCH_LIST=( ${ARCHES:-} )
if [[ ${#ARCH_LIST[@]} -eq 0 ]]; then
  HOST_ARCH="$(uname -m)"
  ARCH_LIST=("$HOST_ARCH")
fi

mkdir -p "$DIST_DIR"
rm -rf "$APP_BUNDLE"

for arch in "${ARCH_LIST[@]}"; do
  swift build -c "$CONFIGURATION" --arch "$arch"
done

resolve_binary() {
  local configuration="$1"
  local arch="$2"
  local candidate="$ROOT_DIR/.build/${arch}-apple-macosx/${configuration}/${APP_NAME}"
  if [[ -x "$candidate" ]]; then
    echo "$candidate"
    return 0
  fi

  candidate="$ROOT_DIR/.build/${configuration}/${APP_NAME}"
  if [[ -x "$candidate" ]]; then
    echo "$candidate"
    return 0
  fi

  return 1
}

mkdir -p "$APP_CONTENTS/MacOS" "$APP_CONTENTS/Resources"

if [[ ${#ARCH_LIST[@]} -eq 1 ]]; then
  cp "$(resolve_binary "$CONFIGURATION" "${ARCH_LIST[0]}")" "$EXECUTABLE_PATH"
else
  LIPO_INPUTS=()
  for arch in "${ARCH_LIST[@]}"; do
    LIPO_INPUTS+=("$(resolve_binary "$CONFIGURATION" "$arch")")
  done
  lipo -create "${LIPO_INPUTS[@]}" -output "$EXECUTABLE_PATH"
fi
chmod +x "$EXECUTABLE_PATH"

BUILD_TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
GIT_COMMIT="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"

cat > "$APP_CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key><string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key><string>${BUNDLE_ID}</string>
    <key>CFBundleExecutable</key><string>${APP_NAME}</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>${MARKETING_VERSION}</string>
    <key>CFBundleVersion</key><string>${BUILD_NUMBER}</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
    <key>SignalBarBuildTimestamp</key><string>${BUILD_TIMESTAMP}</string>
    <key>SignalBarGitCommit</key><string>${GIT_COMMIT}</string>
</dict>
</plist>
PLIST

echo "Packaged app bundle: $APP_BUNDLE"
