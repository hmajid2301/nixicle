#!/usr/bin/env bash
set -euo pipefail

mkdir -p repair

: "${REPAIR_GITLAB_TOKEN:?need REPAIR_GITLAB_TOKEN (project access token with api scope)}"
: "${OLLAMA_API_KEY:?need OLLAMA_API_KEY for cloud model access}"
ollama_url="${OLLAMA_BASE_URL:-https://ollama.com/api/chat}"
model="${OLLAMA_MODEL:-deepseek-v4-pro}"
ollama_auth_header=( -H "Authorization: Bearer $OLLAMA_API_KEY" )
max_trace_chars="${REPAIR_MAX_TRACE_CHARS:-40000}"

append_trace() {
  local job_name="$1"
  local job_id="$2"
  local trace="$3"
  local trace_file="repair/trace-${job_id}-${job_name//[:\/ ]/_}.log"

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

traces=""
failed_jobs_json="$(curl -fsS \
  --header "PRIVATE-TOKEN: $REPAIR_GITLAB_TOKEN" \
  "$CI_API_V4_URL/projects/$CI_PROJECT_ID/pipelines/$CI_PIPELINE_ID/jobs?scope[]=failed" \
  | jq '[.[] | select(.name != "repair")]')"

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

if [ "$(printf '%s' "$failed_jobs_json" | jq 'length')" -eq 0 ]; then
  note="🤖 Repair attempt skipped: no failed non-repair jobs found in the current pipeline."
  curl -fsS --request POST \
    --header "PRIVATE-TOKEN: $REPAIR_GITLAB_TOKEN" \
    --header 'Content-Type: application/json' \
    --data "$(jq -nc --arg body "$note" '{body:$body}')" \
    "$CI_API_V4_URL/projects/$CI_PROJECT_ID/merge_requests/$CI_MERGE_REQUEST_IID/notes" >/dev/null
  exit 0
fi

diff_base="${CI_MERGE_REQUEST_DIFF_BASE_SHA:-${CI_COMMIT_BEFORE_SHA:-}}"
if [ -n "$diff_base" ] && [ "$diff_base" != "0000000000000000000000000000000000000000" ]; then
  diff="$(git diff --unified=80 "$diff_base...$CI_COMMIT_SHA" || true)"
  files="$(git diff --name-only "$diff_base...$CI_COMMIT_SHA" || true)"
else
  diff="$(git show --stat --patch --format=medium "$CI_COMMIT_SHA" || true)"
  files="$(git diff --name-only "$CI_COMMIT_SHA" || true)"
fi

cat > repair/prompt.md <<EOF
You are a GitLab MR repair assistant for repository $CI_PROJECT_PATH.

Goal:
- Fix the failure with the smallest possible patch.
- Prefer direct code/config fixes over workarounds.
- Do not invent new secrets or tokens.
- If the failure is unrelated to code, return a patch that documents the root cause in a comment near the relevant config.

MR:
- IID: ${CI_MERGE_REQUEST_IID:-}
- Title: ${CI_MERGE_REQUEST_TITLE:-}

Failed jobs JSON:
$failed_jobs_json

Changed files:
$files

Diff context:
$diff

Job traces:
$traces

Return ONLY valid JSON with these keys:
- summary: short string
- patch: unified diff as a string, or empty string if no patch is possible
- comment: short markdown note for the MR
- confidence: one of low, medium, high
EOF

prompt="$(cat repair/prompt.md)"
jq -n --rawfile prompt repair/prompt.md --arg model "$model" '{model:$model,messages:[{role:"system",content:"Return JSON only."},{role:"user",content:$prompt}],stream:false}' > repair/request.json
http_code="$(curl -sS "$ollama_url" "${ollama_auth_header[@]}" -H 'Content-Type: application/json' --data @repair/request.json -o repair/response.json -w '%{http_code}')"
if [ "$http_code" != "200" ]; then
  echo "ollama request failed with HTTP $http_code" >&2
  exit 1
fi
content="$(jq -r '.message.content // .response // .choices[0].message.content // empty' repair/response.json)"
result_json="$(printf '%s' "$content" | jq -c . 2>/dev/null || true)"
if [ -z "$result_json" ]; then
  result_json="$(printf '%s' "$content" | sed -n '/^```json$/,/^```$/p' | sed '1d;$d' | jq -c . 2>/dev/null || true)"
fi
if [ -z "$result_json" ]; then
  echo "ollama response was not valid JSON" >&2
  printf '%s\n' "$content" > repair/response.txt
  exit 1
fi

summary="$(printf '%s' "$result_json" | jq -r '.summary // ""')"
patch="$(printf '%s' "$result_json" | jq -r '.patch // ""')"
comment="$(printf '%s' "$result_json" | jq -r '.comment // ""')"
confidence="$(printf '%s' "$result_json" | jq -r '.confidence // "unknown"')"

printf '# Repair summary\n\n- confidence: %s\n- summary: %s\n' "$confidence" "$summary" > repair/summary.md
printf '%s\n' "$prompt" > repair/prompt.md
printf '%s\n' "$patch" > repair/repair.patch
[ -n "$comment" ] && printf '%s\n' "$comment" > repair/comment.md

note="🤖 Repair attempt: ${summary:-applied a patch and re-tested successfully.}\n\nConfidence: ${confidence}\n\nPatch stored in job artifacts: \`repair/repair.patch\`"

if [ -n "$patch" ]; then
  if grep -q '^diff --git ' repair/repair.patch && git apply --check --whitespace=nowarn repair/repair.patch >/dev/null 2>repair/git-apply-check.log; then
    git apply --whitespace=nowarn repair/repair.patch
    if nix flake check --print-build-logs 2>&1 | tee repair/retest.log; then
      :
    else
      note="🤖 Repair attempt produced a patch but the retest still failed.\n\nSummary: ${summary:-n/a}\nConfidence: ${confidence}\n\nPatch artifact: \`repair/repair.patch\`\nRetest log: \`repair/retest.log\`"
    fi
  else
    note="🤖 Repair attempt produced an invalid patch.\n\nSummary: ${summary:-n/a}\nConfidence: ${confidence}\n\nPatch artifact: \`repair/repair.patch\`"
  fi
else
  note="🤖 Repair attempt produced no patch.\n\nSummary: ${summary:-n/a}\nConfidence: ${confidence}\n\nPatch artifact: \`repair/repair.patch\`"
fi

curl -fsS --request POST \
  --header "PRIVATE-TOKEN: $REPAIR_GITLAB_TOKEN" \
  --header 'Content-Type: application/json' \
  --data "$(jq -nc --arg body "$note" '{body:$body}')" \
  "$CI_API_V4_URL/projects/$CI_PROJECT_ID/merge_requests/$CI_MERGE_REQUEST_IID/notes" >/dev/null
