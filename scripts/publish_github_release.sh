#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/release_common.sh"
load_local_release_env "$ROOT_DIR"
source "$ROOT_DIR/version.env"

require_command gh
require_command ditto

REPO="$(resolve_github_repo)"
TAG="${1:-v${MARKETING_VERSION}}"
TITLE="${SIGNALBAR_RELEASE_TITLE:-SignalBar ${MARKETING_VERSION}}"
DIST_DIR="$ROOT_DIR/dist"
ZIP_PATH="$DIST_DIR/SignalBar-${MARKETING_VERSION}.zip"
SHA_PATH="$ZIP_PATH.sha256"
SIGNING_SUMMARY_PATH="$DIST_DIR/signing-summary.txt"
VERIFY_DIR="$DIST_DIR/verify"
VERIFY_ARCHIVE_PATH="$DIST_DIR/SignalBar-${MARKETING_VERSION}-verify.zip"

if [[ ! -f "$ZIP_PATH" || ! -f "$SHA_PATH" ]]; then
  echo "ERROR: release artifacts are missing. Run scripts/release_public.sh first." >&2
  exit 1
fi

if ! gh auth status -h github.com >/dev/null 2>&1; then
  echo "ERROR: gh is not authenticated for github.com." >&2
  exit 1
fi

rm -f "$VERIFY_ARCHIVE_PATH"
if [[ -d "$VERIFY_DIR" ]]; then
  ditto -c -k --keepParent "$VERIFY_DIR" "$VERIFY_ARCHIVE_PATH"
fi

assets=(
  "$ZIP_PATH"
  "$SHA_PATH"
)

if [[ -f "$SIGNING_SUMMARY_PATH" ]]; then
  assets+=("$SIGNING_SUMMARY_PATH")
fi

if [[ -f "$VERIFY_ARCHIVE_PATH" ]]; then
  assets+=("$VERIFY_ARCHIVE_PATH")
fi

if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
  gh release upload "$TAG" "${assets[@]}" --repo "$REPO" --clobber
else
  create_args=(
    "$TAG"
    --repo "$REPO"
    --title "$TITLE"
    --verify-tag
  )

  if [[ -n "${SIGNALBAR_RELEASE_NOTES_FILE:-}" ]]; then
    create_args+=(--notes-file "$SIGNALBAR_RELEASE_NOTES_FILE")
  else
    create_args+=(--generate-notes)
  fi

  if [[ "${SIGNALBAR_RELEASE_DRAFT:-0}" == "1" ]]; then
    create_args+=(--draft)
  fi

  if [[ "${SIGNALBAR_RELEASE_PRERELEASE:-0}" == "1" ]]; then
    create_args+=(--prerelease)
  fi

  gh release create "${create_args[@]}" "${assets[@]}"
fi

RELEASE_URL="$(gh release view "$TAG" --repo "$REPO" --json url --jq '.url')"
echo "Published GitHub release: $RELEASE_URL"
