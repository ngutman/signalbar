#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

"$ROOT_DIR/scripts/package_app.sh"
"$ROOT_DIR/scripts/sign_release.sh"
"$ROOT_DIR/scripts/verify_release.sh"

echo "Local signed release completed successfully. See dist/ for artifacts."
