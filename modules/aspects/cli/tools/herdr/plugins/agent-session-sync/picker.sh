#!/bin/sh
# Interactive browser for mirrored transcripts, run inside a herdr popup pane.
# Lists every mirrored host's sessions and promotes the one you pick.
set -u

SYNC="${AGENT_SESSION_SYNC_BIN:-agent-session-sync}"
FZF=$(command -v fzf 2>/dev/null || true)

pause() { printf '\nPress enter to close. '; read -r _; }

if ! command -v "$SYNC" >/dev/null 2>&1; then
  printf 'agent-session-sync is not on PATH.\n'; pause; exit 1
fi

hosts=$("$SYNC" status 2>/dev/null | awk '!/^no mirror/ {print $1}')
if [ -z "$hosts" ]; then
  printf 'Nothing mirrored yet.\n\nRun:  %s pull <host>\n' "$SYNC"; pause; exit 0
fi

# "<host>  <rest of the list line>" so the host survives into the selection.
rows=$(for h in $hosts; do
  "$SYNC" list "$h" 2>/dev/null | sed "s|^|$h |"
done)

if [ -z "$rows" ]; then
  printf 'No transcripts mirrored.\n'; pause; exit 0
fi

if [ -n "$FZF" ]; then
  sel=$(printf '%s\n' "$rows" | "$FZF" \
    --prompt='promote> ' \
    --header='enter: promote into the live store   esc: cancel' \
    --no-sort --reverse --height=100%) || exit 0
else
  printf '%s\n' "$rows" | nl -w3 -s'  '
  printf '\nNumber to promote (enter to cancel): '
  read -r n
  [ -z "$n" ] && exit 0
  sel=$(printf '%s\n' "$rows" | sed -n "${n}p")
fi

[ -z "${sel:-}" ] && exit 0

host=$(printf '%s' "$sel" | awk '{print $1}')
# Columns are: <host> <kind-marker?> <agent> <uuid> ... — the marker is only
# present for subagent rows, so locate the uuid by the agent name before it.
id=$(printf '%s' "$sel" | awk '{for (i=2;i<=NF;i++) if ($i=="claude"||$i=="pi") {print $(i+1); exit}}')

if [ -z "$id" ]; then
  printf 'Could not parse a session id from:\n  %s\n' "$sel"; pause; exit 1
fi

printf 'Promoting %s from %s...\n\n' "$id" "$host"
"$SYNC" promote "$host" "$id"
pause
