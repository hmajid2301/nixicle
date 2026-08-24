#!/usr/bin/env bash
set -euo pipefail

mkdir -p repair
nix-env -iA nixpkgs.git nixpkgs.curl nixpkgs.jq >/dev/null

: "${REPAIR_GITLAB_TOKEN:?need REPAIR_GITLAB_TOKEN (project access token with api scope)}"
ollama_url="${OLLAMA_BASE_URL:-http://ollama:11434/v1}"
ollama_root="${ollama_url%/v1}"
model="${OLLAMA_MODEL:-gemma4:cloud}"

echo "waiting for ollama"
until curl -fsS "$ollama_root/api/version" >/dev/null; do sleep 2; done
curl -fsS -X POST "$ollama_root/api/pull" \
  -H 'Content-Type: application/json' \
  -d "$(jq -nc --arg model "$model" '{model:$model,stream:false}')" >/dev/null

failed_jobs_json="$(curl -fsS \
  --header "PRIVATE-TOKEN: $REPAIR_GITLAB_TOKEN" \
  "$CI_API_V4_URL/projects/$CI_PROJECT_ID/pipelines/$CI_PIPELINE_ID/jobs?scope[]=failed")"

traces=""
while IFS= read -r job; do
  [ -n "$job" ] || continue
  job_id="$(printf '%s' "$job" | jq -r '.id')"
  job_name="$(printf '%s' "$job" | jq -r '.name')"
  trace="$(curl -fsS --header "PRIVATE-TOKEN: $REPAIR_GITLAB_TOKEN" \
    "$CI_API_V4_URL/projects/$CI_PROJECT_ID/jobs/$job_id/trace" || true)"
  traces+=$'\n## Job: '
  traces+="$job_name"
  traces+=$' ('
  traces+="$job_id"
  traces+=$')\n\n'
  traces+="$(printf '%s' "$trace" | head -c 20000)"
  traces+=$'\n'
done < <(printf '%s' "$failed_jobs_json" | jq -c '.[]')

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
payload="$(jq -nc --arg model "$model" --arg prompt "$prompt" '{model:$model,messages:[{role:"system",content:"Return JSON only."},{role:"user",content:$prompt}],temperature:0}')"
response="$(curl -fsS "$ollama_url/chat/completions" -H 'Content-Type: application/json' -d "$payload")"
content="$(printf '%s' "$response" | jq -r '.choices[0].message.content')"
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
printf '%s\n' "$response" > repair/response.json
printf '%s\n' "$patch" > repair/repair.patch
[ -n "$comment" ] && printf '%s\n' "$comment" > repair/comment.md

note="🤖 Repair attempt: ${summary:-applied a patch and re-tested successfully.}\n\nConfidence: ${confidence}\n\nPatch stored in job artifacts: \\`repair/repair.patch\\`"

if [ -n "$patch" ]; then
  printf '%s\n' "$patch" | git apply --check --whitespace=nowarn
  printf '%s\n' "$patch" | git apply --whitespace=nowarn
  if nix flake check --print-build-logs 2>&1 | tee repair/retest.log; then
    :
  else
    note="🤖 Repair attempt produced a patch but the retest still failed.\n\nSummary: ${summary:-n/a}\nConfidence: ${confidence}\n\nPatch artifact: \\`repair/repair.patch\\`\nRetest log: \\`repair/retest.log\\`"
  fi
else
  note="🤖 Repair attempt produced no patch.\n\nSummary: ${summary:-n/a}\nConfidence: ${confidence}\n\nPatch artifact: \\`repair/repair.patch\\`"
fi

curl -fsS --request POST \
  --header "PRIVATE-TOKEN: $REPAIR_GITLAB_TOKEN" \
  --header 'Content-Type: application/json' \
  --data "$(jq -nc --arg body "$note" '{body:$body}')" \
  "$CI_API_V4_URL/projects/$CI_PROJECT_ID/merge_requests/$CI_MERGE_REQUEST_IID/notes" >/dev/null
