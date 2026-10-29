#!/usr/bin/env bash
# Claude Code statusline - Catppuccin Mocha, rounded pill segments (pi-catppuccin-footer style)

input=$(cat)

# mapfile -d preserves empty fields; `IFS=$'\t' read` silently collapses
# consecutive tabs and shifts every later column, so it cannot be used here.
mapfile -d $'\t' -t _fields < <(jq -j '[
    (.model.display_name // .model.id // "unknown"),
    (.session_name // ""),
    (.workspace.current_dir // ""),
    (.context_window.context_window_size // 200000),
    (.context_window.used_percentage // ""),
    (.rate_limits.five_hour.used_percentage // ""),
    (.rate_limits.five_hour.resets_at // ""),
    (.rate_limits.seven_day.used_percentage // ""),
    (.rate_limits.seven_day.resets_at // ""),
    (.effort.level // ""),
    (.pr.number // ""),
    (.pr.review_state // ""),
    (.worktree.name // ""),
    (.prompt_cache.warm // ""),
    (.workspace.repo.host // "")
  ] | join("\t")' <<< "$input")
model="${_fields[0]}"
session_name="${_fields[1]}"
cwd="${_fields[2]}"
max_ctx="${_fields[3]}"
used_pct="${_fields[4]}"
five_hour_pct="${_fields[5]}"
five_hour_reset="${_fields[6]}"
week_pct="${_fields[7]}"
effort="${_fields[9]}"
pr_number="${_fields[10]}"
pr_review_state="${_fields[11]}"
worktree_name="${_fields[12]}"
cache_warm="${_fields[13]}"
repo_host="${_fields[14]%$'\n'}"

# Prune cache files older than a day so /tmp doesn't accumulate one pair per
# project ever opened. Gated behind its own sentinel so the find walk only
# runs once/day, not on every statusline render.
prune_sentinel="/tmp/cc-statusline-pruned"
if [ ! -f "$prune_sentinel" ] || [ $(( $(date +%s) - $(stat -c %Y "$prune_sentinel" 2>/dev/null || stat -f %m "$prune_sentinel" 2>/dev/null || echo 0) )) -gt 86400 ]; then
    touch "$prune_sentinel"
    find /tmp -maxdepth 1 -name 'cc-statusline-*' -mtime +1 -delete 2>/dev/null &
    disown
fi

# Git: branch + dirty status, cached 5s, keyed by cwd
branch=""
dirty=""
if git rev-parse --git-dir > /dev/null 2>&1; then
    cache_key=$(echo -n "$cwd" | cksum | cut -d' ' -f1)
    cache_file="/tmp/cc-statusline-git-${cache_key}"
    cache_age=999
    if [ -f "$cache_file" ]; then
        cache_age=$(( $(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null || echo 0) ))
    fi
    if [ "$cache_age" -gt 5 ]; then
        b=$(git branch --show-current 2>/dev/null)
        [ -z "$b" ] && b=$(git rev-parse --short HEAD 2>/dev/null)
        d=""
        [ -n "$(git status --porcelain 2>/dev/null | head -1)" ] && d="1"
        printf '%s\t%s\n' "$b" "$d" > "$cache_file"
    fi
    IFS=$'\t' read -r branch dirty < "$cache_file"
    [ "${#branch}" -gt 24 ] && branch="${branch:0:23}…"
fi

# CI status: never block on the network. Read whatever's cached (30s TTL) and,
# if stale, kick off a detached background refresh for the *next* render.
ci_status=""
if [ -n "$branch" ]; then
    ci_cache_file="/tmp/cc-statusline-ci-${cache_key}"
    ci_cache_age=999
    if [ -f "$ci_cache_file" ]; then
        ci_cache_age=$(( $(date +%s) - $(stat -c %Y "$ci_cache_file" 2>/dev/null || stat -f %m "$ci_cache_file" 2>/dev/null || echo 0) ))
    fi
    [ -f "$ci_cache_file" ] && ci_status=$(cat "$ci_cache_file")
    if [ "$ci_cache_age" -gt 30 ]; then
        touch "$ci_cache_file"
        (
            cd "$cwd" 2>/dev/null || exit 0
            result=""
            if [[ "$repo_host" == *gitlab* ]] && command -v glab > /dev/null 2>&1; then
                state=$(glab api "projects/:id/pipelines?ref=${branch}&per_page=1" 2>/dev/null | jq -r '.[0].status // empty')
                case "$state" in
                    success) result="pass" ;;
                    failed) result="fail" ;;
                    running|pending) result="running" ;;
                esac
            elif command -v gh > /dev/null 2>&1; then
                bucket=$(gh pr checks --json bucket 2>/dev/null | jq -r 'if length == 0 then empty elif any(.[]; .bucket == "fail") then "fail" elif any(.[]; .bucket == "pending") then "running" else "pass" end')
                result="$bucket"
            fi
            printf '%s' "$result" > "$ci_cache_file"
        ) & disown
    fi
fi

# Catppuccin Mocha (24-bit true color)
BG_HEX="49;50;68"  # surface0, the dark text-pill background

declare -A HEX=(
  [mauve]="203;166;247"
  [blue]="137;180;250"
  [teal]="148;226;213"
  [lavender]="180;190;254"
  [green]="166;227;161"
  [yellow]="249;226;175"
  [peach]="250;179;135"
  [red]="243;139;168"
  [pink]="245;194;231"
  [sky]="137;220;235"
)

# Powerline round-cap glyphs (Nerd Font)
CAP_LEFT=$''
CAP_RIGHT=$''

pct_color() {
    local pct="$1"
    [ -z "$pct" ] && { echo ""; return; }
    local p; p=$(printf '%.0f' "$pct" 2>/dev/null || echo 0)
    if [ "$p" -ge 90 ]; then echo "red"
    elif [ "$p" -ge 70 ]; then echo "peach"
    elif [ "$p" -ge 40 ]; then echo "yellow"
    else echo "green"
    fi
}

fmt_reset_in() {
    local epoch="$1"
    [ -z "$epoch" ] && return
    local now diff h m
    now=$(date +%s)
    diff=$(( epoch - now ))
    [ "$diff" -lt 0 ] && diff=0
    h=$(( diff / 3600 ))
    m=$(( (diff % 3600) / 60 ))
    if [ "$h" -gt 0 ]; then echo "${h}h${m}m"; else echo "${m}m"; fi
}

# 10-segment block bar, e.g. ▓▓▓▓░░░░░░ - filled blocks colored by threshold,
# empty blocks dimmed against the dark text-pill background.
OVERLAY_HEX="88;91;112"  # overlay1, for the unfilled portion of the bar
progress_bar() {
    local pct="$1" color="$2"
    local hex="${HEX[$color]}"
    local filled=$(( pct / 10 ))
    [ "$filled" -gt 10 ] && filled=10
    local bar="" i
    for i in 0 1 2 3 4 5 6 7 8 9; do
        if [ "$i" -lt "$filled" ]; then
            bar="${bar}\033[38;2;${hex}m▓"
        else
            bar="${bar}\033[38;2;${OVERLAY_HEX}m░"
        fi
    done
    printf '%b\033[38;2;205;214;244m' "$bar"
}

# One fused tab, like a zellij/tmux tab: round cap only at the far left and
# far right; the icon zone's background abuts the text zone's background
# directly with no cap glyph between them, so it reads as one continuous
# pill instead of two circles glued together. Mirrors zjstatus tab_active.
segment() {
    local color="$1" icon="$2" text="$3"
    local hex="${HEX[$color]}"
    printf '\033[38;2;%sm%s\033[0m' "$hex" "$CAP_LEFT"
    printf '\033[48;2;%sm\033[38;2;17;17;27m\033[1m %s \033[0m' "$hex" "$icon"
    printf '\033[48;2;%sm\033[38;2;205;214;244m %b \033[0m' "$BG_HEX" "$text"
    printf '\033[38;2;%sm%s\033[0m' "$BG_HEX" "$CAP_RIGHT"
}

# Icons (Nerd Font, explicit codepoints so they never silently go missing)
ICON_BRANCH=$''      # nf-fa-code_fork
ICON_DIRTY=$''       # nf-md-circle
ICON_SESSION=$''     # nf-fa-terminal
ICON_CONTEXT=$''     # nf-fa-dashboard
ICON_CLOCK=$''       # nf-fa-clock_o
ICON_CALENDAR=$''    # nf-fa-calendar
ICON_MODEL=$''       # nf-fa-robot / md-robot
ICON_PR=$'\xef\x90\x87'  # nf-oct-git_pull_request
ICON_WORKTREE=$'\xef\x86\xbb'  # nf-fa-tree
ICON_CI_PASS=$'\xef\x80\x8c'  # nf-fa-check
ICON_CI_FAIL=$'\xef\x80\x8d'  # nf-fa-times
ICON_CI_RUN=$'\xef\x80\xa1'  # nf-fa-refresh
ICON_CACHE_HOT=$'\xef\x81\xad'  # nf-fa-fire
ICON_CACHE_COLD=$'\xef\x8b\x9c'  # nf-fa-snowflake_o

left=""

if [ -n "$branch" ]; then
    icon="$ICON_BRANCH"
    [ -n "$dirty" ] && icon="$ICON_DIRTY"
    left="${left}$(segment lavender "$icon" "${branch}${dirty:+ ●}")"
fi

if [ -n "$worktree_name" ]; then
    left="${left}${left:+ }$(segment peach "$ICON_WORKTREE" "${worktree_name}")"
fi

if [ -n "$pr_number" ]; then
    pr_color="teal"
    case "$pr_review_state" in
        approved) pr_color="green" ;;
        changes_requested) pr_color="red" ;;
        draft) pr_color="sky" ;;
        pending) pr_color="yellow" ;;
    esac
    left="${left}${left:+ }$(segment "$pr_color" "$ICON_PR" "#${pr_number}${pr_review_state:+ ${pr_review_state//_/ }}")"
fi

if [ -n "$ci_status" ]; then
    case "$ci_status" in
        pass) left="${left}${left:+ }$(segment green "$ICON_CI_PASS" "CI")" ;;
        fail) left="${left}${left:+ }$(segment red "$ICON_CI_FAIL" "CI")" ;;
        running) left="${left}${left:+ }$(segment yellow "$ICON_CI_RUN" "CI")" ;;
    esac
fi

if [ -n "$session_name" ]; then
    left="${left}${left:+ }$(segment lavender "$ICON_SESSION" "${session_name}")"
fi

if [ "$cache_warm" = "true" ]; then
    left="${left} $(segment peach "$ICON_CACHE_HOT" "cache")"
elif [ "$cache_warm" = "false" ]; then
    left="${left} $(segment sky "$ICON_CACHE_COLD" "cache")"
fi

# Plain colored text joined by dim vertical-bar separators (no pill
# background), used for the usage side of the statusline.
SEP_GLYPH=$'\xe2\x94\x82'  # U+2502 BOX DRAWINGS LIGHT VERTICAL
SEP="\033[38;2;${OVERLAY_HEX}m ${SEP_GLYPH} \033[0m"
plain() {
    local color="$1" text="$2"
    local hex="${HEX[$color]}"
    printf '\033[38;2;%sm%b\033[0m' "$hex" "$text"
}

right=""

if [ -z "$used_pct" ] || [ "$used_pct" = "null" ]; then
    right="${right}$(plain sky "${ICON_CONTEXT} --")"
else
    pct=$(printf "%.0f" "$used_pct" 2>/dev/null || echo "$used_pct")
    [ "$pct" -gt 100 ] 2>/dev/null && pct=100
    used_k=$(( max_ctx * pct / 100 / 1000 ))
    max_k=$(( max_ctx / 1000 ))
    ctx_color=$(pct_color "$pct")
    [ -z "$ctx_color" ] && ctx_color="sky"
    bar=$(progress_bar "$pct" "$ctx_color")
    right="${right}$(plain "$ctx_color" "${ICON_CONTEXT}") ${bar} $(plain "$ctx_color" "${used_k}k/${max_k}k")"
fi

if [ -n "$five_hour_pct" ]; then
    fh=$(printf "%.0f" "$five_hour_pct" 2>/dev/null || echo "$five_hour_pct")
    fh_reset=$(fmt_reset_in "$five_hour_reset")
    fh_color=$(pct_color "$fh"); [ -z "$fh_color" ] && fh_color="teal"
    right="${right}${SEP}$(plain "$fh_color" "${ICON_CLOCK} ${fh}%${fh_reset:+ ⟳${fh_reset}}")"
fi

if [ -n "$week_pct" ]; then
    wk=$(printf "%.0f" "$week_pct" 2>/dev/null || echo "$week_pct")
    wk_color=$(pct_color "$wk"); [ -z "$wk_color" ] && wk_color="teal"
    right="${right}${SEP}$(plain "$wk_color" "${ICON_CALENDAR} ${wk}%")"
fi

right="${right}${SEP}$(plain lavender "${ICON_MODEL} ${model}${effort:+ ·${effort}}")"

cols="${COLUMNS:-120}"
left_visible=$(printf '%b' "$left" | sed -E 's/\x1b\[[0-9;]*m//g')
right_visible=$(printf '%b' "$right" | sed -E 's/\x1b\[[0-9;]*m//g')
left_len=${#left_visible}
right_len=${#right_visible}
gap=$(( cols - left_len - right_len - 2 ))
[ "$gap" -lt 1 ] && gap=1
padding=$(printf '%*s' "$gap" '')

printf '%b%s%b\n' "$left" "$padding" "$right"
