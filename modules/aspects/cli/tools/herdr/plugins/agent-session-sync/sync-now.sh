#!/bin/sh
# Pull every mirrored host immediately, rather than waiting for the timer.
# Useful right before closing the laptop.
set -u
BIN="${HERDR_BIN_PATH:-herdr}"
SYNC="${AGENT_SESSION_SYNC_BIN:-agent-session-sync}"
command -v "$SYNC" >/dev/null 2>&1 || exit 0

hosts=$("$SYNC" status 2>/dev/null | awk '!/^no mirror/ {print $1}')
[ -z "$hosts" ] && exit 0

ok=0; failed=""
for h in $hosts; do
  if "$SYNC" pull "$h" >/dev/null 2>&1; then ok=$((ok+1)); else failed="$failed $h"; fi
done

if [ -n "$failed" ]; then
  "$BIN" notification show "Sync failed" --body "could not reach:$failed" --sound request >/dev/null 2>&1
else
  "$BIN" notification show "Transcripts synced" --body "$ok host(s) up to date" --sound done >/dev/null 2>&1
fi
