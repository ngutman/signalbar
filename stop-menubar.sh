#!/usr/bin/env bash
set -euo pipefail

PATTERNS=(
  "SignalBar.app/Contents/MacOS/SignalBar"
  "/SignalBar"
)

for pattern in "${PATTERNS[@]}"; do
  pkill -f "$pattern" 2>/dev/null || true
  sleep 0.2
  pkill -9 -f "$pattern" 2>/dev/null || true
  sleep 0.2
done

pkill -x "SignalBar" 2>/dev/null || true
sleep 0.2
pkill -9 -x "SignalBar" 2>/dev/null || true
