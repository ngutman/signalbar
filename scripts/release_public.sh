#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/release_common.sh"
load_local_release_env "$ROOT_DIR"

if [[ -z "${SIGNALBAR_NOTARY_PROFILE:-}" ]]; then
  echo "ERROR: set SIGNALBAR_NOTARY_PROFILE to a valid notarytool keychain profile." >&2
  exit 1
fi

"$ROOT_DIR/scripts/check_release_prereqs.sh" "$SIGNALBAR_NOTARY_PROFILE"
"$ROOT_DIR/scripts/package_app.sh"
SIGNALBAR_NOTARIZE=1 "$ROOT_DIR/scripts/sign_release.sh"
SIGNALBAR_EXPECT_GATEKEEPER=1 SIGNALBAR_EXPECT_NOTARIZED=1 "$ROOT_DIR/scripts/verify_release.sh"

echo "Public release artifact built, notarized, stapled, and verified successfully."
