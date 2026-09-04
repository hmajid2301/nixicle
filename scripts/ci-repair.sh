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
ollama_auth_header=( -H "Authorization: Bearer $OLLAMA_API_KEY" )
traces=""
summary=""
diagnosis=""
suggested_fixes_json='[]'
patch=""
comment=""
confidence="unknown"

post_mr_note() {
  local body="$1"

  curl -fsS --request POST \
    --header "PRIVATE-TOKEN: $REPAIR_GITLAB_TOKEN" \
    --header 'Content-Type: application/json' \
    --data "$(jq -nc --arg body "$body" '{body:$body}')" \
    "$CI_API_V4_URL/projects/$CI_PROJECT_ID/merge_requests/$CI_MERGE_REQUEST_IID/notes" >/dev/null
}

render_suggested_fixes_markdown() {
  printf '%s' "$suggested_fixes_json" | jq -r '
    if length == 0 then
      ""
    else
      .[]
      | "#### `\(.file // "unknown")`\n\n- lines: \(.lines // "unknown")\n- location: \(.location // "unknown")\n- problem: \(.problem // "")\n- change: \(.change // "")\n\n```\n\(.replacement // "")\n```\n"
    end
  '
}

build_note() {
  local title="$1"
  local extra_artifacts="$2"
  local suggested_fixes_markdown

  suggested_fixes_markdown="$(render_suggested_fixes_markdown)"

  note="$({
    printf '## 🤖 Repair attempt\n\n'
    printf '**Status:** %s\n\n' "$title"
    printf '### Summary\n\n%s\n\n' "${summary:-n/a}"
    printf '### Diagnosis\n\n%s\n\n' "${diagnosis:-n/a}"
    printf '### Confidence\n\n- `%s`\n\n' "$confidence"
    if [ -n "$suggested_fixes_markdown" ]; then
      printf '### Suggested fixes\n\n%s\n' "$suggested_fixes_markdown"
    fi
    printf '### Artifacts\n\n'
    printf -- '- `repair/repair.patch`\n'
    [ -n "$extra_artifacts" ] && printf '%s\n' "$extra_artifacts"
    if [ -n "$comment" ]; then
      printf '\n### Note\n\n%s\n' "$comment"
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
  [ -n "$comment" ] && printf '%s\n' "$comment" > "$repair_dir/comment.md"
}

apply_patch_and_retest() {
  if [ -z "$patch" ]; then
    build_note "no patch produced" ""
    return
  fi

  if ! grep -q '^diff --git ' "$repair_dir/repair.patch"; then
    build_note "invalid patch produced" "- `repair/git-apply-check.log`"
    return
  fi

  if ! git apply --check --whitespace=nowarn "$repair_dir/repair.patch" >/dev/null 2>"$repair_dir/git-apply-check.log"; then
    build_note "invalid patch produced" "- `repair/git-apply-check.log`"
    return
  fi

  git apply --whitespace=nowarn "$repair_dir/repair.patch"

  if nix flake check --print-build-logs 2>&1 | tee "$repair_dir/retest.log"; then
    build_note "patch applied and retest passed" ""
  else
    build_note "patch applied but retest failed" "- `repair/retest.log`"
  fi
}

failed_jobs_json="$(fetch_failed_jobs_json)"
printf '%s\n' "$failed_jobs_json" > "$repair_dir/failed-jobs.json"

if [ "$(printf '%s' "$failed_jobs_json" | jq 'length')" -eq 0 ]; then
  post_mr_note "🤖 Repair attempt skipped: no failed non-repair jobs found in the current pipeline."
  exit 0
fi

collect_traces "$failed_jobs_json"
collect_diff_context
render_prompt
request_model
parse_model_response
write_summary
apply_patch_and_retest
post_mr_note "$note"
