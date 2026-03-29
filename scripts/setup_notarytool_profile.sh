#!/usr/bin/env bash
set -euo pipefail

PROFILE_NAME="${1:-${SIGNALBAR_NOTARY_PROFILE:-signalbar-notary}}"
API_KEY_FILE="${2:-${APP_STORE_CONNECT_API_KEY_FILE:-}}"
KEY_ID="${3:-${APP_STORE_CONNECT_KEY_ID:-}}"
ISSUER_ID="${4:-${APP_STORE_CONNECT_ISSUER_ID:-}}"

if [[ -z "$API_KEY_FILE" || -z "$KEY_ID" || -z "$ISSUER_ID" ]]; then
  echo "Usage: $(basename "$0") <profile-name> <api-key-file.p8> <key-id> <issuer-id>" >&2
  echo "You can also provide APP_STORE_CONNECT_API_KEY_FILE, APP_STORE_CONNECT_KEY_ID, and APP_STORE_CONNECT_ISSUER_ID via environment variables." >&2
  exit 1
fi

if [[ ! -f "$API_KEY_FILE" ]]; then
  echo "ERROR: API key file not found at '$API_KEY_FILE'." >&2
  exit 1
fi

xcrun notarytool store-credentials "$PROFILE_NAME" \
  --key "$API_KEY_FILE" \
  --key-id "$KEY_ID" \
  --issuer "$ISSUER_ID"

echo "Stored notarytool credentials in keychain profile: $PROFILE_NAME"
