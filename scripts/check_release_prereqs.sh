#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/release_common.sh"
load_local_release_env "$ROOT_DIR"

NOTARY_PROFILE="${1:-${SIGNALBAR_NOTARY_PROFILE:-}}"
REQUIRE_NOTARY_PROFILE="${SIGNALBAR_REQUIRE_NOTARY_PROFILE:-0}"

DEVELOPER_ID_IDENTITY="$(security find-identity -p codesigning -v 2>/dev/null | awk -F '"' '/Developer ID Application:/ { print $2; exit }')"

if [[ -z "$DEVELOPER_ID_IDENTITY" ]]; then
  echo "ERROR: no Developer ID Application signing identity was found in the keychain." >&2
  exit 1
fi

echo "Developer ID identity: $DEVELOPER_ID_IDENTITY"

if [[ "$REQUIRE_NOTARY_PROFILE" == "1" || -n "$NOTARY_PROFILE" ]]; then
  if [[ -z "$NOTARY_PROFILE" ]]; then
    echo "ERROR: no notarytool keychain profile name was provided." >&2
    exit 1
  fi

  if ! xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null 2>&1; then
    echo "ERROR: notarytool keychain profile '$NOTARY_PROFILE' is missing or invalid." >&2
    exit 1
  fi

  echo "Notary profile available: $NOTARY_PROFILE"
fi
