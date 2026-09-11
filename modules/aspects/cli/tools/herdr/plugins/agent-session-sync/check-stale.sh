#!/bin/sh
# Notify when a mirror has gone stale.
#
# A sync that works is unremarkable and notifying on it would train you to
# ignore the notifications. A mirror that has silently stopped updating is the
# case you would otherwise never notice — until the remote box dies and the
# transcripts you thought were backed up are hours old.
set -u

BIN="${HERDR_BIN_PATH:-herdr}"
SYNC="${AGENT_SESSION_SYNC_BIN:-agent-session-sync}"

status=$("$SYNC" status 2>/dev/null) || exit 0
case "$status" in
  ""|"no mirror yet"*) exit 0 ;;
esac

stale=$(printf '%s\n' "$status" | grep '\[STALE\]' | awk '{print $1}')
never=$(printf '%s\n' "$status" | grep 'never synced' | awk '{print $1}')

[ -z "$stale" ] && [ -z "$never" ] && exit 0

# Age is the token before "ago"; a trailing [STALE] makes a fixed field index wrong.
body=""
for h in $stale; do
  age=$(printf '%s\n' "$status" | awk -v h="$h" \
    '$1==h {for (i=1;i<=NF;i++) if ($i=="ago") {print $(i-1); exit}}')
  body="${body}${h} last synced ${age:-?} ago. "
done
for h in $never; do
  body="${body}${h} has never synced. "
done

"$BIN" notification show "Agent transcripts not backing up" \
  --body "$body" --sound request >/dev/null 2>&1 || true
