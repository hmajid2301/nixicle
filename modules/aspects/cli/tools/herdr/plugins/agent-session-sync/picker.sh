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
# awk with the host passed as a variable, not sed with it spliced into the
# script — a host containing the delimiter would otherwise break the expression.
rows=$(for h in $hosts; do
  "$SYNC" list "$h" 2>/dev/null | awk -v h="$h" '{print h " " $0}'
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
  total=$(printf '%s\n' "$rows" | wc -l)
  printf '\nNumber to promote (enter to cancel): '
  read -r n
  [ -z "$n" ] && exit 0
  # Validate before it reaches sed: "1p;1" would silently select a different
  # row, and "0" or "-1" are sed errors rather than useful messages.
  case "$n" in
    ''|*[!0-9]*) printf 'Not a number: %s\n' "$n"; pause; exit 1 ;;
  esac
  if [ "$n" -lt 1 ] || [ "$n" -gt "$total" ]; then
    printf 'Out of range (1-%s): %s\n' "$total" "$n"; pause; exit 1
  fi
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
