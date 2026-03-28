#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

MODE="${1:-lint}"

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: required tool '$1' is not installed." >&2
    exit 1
  fi
}

require_tool swiftformat
require_tool swiftlint

case "$MODE" in
  lint)
    swiftformat --lint Package.swift Sources Tests
    swiftlint lint
    ;;
  format)
    swiftformat Package.swift Sources Tests
    swiftlint lint
    ;;
  *)
    echo "Usage: $(basename "$0") [lint|format]" >&2
    exit 1
    ;;
esac
