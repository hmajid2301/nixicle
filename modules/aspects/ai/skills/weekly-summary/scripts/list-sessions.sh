#!/usr/bin/env bash
# Lists Claude Code and pi sessions touched since a date, one block per session.
# Usage: list-sessions.sh [YYYY-MM-DD] [tail-chars]
# Defaults to Monday of the current week and the last 600 chars of the final reply.
set -u

since=${1:-$(date -d "$(date +%F) -$(( $(date +%u) - 1 )) days" +%F)}
tail_chars=${2:-600}

first_prompt_claude='select(.type=="user" and (.isMeta|not)) | .message.content
  | if type=="string" then . else (map(select(.type=="text").text) | join(" ")) end'
last_reply_claude='select(.type=="assistant") | .message.content[]? | select(.type=="text") | .text'
title_claude='select(.type=="custom-title" or .type=="ai-title" or .type=="summary")
  | (.customTitle // .aiTitle // .summary // empty)'

first_prompt_pi='select(.type=="message" and .message.role=="user") | .message.content
  | if type=="string" then . else (map(select(.type=="text").text) | join(" ")) end'
last_reply_pi='select(.type=="message" and .message.role=="assistant") | .message.content[]? | select(.type=="text") | .text'
title_pi='select(.type=="session_info") | (.name // empty)'

clean_prompt() {
  grep -v '^<\|^\[Request\|^Caveat\|^$' | head -2 | tr '\n' ' ' | cut -c1-250
}

emit() {
  local tool=$1 file=$2 cwd=$3 title=$4 prompt=$5 reply=$6
  printf '=== %s | %s | %s\n' "$(date -r "$file" '+%a %F %H:%M')" "$tool" "$cwd"
  printf 'file: %s\n' "$file"
  [[ -n $title ]] && printf 'title: %s\n' "$title"
  [[ -n $prompt ]] && printf 'prompt: %s\n' "$prompt"
  printf 'last reply: %s\n\n' "$(printf '%s' "$reply" | tail -c "$tail_chars" | tr '\n' ' ')"
}

if [[ -d ~/.claude/projects ]]; then
  find ~/.claude/projects -name '*.jsonl' -newermt "$since" -size +5k -not -path '*/subagents/*' -print0 |
    while IFS= read -r -d '' f; do
      cwd=$(jq -r 'select(.cwd) | .cwd' "$f" 2>/dev/null | head -1)
      title=$(jq -r "$title_claude" "$f" 2>/dev/null | tail -1)
      prompt=$(jq -r "$first_prompt_claude" "$f" 2>/dev/null | clean_prompt)
      reply=$(jq -r "$last_reply_claude" "$f" 2>/dev/null)
      emit claude "$f" "$cwd" "$title" "$prompt" "$reply"
    done
fi

if [[ -d ~/.pi/agent/sessions ]]; then
  find ~/.pi/agent/sessions -name '*.jsonl' -newermt "$since" -size +5k -not -path '*/subagents/*' -print0 |
    while IFS= read -r -d '' f; do
      cwd=$(jq -r 'select(.type=="session") | .cwd' "$f" 2>/dev/null | head -1)
      title=$(jq -r "$title_pi" "$f" 2>/dev/null | tail -1)
      prompt=$(jq -r "$first_prompt_pi" "$f" 2>/dev/null | clean_prompt)
      reply=$(jq -r "$last_reply_pi" "$f" 2>/dev/null)
      emit pi "$f" "$cwd" "$title" "$prompt" "$reply"
    done
fi
