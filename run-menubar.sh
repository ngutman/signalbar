#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

LOG_FILE="${ROOT_DIR}/dist/run-menubar.log"
mkdir -p "${ROOT_DIR}/dist"

"${ROOT_DIR}/stop-menubar.sh" >/dev/null 2>&1 || true

swift build -c debug
BIN_DIR="$(swift build -c debug --show-bin-path)"
BIN="${BIN_DIR}/SignalBar"

if [[ ! -x "$BIN" ]]; then
  echo "ERROR: could not find built SignalBar binary at $BIN" >&2
  exit 1
fi

nohup "$BIN" >"$LOG_FILE" 2>&1 &
PID=$!

sleep 3
if ! kill -0 "$PID" 2>/dev/null; then
  echo "ERROR: SignalBar exited early. Check $LOG_FILE" >&2
  exit 1
fi

echo "SignalBar started (pid $PID)"
echo "Log: $LOG_FILE"
