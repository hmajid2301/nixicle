#!/usr/bin/env bash
set -euo pipefail

repair_dir="repair"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
prompt_template="$script_dir/ci-repair-prompt.md"

mkdir -p "$repair_dir"

: "${REPAIR_GITLAB_TOKEN:?need REPAIR_GITLAB_TOKEN (project access token with api scope)}"
: "${OLLAMA_API_KEY:?need OLLAMA_API_KEY for cloud model access}"

ollama_url="${OLLAMA_BASE_URL:-https://ollama.com/api/chat}"
model="${OLLAMA_MODEL:-deepseek-v4-pro}"
max_trace_chars="${REPAIR_MAX_TRACE_CHARS:-40000}"
max_repair_attempts="${REPAIR_MAX_ATTEMPTS:-3}"
ollama_auth_header=( -H "Authorization: Bearer $OLLAMA_API_KEY" )
repair_note_id=""
repair_note_body=""
fixed_commit_sha=""
traces=""
summary=""
diagnosis=""
suggested_fixes_json='[]'
patch=""
comment=""
confidence="unknown"
note=""
repair_attempts=0

# The repair bot keeps a single note per MR, identified by its heading.
repair_note_marker='## 🤖 Repair attempt'

find_repair_note() {
  local page=1
  local notes_json
  local matched

  while :; do
    notes_json="$(curl -fsS \
      --header "PRIVATE-TOKEN: $REPAIR_GITLAB_TOKEN" \
      "$CI_API_V4_URL/projects/$CI_PROJECT_ID/merge_requests/$CI_MERGE_REQUEST_IID/notes?per_page=100&page=$page" \
      || printf '[]')"
    if [ "$(printf '%s' "$notes_json" | jq 'length')" -eq 0 ]; then
      return
    fi

    matched="$(printf '%s' "$notes_json" \
      | jq -c --arg marker "$repair_note_marker" '[.[] | select(.system != true and (.body | contains($marker)))] | .[0] // empty')"
    if [ -n "$matched" ] && [ "$matched" != "null" ]; then
      repair_note_id="$(printf '%s' "$matched" | jq -r '.id')"
      repair_note_body="$(printf '%s' "$matched" | jq -r '.body')"
      return
    fi

    page=$((page + 1))
  done
}

upsert_mr_note() {
  local body="$1"

  if [ -n "$repair_note_id" ]; then
    curl -fsS --request PUT \
      --header "PRIVATE-TOKEN: $REPAIR_GITLAB_TOKEN" \
      --header 'Content-Type: application/json' \
      --data "$(jq -nc --arg body "$body" '{body:$body}')" \
      "$CI_API_V4_URL/projects/$CI_PROJECT_ID/merge_requests/$CI_MERGE_REQUEST_IID/notes/$repair_note_id" >/dev/null
  else
    curl -fsS --request POST \
      --header "PRIVATE-TOKEN: $REPAIR_GITLAB_TOKEN" \
      --header 'Content-Type: application/json' \
      --data "$(jq -nc --arg body "$body" '{body:$body}')" \
      "$CI_API_V4_URL/projects/$CI_PROJECT_ID/merge_requests/$CI_MERGE_REQUEST_IID/notes" >/dev/null
  fi
}

render_suggested_fixes_markdown() {
  printf '%s' "$suggested_fixes_json" | jq -r '
    def fence_lang($file):
      if ($file | endswith(".nix")) then "nix"
      elif ($file | endswith(".sh")) then "bash"
      elif ($file | endswith(".bash")) then "bash"
      elif ($file | endswith(".zsh")) then "zsh"
      elif ($file | endswith(".fish")) then "fish"
      elif ($file | endswith(".json")) then "json"
      elif ($file | endswith(".jsonc")) then "json"
      elif ($file | endswith(".yaml")) or ($file | endswith(".yml")) then "yaml"
      elif ($file | endswith(".toml")) then "toml"
      elif ($file | endswith(".md")) then "md"
      elif ($file | endswith(".ts")) then "ts"
      elif ($file | endswith(".tsx")) then "tsx"
      elif ($file | endswith(".js")) then "js"
      elif ($file | endswith(".jsx")) then "jsx"
      elif ($file | endswith(".py")) then "python"
      elif ($file | endswith(".go")) then "go"
      elif ($file | endswith(".rs")) then "rust"
      elif ($file | endswith(".lua")) then "lua"
      else ""
      end;
    if length == 0 then
      ""
    else
      .[]
      | (.file // "unknown") as $file
      | "#### `\($file)`\n\n- lines: \(.lines // "unknown")\n- location: \(.location // "unknown")\n- problem: \(.problem // "")\n- change: \(.change // "")\n\n```\(fence_lang($file))\n\(.replacement // "")\n```\n"
    end
  '
}

build_note() {
  local title="$1"
  local extra_artifacts="$2"
  local suggested_fixes_markdown

  suggested_fixes_markdown="$(render_suggested_fixes_markdown)"

  note="$({
    # Hidden markers: one note per MR, multiple repair attempts allowed up to REPAIR_MAX_ATTEMPTS.
    printf '<!--repair:note--><!--repair:attempted-->'
    if [ -n "$fixed_commit_sha" ]; then
      printf '<!--repair:applied-->'
    fi
    printf '\n\n'
    printf '%s\n\n' "$repair_note_marker"
    printf '**Status:** %s\n\n' "$title"
    printf '**Attempt:** %s of %s\n\n' "$((repair_attempts + 1))" "$max_repair_attempts"
    if [ -n "$fixed_commit_sha" ]; then
      printf '### Fix applied\n\n'
      printf -- '- Commit `%s` pushed to `%s` by the AI repair bot (`%s`)\n\n' \
        "$fixed_commit_sha" "${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME:-unknown branch}" "$model"
    fi
    printf '### Summary\n\n%s\n\n' "${summary:-n/a}"
    printf '### Diagnosis\n\n%s\n\n' "${diagnosis:-n/a}"
    printf '### Confidence\n\n- `%s`\n\n' "$confidence"
    if [ -n "$suggested_fixes_markdown" ]; then
      printf '### Suggested fixes\n\n%s\n' "$suggested_fixes_markdown"
    fi
    printf '### Artifacts\n\n'
    printf -- '- `repair/repair.patch`\n'
    if [ -n "$extra_artifacts" ]; then
      printf '%b\n' "$extra_artifacts"
    fi
    if [ -n "$comment" ]; then
      printf '\n### Note\n\n%s\n' "$comment"
    fi
    if [ -n "$repair_note_body" ]; then
      printf '\n---\n\n### Previous repair notes\n\n%s\n' "$repair_note_body"
    fi
  } )"
}

fetch_failed_jobs_json() {
  curl -fsS \
    --header "PRIVATE-TOKEN: $REPAIR_GITLAB_TOKEN" \
    "$CI_API_V4_URL/projects/$CI_PROJECT_ID/pipelines/$CI_PIPELINE_ID/jobs?scope[]=failed" \
    | jq '[.[] | select(.name != "repair")]'
}

append_trace() {
  local job_name="$1"
  local job_id="$2"
  local trace="$3"
  local safe_job_name
  local trace_file

  safe_job_name="$(printf '%s' "$job_name" | tr ' /:' '___')"
  trace_file="$repair_dir/trace-${job_id}-${safe_job_name}.log"
  printf '%s' "$trace" > "$trace_file"

  if [ "${#trace}" -gt "$max_trace_chars" ]; then
    trace="[trace truncated to last ${max_trace_chars} chars for model input; full trace saved to ${trace_file}]\n${trace: -$max_trace_chars}"
  fi

  traces+=$'\n## Job: '
  traces+="$job_name"
  traces+=$' ('
  traces+="$job_id"
  traces+=$')\n\n'
  traces+="$trace"
  traces+=$'\n'
}

collect_traces() {
  local failed_jobs_json="$1"
  local job
  local job_id
  local job_name
  local job_slug
  local artifact_trace
  local trace

  while IFS= read -r job; do
    [ -n "$job" ] || continue
    job_id="$(printf '%s' "$job" | jq -r '.id')"
    job_name="$(printf '%s' "$job" | jq -r '.name')"
    job_slug="${job_name#build:}"
    artifact_trace="build-logs/${job_slug}.log"

    if [ -f "$artifact_trace" ]; then
      trace="$(cat "$artifact_trace")"
    else
      trace="$(curl -fsS --header "PRIVATE-TOKEN: $REPAIR_GITLAB_TOKEN" \
        "$CI_API_V4_URL/projects/$CI_PROJECT_ID/jobs/$job_id/trace" || true)"
    fi

    append_trace "$job_name" "$job_id" "$trace"
  done < <(printf '%s' "$failed_jobs_json" | jq -c '.[]')
}

collect_diff_context() {
  local diff_base

  diff_base="${CI_MERGE_REQUEST_DIFF_BASE_SHA:-${CI_COMMIT_BEFORE_SHA:-}}"
  if [ -n "$diff_base" ] && [ "$diff_base" != "0000000000000000000000000000000000000000" ]; then
    diff="$(git diff --unified=80 "$diff_base...$CI_COMMIT_SHA" || true)"
    files="$(git diff --name-only "$diff_base...$CI_COMMIT_SHA" || true)"
  else
    diff="$(git show --stat --patch --format=medium "$CI_COMMIT_SHA" || true)"
    files="$(git diff --name-only "$CI_COMMIT_SHA" || true)"
  fi
}

render_prompt() {
  {
    cat "$prompt_template"
    cat <<'EOF'

## Repository

EOF
    printf -- '- Project: %s\n' "$CI_PROJECT_PATH"
    printf -- '- MR IID: %s\n' "${CI_MERGE_REQUEST_IID:-}"
    printf -- '- MR Title: %s\n' "${CI_MERGE_REQUEST_TITLE:-}"
    cat <<'EOF'

## Failed jobs JSON

```json
EOF
    printf '%s\n' "$failed_jobs_json"
    cat <<'EOF'
```

## Changed files

```text
EOF
    printf '%s\n' "$files"
    cat <<'EOF'
```

## Diff context

```diff
EOF
    printf '%s\n' "$diff"
    cat <<'EOF'
```

## Job traces
EOF
    printf '%s\n' "$traces"
  } > "$repair_dir/prompt.md"
}

request_model() {
  jq -n \
    --rawfile prompt "$repair_dir/prompt.md" \
    --arg model "$model" \
    '{model:$model,messages:[{role:"system",content:"Return JSON only."},{role:"user",content:$prompt}],stream:false}' \
    > "$repair_dir/request.json"

  http_code="$(curl -sS "$ollama_url" "${ollama_auth_header[@]}" -H 'Content-Type: application/json' \
    --data @"$repair_dir/request.json" -o "$repair_dir/response.json" -w '%{http_code}')"

  if [ "$http_code" != "200" ]; then
    echo "ollama request failed with HTTP $http_code" >&2
    exit 1
  fi
}

parse_model_response() {
  local content
  local result_json

  content="$(jq -r '.message.content // .response // .choices[0].message.content // empty' "$repair_dir/response.json")"
  result_json="$(printf '%s' "$content" | jq -c . 2>/dev/null || true)"

  if [ -z "$result_json" ]; then
    result_json="$(printf '%s' "$content" | sed -n '/^```json$/,/^```$/p' | sed '1d;$d' | jq -c . 2>/dev/null || true)"
  fi

  if [ -z "$result_json" ]; then
    echo "ollama response was not valid JSON" >&2
    printf '%s\n' "$content" > "$repair_dir/response.txt"
    exit 1
  fi

  printf '%s\n' "$result_json" > "$repair_dir/result.json"

  summary="$(printf '%s' "$result_json" | jq -r '.summary // ""')"
  diagnosis="$(printf '%s' "$result_json" | jq -r '.diagnosis // ""')"
  suggested_fixes_json="$(printf '%s' "$result_json" | jq -c '.suggested_fixes // []')"
  patch="$(printf '%s' "$result_json" | jq -r '.patch // ""')"
  comment="$(printf '%s' "$result_json" | jq -r '.comment // ""')"
  confidence="$(printf '%s' "$result_json" | jq -r '.confidence // "unknown"')"
}

write_summary() {
  {
    printf '# Repair summary\n\n'
    printf -- '- confidence: %s\n' "$confidence"
    printf -- '- summary: %s\n' "$summary"
    [ -n "$diagnosis" ] && printf -- '- diagnosis: %s\n' "$diagnosis"
    printf '\n## Suggested fixes\n\n'
    printf '%s' "$suggested_fixes_json" | jq -r '
      if length == 0 then
        "- none"
      else
        .[]
        | "- `\(.file // "unknown")` (\(.lines // "unknown"), \(.location // "unknown"))\n  - problem: \(.problem // "")\n  - change: \(.change // "")\n  - replacement:\n\n```\n\(.replacement // "")\n```"
      end
    '
  } > "$repair_dir/summary.md"

  printf '%s\n' "$patch" > "$repair_dir/repair.patch"
  if [ -n "$comment" ]; then
    printf '%s\n' "$comment" > "$repair_dir/comment.md"
  fi
}

patch_files_from_patch() {
  printf '%s\n' "$patch" \
    | grep '^diff --git ' \
    | sed -E 's|^diff --git a/\S+ b/||' \
    || true
}

commit_and_push_fix() {
  git config user.name "ci-repair bot"
  git config user.email "ci-repair@noreply.gitlab.com"

  if ! git commit \
    -m 'fix(ci-repair): apply AI repair patch' \
    -m "AI repair bot (${model}) generated this fix for the failed jobs on MR !${CI_MERGE_REQUEST_IID}.

${summary:-}

Diagnosis: ${diagnosis:-n/a}

Confidence: ${confidence}" \
    -m 'GitLab-CI-Repair: true' \
    >"$repair_dir/commit.log" 2>&1; then
    return 1
  fi

  fixed_commit_sha="$(git rev-parse --short HEAD)"

  git push \
    "https://oauth2:${REPAIR_GITLAB_TOKEN}@${CI_SERVER_HOST}/${CI_PROJECT_PATH}.git" \
    "HEAD:${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME}" \
    >"$repair_dir/push.log" 2>&1 || return 1
}

apply_patch_and_retest() {
  local patch_files=()

  case "$confidence" in
    high|medium) ;;
    *)
      build_note "low confidence; no patch applied" ""
      return
      ;;
  esac

  if [ -z "$patch" ]; then
    build_note "no patch produced" ""
    return
  fi

  if ! grep -q '^diff --git ' "$repair_dir/repair.patch"; then
    build_note "invalid patch produced" "- \`repair/git-apply-check.log\`"
    return
  fi

  if ! git apply --check --whitespace=nowarn "$repair_dir/repair.patch" >/dev/null 2>"$repair_dir/git-apply-check.log"; then
    build_note "invalid patch produced" "- \`repair/git-apply-check.log\`"
    return
  fi

  mapfile -t patch_files < <(patch_files_from_patch)
  if [ "${#patch_files[@]}" -eq 0 ]; then
    build_note "invalid patch produced" "- \`repair/git-apply-check.log\`"
    return
  fi

  if ! git apply --index --whitespace=nowarn "$repair_dir/repair.patch"; then
    build_note "patch could not be applied" "- \`repair/git-apply-check.log\`"
    return
  fi

  if ! nix fmt -- "${patch_files[@]}" >"$repair_dir/fmt.log" 2>&1; then
    build_note "patch applied but formatting failed" "- \`repair/fmt.log\`"
    return
  fi
  git add -- "${patch_files[@]}"

  if nix flake check --print-build-logs 2>&1 | tee "$repair_dir/retest.log"; then
    if commit_and_push_fix; then
      if [ "$confidence" = "medium" ]; then
        comment="${comment:+$comment

}Medium-confidence repair pushed. Human review required before automerge."
      fi
      build_note "fix applied and pushed to the MR branch" ""
    else
      build_note "patch applied but commit or push failed" "- \`repair/commit.log\`\n- \`repair/push.log\`"
    fi
  else
    build_note "patch applied but retest failed" "- \`repair/retest.log\`"
  fi
}

find_repair_note

failed_jobs_json="$(fetch_failed_jobs_json)"
printf '%s\n' "$failed_jobs_json" > "$repair_dir/failed-jobs.json"

if [ "$(printf '%s' "$failed_jobs_json" | jq 'length')" -eq 0 ]; then
  # Green pipeline: nothing to report; never touch the existing repair note.
  exit 0
fi

if [ -n "$repair_note_body" ]; then
  repair_attempts="$( (grep -o '<!--repair:attempted-->' <<<"$repair_note_body" || true) | wc -l | tr -d ' ')"
fi

if [ "$repair_attempts" -ge "$max_repair_attempts" ]; then
  upsert_mr_note "$(
    {
      printf '<!--repair:note-->\n\n'
      printf '%s\n\n' "$repair_note_marker"
      printf '**Status:** reached automatic repair limit (%s attempts); waiting for human intervention.\n\n' "$max_repair_attempts"
      printf '%s\n' '---'
      printf '\n%s\n' "$repair_note_body"
    }
  )"
  exit 0
fi

collect_traces "$failed_jobs_json"
collect_diff_context
render_prompt
request_model
parse_model_response
write_summary
apply_patch_and_retest
upsert_mr_note "$note"