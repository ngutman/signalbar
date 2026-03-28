#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

OUTPUT_DIR="$ROOT_DIR/docs/screenshots"
mkdir -p "$OUTPUT_DIR"

SIGNALBAR_WRITE_RENDER=1 swift test --filter MenuCardViewRenderTests

cp /tmp/signalbar-menu-card-preview.png "$OUTPUT_DIR/menu-healthy.png"
cp /tmp/signalbar-menu-card-overview.png "$OUTPUT_DIR/menu-overview.png"
cp /tmp/signalbar-menu-card-reliability.png "$OUTPUT_DIR/menu-reliability.png"
cp /tmp/signalbar-menu-card-empty-live.png "$OUTPUT_DIR/menu-empty-live.png"

echo "Wrote screenshots to $OUTPUT_DIR"
