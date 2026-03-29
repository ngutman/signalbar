#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/release_common.sh"
load_local_release_env "$ROOT_DIR"
source "$ROOT_DIR/version.env"

require_command git
require_command gh
require_command swift

require_clean_git_tree

if ! gh auth status -h github.com >/dev/null 2>&1; then
  echo "ERROR: gh is not authenticated for github.com." >&2
  exit 1
fi

CURRENT_BRANCH="$(git branch --show-current)"
if [[ "$CURRENT_BRANCH" != "main" ]]; then
  echo "ERROR: release_github_local.sh must be run from the main branch." >&2
  exit 1
fi

git fetch origin main --tags

if [[ "${SIGNALBAR_SKIP_PRECHECKS:-0}" != "1" ]]; then
  "$ROOT_DIR/scripts/lint.sh"
  swift test
fi

"$ROOT_DIR/scripts/release_public.sh"

TAG="v${MARKETING_VERSION}"
TAG_MESSAGE="release ${TAG}"
TAG_COMMIT="$(git rev-parse HEAD)"

if git rev-parse "refs/tags/${TAG}" >/dev/null 2>&1; then
  EXISTING_TAG_COMMIT="$(git rev-parse "${TAG}^{}")"
  if [[ "$EXISTING_TAG_COMMIT" != "$TAG_COMMIT" ]]; then
    echo "ERROR: local tag ${TAG} already exists on a different commit." >&2
    exit 1
  fi
else
  git tag -a "$TAG" -m "$TAG_MESSAGE"
fi

REMOTE_TAG_COMMIT="$(git ls-remote --tags origin "refs/tags/${TAG}^{}" | awk 'NR == 1 { print $1 }')"
if [[ -n "$REMOTE_TAG_COMMIT" && "$REMOTE_TAG_COMMIT" != "$TAG_COMMIT" ]]; then
  echo "ERROR: remote tag ${TAG} already exists on a different commit." >&2
  exit 1
fi

LOCAL_HEAD="$(git rev-parse HEAD)"
REMOTE_HEAD="$(git rev-parse origin/main 2>/dev/null || true)"
if [[ -n "$REMOTE_HEAD" && "$LOCAL_HEAD" != "$REMOTE_HEAD" ]]; then
  git push origin main
fi

if [[ -z "$REMOTE_TAG_COMMIT" ]]; then
  git push origin "$TAG"
fi

"$ROOT_DIR/scripts/publish_github_release.sh" "$TAG"

echo "Local notarized GitHub release completed successfully for ${TAG}."
