#!/usr/bin/env bash
# Pull agent session transcripts from a remote machine into a local read-only
# quarantine mirror, so a remote box dying does not take conversations with it.
#
#   agent-session-sync pull <host>          one sync pass
#   agent-session-sync status               what is mirrored, and how stale
#   agent-session-sync list <host>          mirrored sessions for a host
#   agent-session-sync promote <host> <id>  move one session into the live store
#   agent-session-sync daemon <host>        loop pull on an interval
#
# The mirror is never read by the agents. Promote is the only step that writes
# into the live store, and it refuses to clobber a newer local file.

set -uo pipefail

MIRROR="${AGENT_SYNC_MIRROR:-$HOME/.local/state/agent-session-sync}"
INTERVAL="${AGENT_SYNC_INTERVAL:-900}"
STALE_AFTER="${AGENT_SYNC_STALE_AFTER:-3600}"
LOG="$MIRROR/sync.log"

# agent | local session root | remote session root
AGENTS=(
  "claude:.claude/projects:.claude/projects"
  "pi:.pi/agent/sessions:.pi/agent/sessions"
)

# Credentials and caches live alongside transcripts. Never pull them.
# ORDER MATTERS: rsync filters are first-match-wins, so these must precede the
# --include '*/' that follows, or every directory rule below is unreachable.
EXCLUDES=(
  --exclude 'tmp/' --exclude 'npm/' --exclude 'node_modules/'
  --exclude 'paste-cache/' --exclude 'shell-snapshots/' --exclude 'file-history/'
  --exclude '.credentials.json' --exclude 'auth.json'
  --exclude '*.db' --exclude '*.db-*' --exclude '*.log'
)

die() { printf 'error: %s\n' "$*" >&2; exit 1; }
is_num() { [[ ${1:-} =~ ^[0-9]+$ ]]; }

command -v rsync >/dev/null || die "rsync not found"
command -v jq    >/dev/null || die "jq not found"
is_num "$INTERVAL"    || die "AGENT_SYNC_INTERVAL must be a number, got: $INTERVAL"
is_num "$STALE_AFTER" || die "AGENT_SYNC_STALE_AFTER must be a number, got: $STALE_AFTER"
log() { mkdir -p "$MIRROR"; printf '%s %s\n' "$(date -Is)" "$*" >>"$LOG"; }

now() { date +%s; }
mtime() { stat -c %Y "$1" 2>/dev/null || echo 0; }
size() { stat -c %s "$1" 2>/dev/null || echo 0; }

# Compare two append-only transcripts by content:
#   same | local-ahead | mirror-ahead | diverged
# One file strictly extending the other means it is the later version. Neither
# extending the other means they forked and a human needs to know.
jsonl_relation() {
  local a=$1 b=$2 sa sb
  sa=$(size "$a"); sb=$(size "$b")
  if (( sa == sb )); then
    cmp -s "$a" "$b" && printf 'same' || printf 'diverged'
  elif (( sa > sb )); then
    # b is a prefix of a  ->  local has extra lines
    cmp -s -n "$sb" "$a" "$b" && printf 'local-ahead' || printf 'diverged'
  else
    cmp -s -n "$sa" "$a" "$b" && printf 'mirror-ahead' || printf 'diverged'
  fi
}

human_age() {
  local s=$1
  if   (( s < 90 ));    then printf '%ds' "$s"
  elif (( s < 5400 ));  then printf '%dm' "$((s / 60))"
  elif (( s < 172800 )); then printf '%dh' "$((s / 3600))"
  else printf '%dd' "$((s / 86400))"
  fi
}

# Slugs are not reversible: a directory named "nala-workspace" and the separator
# between path segments are both "-", so parsing a slug back into a path guesses
# wrong. Everything below therefore works on slugs directly, swapping a known
# prefix rather than interpreting the interior.
#   claude: /home/u/p/repo  -> -home-u-p-repo
#   pi:     /home/u/p/repo  -> --home-u-p-repo--
slugify() {
  local agent=$1 path=$2
  case "$agent" in
    claude) printf '%s' "${path////-}" ;;
    pi)     printf -- '-%s--' "${path////-}" ;;
  esac
}

# Explicit remote->local project path mappings, for repos that do not sit at the
# same subpath on both machines. One "<remote> <local>" pair per line; longest
# remote path wins, so a specific repo can override a broader parent mapping.
# Swapping the home prefix only covers /Users/you -> /home/you; this covers
# /home/you/work/repo -> /home/you/projects/repo.
MAPFILE="${AGENT_SYNC_MAP:-${XDG_CONFIG_HOME:-$HOME/.config}/agent-session-sync/paths}"

# Remote absolute path -> local absolute path.
remap_path() {
  local path=$1 remote_home=$2
  local best_r='' best_l='' r l

  if [[ -f "$MAPFILE" ]]; then
    while read -r r l; do
      [[ -z "$r" || "$r" == \#* || -z "$l" ]] && continue
      r="${r%/}"; l="${l%/}"
      # Expand a leading ~ on each side against the machine it refers to.
      [[ "$r" == '~'* ]] && r="$remote_home${r#\~}"
      [[ "$l" == '~'* ]] && l="$HOME${l#\~}"
      if [[ "$path" == "$r" || "$path" == "$r"/* ]] && (( ${#r} > ${#best_r} )); then
        best_r=$r; best_l=$l
      fi
    done <"$MAPFILE"
  fi

  if [[ -n "$best_r" ]]; then
    printf '%s%s' "$best_l" "${path#"$best_r"}"
  elif [[ "$path" == "$remote_home" || "$path" == "$remote_home"/* ]]; then
    printf '%s%s' "$HOME" "${path#"$remote_home"}"
  else
    printf '%s' "$path"   # unmapped; caller warns
  fi
}

# Remote slug -> local slug. Prefers the transcript's recorded cwd, since that
# is an unambiguous absolute path and can go through the full mapping table.
# Falls back to a slug-level home-prefix swap when no cwd is available, because
# slugs cannot be reversed into paths (a "-" is both separator and literal).
remap_slug() {
  local agent=$1 slug=$2 remote_home=$3 cwd=${4:-}

  if [[ -n "$cwd" ]]; then
    local lpath
    lpath=$(remap_path "$cwd" "$remote_home")
    if [[ "$lpath" != "$cwd" || "$cwd" == "$HOME"* ]]; then
      slugify "$agent" "$lpath"
      return
    fi
  fi

  local rpfx lpfx
  rpfx=$(slugify "$agent" "$remote_home")
  lpfx=$(slugify "$agent" "$HOME")
  case "$agent" in
    pi) rpfx="${rpfx%--}"; lpfx="${lpfx%--}" ;;
  esac
  # The match must end on a segment boundary. A bare prefix test lets remote
  # home /home/u swallow the start of /home/username, producing a slug that
  # maps to no real path at all.
  if [[ "$slug" == "$rpfx" || "$slug" == "$rpfx-"* ]]; then
    printf '%s%s' "$lpfx" "${slug#"$rpfx"}"
  else
    printf '%s' "$slug"
  fi
}

# Best-effort display only — never used to compute a destination. The cwd is
# recorded verbatim inside the transcript, so read it from there instead of
# guessing from the slug.
cwd_of() {
  local f=$1 c
  # fromjson? skips unparseable lines, so one torn line does not abort the scan.
  c=$(head -40 "$f" 2>/dev/null | jq -r -R 'fromjson? | select(.cwd) | .cwd' 2>/dev/null | head -1)
  [[ -n "$c" ]] && printf '%s' "$c"
}

remote_home() {
  local host=$1 home
  # Only the last line, in case a login shell prints banners before our output.
  home=$(ssh -o BatchMode=yes -o ConnectTimeout=10 "$host" 'printf "%s\n" "$HOME"' 2>/dev/null | tail -1) \
    || return 1
  [[ -n "$home" && "$home" == /* ]] || return 1
  printf '%s' "$home"
}

cmd_pull() {
  local host=${1:-} rc=0 probed=0 synced=0
  [[ -n "$host" ]] || die "usage: agent-session-sync pull <host>"
  [[ "$host" != */* && "$host" != .* ]] || die "invalid host: $host"

  local rhome
  if ! rhome=$(remote_home "$host"); then
    log "pull $host: unreachable"
    printf 'unreachable: %s (mirror left untouched)\n' "$host" >&2
    return 1
  fi

  for entry in "${AGENTS[@]}"; do
    IFS=: read -r agent lroot rroot <<<"$entry"
    local src="$rhome/$rroot/" dest="$MIRROR/$host/$agent/" prc=0

    # Probe first: a missing root is normal (agent not used on that box) and
    # should not look like a failure. ssh's own 255 means the connection failed
    # rather than the directory being absent — those must not look alike.
    ssh -o BatchMode=yes -o ConnectTimeout=10 "$host" \
        'test -d "$1"' _ "$rhome/$rroot" 2>/dev/null || prc=$?
    if (( prc == 255 )); then
      rc=1
      printf 'probe failed %-7s %s (ssh error)\n' "$agent" "$host" >&2
      log "pull $host/$agent: ssh probe failed"
      continue
    fi
    probed=1
    (( prc == 0 )) || continue

    mkdir -p "$dest"
    # --partial-dir, not --partial: an interrupted transfer must never leave a
    # truncated file at the real path, because rsync cuts mid-line and promote
    # would then copy a torn transcript into the live store.
    if rsync -az --partial-dir=.rsync-partial --prune-empty-dirs \
         "${EXCLUDES[@]}" \
         --include '*/' --include '*.jsonl' --exclude '*' \
         -e 'ssh -o BatchMode=yes -o ConnectTimeout=10' \
         "$src" "$dest" >/dev/null 2>&1; then
      synced=1
      printf '%s' "$rhome" >"$MIRROR/$host/.remote-home"
      date +%s >"$MIRROR/$host/.last-sync"
      local n
      n=$(find "$dest" -name '*.jsonl' -type f 2>/dev/null | wc -l)
      printf 'synced %-7s %s  (%s transcripts)\n' "$agent" "$host" "$n"
      log "pull $host/$agent: ok, $n transcripts"
    else
      rc=1
      printf 'failed %-7s %s\n' "$agent" "$host" >&2
      log "pull $host/$agent: rsync failed"
    fi
  done

  # A pass that transferred nothing is not a success: a wedged host whose sshd
  # answers but whose filesystem is hung would otherwise report healthy forever
  # and keep resetting the daemon's backoff.
  if (( ! probed )); then
    printf 'no agent directories reachable on %s\n' "$host" >&2
    log "pull $host: no agent roots reachable"
    return 1
  fi
  if (( ! synced && ! rc )); then
    printf 'nothing to sync on %s (no agent session directories present)\n' "$host" >&2
    log "pull $host: no agent roots present"
    return 1
  fi
  return $rc
}

cmd_status() {
  [[ -d "$MIRROR" ]] || { echo "no mirror yet — run: agent-session-sync pull <host>"; return 0; }
  local found=0
  for hostdir in "$MIRROR"/*/; do
    [[ -d "$hostdir" ]] || continue
    found=1
    local host last age n
    host=$(basename "$hostdir")
    last=$(cat "$hostdir/.last-sync" 2>/dev/null || echo 0)
    is_num "$last" || last=0
    n=$(find "$hostdir" -name '*.jsonl' -type f 2>/dev/null | wc -l)
    if (( last == 0 )); then
      printf '%-14s never synced\n' "$host"
      continue
    fi
    age=$(( $(now) - last ))
    printf '%-14s %4s transcripts   last sync %s ago' "$host" "$n" "$(human_age "$age")"
    (( age > STALE_AFTER )) && printf '   [STALE]'
    printf '\n'
  done
  (( found )) || echo "no mirror yet — run: agent-session-sync pull <host>"
}

cmd_list() {
  local host=${1:-}
  [[ -n "$host" ]] || die "usage: agent-session-sync list <host>"
  local base="$MIRROR/$host"
  [[ -d "$base" ]] || die "nothing mirrored for $host"
  local rhome
  rhome=$(cat "$base/.remote-home" 2>/dev/null || echo "$HOME")

  for entry in "${AGENTS[@]}"; do
    IFS=: read -r agent _ _ <<<"$entry"
    [[ -d "$base/$agent" ]] || continue
    for slugdir in "$base/$agent"/*/; do
      [[ -d "$slugdir" ]] || continue
      local slug
      slug=$(basename "$slugdir")
      while IFS= read -r f; do
        [[ -n "$f" ]] || continue
        local id age cwd lcwd
        id=$(basename "$f" .jsonl)
        age=$(( $(now) - $(mtime "$f") ))
        cwd=$(cwd_of "$f")
        if [[ -n "$cwd" ]]; then
          lcwd=$(remap_path "$cwd" "$rhome")
        else
          lcwd="(cwd unknown) $slug"
        fi
        printf '%-7s %-46s %8s  %s' "$agent" "$id" "$(human_age "$age")" "$lcwd"
        [[ -n "$cwd" && ! -d "$lcwd" ]] && printf '  [no local dir]'
        printf '\n'
      done < <(find "$slugdir" -maxdepth 1 -name '*.jsonl' -type f 2>/dev/null | sort)
    done
  done
}

cmd_promote() {
  local host=${1:-} id=${2:-}
  [[ -n "$host" && -n "$id" ]] || die "usage: agent-session-sync promote <host> <session-id>"
  local base="$MIRROR/$host"
  [[ -d "$base" ]] || die "nothing mirrored for $host"
  local rhome
  rhome=$(cat "$base/.remote-home" 2>/dev/null || echo "$HOME")

  # Match on the uuid, so a pi filename's timestamp prefix does not have to be typed.
  local matches=()
  while IFS= read -r f; do matches+=("$f"); done < <(
    find "$base" -type f -name "*${id}*.jsonl" 2>/dev/null | sort
  )
  (( ${#matches[@]} )) || die "no mirrored session matching '$id' for $host"
  if (( ${#matches[@]} > 1 )); then
    printf 'ambiguous — %d matches:\n' "${#matches[@]}" >&2
    printf '  %s\n' "${matches[@]}" >&2
    die "use a longer session id"
  fi

  local src="${matches[0]}"
  local agent slug lroot
  agent=$(basename "$(dirname "$(dirname "$src")")")
  slug=$(basename "$(dirname "$src")")
  for entry in "${AGENTS[@]}"; do
    IFS=: read -r a l _ <<<"$entry"
    [[ "$a" == "$agent" ]] && lroot=$l
  done
  [[ -n "${lroot:-}" ]] || die "unknown agent layout: $agent"

  # The transcript records its own cwd, which is an unambiguous absolute path —
  # prefer it over the slug when working out where this lands locally.
  local rcwd lcwd lslug destdir dest
  rcwd=$(cwd_of "$src")
  lslug=$(remap_slug "$agent" "$slug" "$rhome" "$rcwd")
  destdir="$HOME/$lroot/$lslug"
  dest="$destdir/$(basename "$src")"

  if [[ -n "$rcwd" ]]; then
    lcwd=$(remap_path "$rcwd" "$rhome")
    if [[ "$lcwd" == "$rcwd" && "$rhome" != "$HOME" ]]; then
      printf 'warning: no mapping for %s; add one to %s\n' "$rcwd" "$MAPFILE" >&2
    fi
    if [[ ! -d "$lcwd" ]]; then
      printf 'warning: %s does not exist locally — resume will not find the project\n' "$lcwd" >&2
      printf '         add a mapping to %s if it lives elsewhere here\n' "$MAPFILE" >&2
    fi
  elif [[ "$lslug" == "$slug" && "$rhome" != "$HOME" ]]; then
    printf 'warning: slug not remapped (no cwd in transcript): %s\n' "$slug" >&2
  fi

  # "Newer" is decided by content, not mtime. rsync -a stamps the mirror with
  # the REMOTE clock, so comparing it against a locally-stamped file is only
  # valid if both machines agree on the time — and a skewed remote clock would
  # either clobber newer local work or silently refuse to rescue newer remote
  # work. Transcripts are append-only, so whichever file strictly extends the
  # other is the later one. That is exact, clock-free, and detects the fork
  # case that mtime comparison cannot see at all.
  if [[ -f "$dest" ]]; then
    local rel
    rel=$(jsonl_relation "$dest" "$src")
    case "$rel" in
      same)
        printf 'skipped: identical (already promoted)\n'
        printf 'local file: %s\n' "$dest"
        return 0 ;;
      local-ahead)
        printf 'skipped: local copy has continued beyond the mirror (%s vs %s lines)\n' \
          "$(wc -l <"$dest")" "$(wc -l <"$src")"
        printf 'nothing promoted. Local file: %s\n' "$dest"
        return 0 ;;
      mirror-ahead)
        cp -p "$dest" "$dest.bak.$(date +%s)"
        printf 'local copy was behind; backed it up to %s.bak.*\n' "$(basename "$dest")" ;;
      diverged)
        local bak="$dest.bak.$(date +%s)"
        cp -p "$dest" "$bak"
        printf 'WARNING: forked — both copies were appended to independently.\n' >&2
        printf '  local  %s lines\n  mirror %s lines\n' \
          "$(wc -l <"$dest")" "$(wc -l <"$src")" >&2
        printf '  local copy preserved at: %s\n' "$bak" >&2
        printf '  promoting the mirror copy over it.\n' >&2 ;;
    esac
  fi

  mkdir -p "$destdir"
  cp -p "$src" "$dest"
  log "promote $host $id -> $dest"

  # pi filenames are <timestamp>_<uuid>; claude filenames are the uuid itself.
  local uuid
  uuid=$(basename "$src" .jsonl)
  [[ "$agent" == pi ]] && uuid=${uuid##*_}
  printf 'promoted -> %s\n\n' "$dest"
  printf 'resume with:\n  cd %s\n' "${lcwd:-<project dir>}"
  case "$agent" in
    claude) printf '  claude --resume %s\n' "$uuid" ;;
    pi)     printf '  pi --resume %s\n' "$uuid" ;;
  esac
}

cmd_daemon() {
  local host=${1:-}
  [[ -n "$host" ]] || die "usage: agent-session-sync daemon <host>"
  [[ "$host" != */* && "$host" != .* ]] || die "invalid host: $host"

  # One daemon per host: two of them race on .last-sync and duplicate all work.
  mkdir -p "$MIRROR"
  exec {lockfd}>"$MIRROR/.daemon.$host.lock"
  flock -n "$lockfd" || die "a daemon is already running for $host"

  trap 'log "daemon stop: $host"; exit 0' INT TERM
  printf 'syncing %s every %ss (mirror: %s)\n' "$host" "$INTERVAL" "$MIRROR"
  log "daemon start: $host every ${INTERVAL}s"
  local fails=0
  while :; do
    if cmd_pull "$host"; then
      fails=0
    else
      fails=$((fails + 1))
      # Back off on a dead host so a 2am outage does not spin ssh every 15m,
      # but never past 4x the interval — the box may come back.
      local backoff=$(( INTERVAL * (fails < 4 ? fails : 4) ))
      log "daemon: $fails consecutive failures, sleeping ${backoff}s"
      sleep "$backoff"
      continue
    fi
    sleep "$INTERVAL"
  done
}

case "${1:-}" in
  pull)    shift; cmd_pull "$@" ;;
  status)  shift; cmd_status "$@" ;;
  list)    shift; cmd_list "$@" ;;
  promote) shift; cmd_promote "$@" ;;
  daemon)  shift; cmd_daemon "$@" ;;
  *)
    cat <<'EOF'
agent-session-sync — mirror remote agent transcripts locally

  pull <host>               one sync pass
  status                    what is mirrored, and how stale
  list <host>               mirrored sessions
  promote <host> <id>       copy one session into the live store (newer wins)
  daemon <host>             loop pull on an interval

env:
  AGENT_SYNC_MIRROR         default ~/.local/state/agent-session-sync
  AGENT_SYNC_INTERVAL       default 900
  AGENT_SYNC_STALE_AFTER    default 3600
EOF
    exit 1 ;;
esac
