#!/usr/bin/env bash
set -euo pipefail

github_json() {
  local headers=(-H 'Accept: application/vnd.github+json' -H 'User-Agent: nixicle-ci-repair')
  local token="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
  if [ -n "$token" ]; then headers+=(-H "Authorization: Bearer $token"); fi
  curl -fsS --max-time 30 "${headers[@]}" "https://api.github.com/repos/NixOS/nixpkgs/$1"
}

collect_candidates() {
  local file candidate input pr locked merge rev status expression
  while IFS= read -r -d '' file; do
    [ ! -L "$file" ] || continue
    while IFS= read -r candidate; do
      input="$(jq -r '.input' <<< "$candidate")"
      pr="$(jq -r '.pr' <<< "$candidate")"
      locked="$(jq -ce --arg input "$input" '
        .nodes[.root].inputs[$input] as $node
        | select($node | type == "string")
        | .nodes[$node].locked
        | select(.type == "github" and (.owner | ascii_downcase) == "nixos"
          and (.repo | ascii_downcase) == "nixpkgs")
        | select(.rev | type == "string")
      ' flake.lock)" || continue
      merge="$(github_json "pulls/$pr" | jq -er 'select(.merged == true) | .merge_commit_sha | select(type == "string" and length > 0)')" || continue
      rev="$(jq -r '.rev' <<< "$locked")"
      status="$(github_json "compare/$merge...$rev" | jq -er '.status')" || continue
      case "$status" in ahead|identical) ;; *) continue ;; esac
      expression="$(jq -r --arg root "$PWD" '
        "(builtins.getFlake " + ($root | tojson) + ").inputs."
        + (.input | tojson) + ".legacyPackages.${builtins.currentSystem}." + .package
      ' <<< "$candidate")"
      nix build --no-link --impure --expr "$expression" >&2 || continue
      jq -c --arg merge "$merge" --arg rev "$rev" '
        . + {merge_commit: $merge, locked_revision: $rev}
      ' <<< "$candidate"
      break
    done < <(jq -nc --arg file "$file" --rawfile source "$file" '
      $source | match("(?:^|(?<=\\n))(?<indent>[ \\t]*)# TODO\\(nixpkgs\\): pr=(?<pr>[1-9][0-9]*) input=(?<input>[A-Za-z0-9_-]+) package=(?<package>[A-Za-z0-9_.-]+) target=(?<target>[^\\s]+)\\n\\k<indent># \\k<package>\\n"; "gm")
      | . as $match
      | (.captures | map({key: .name, value: .string}) | from_entries)
      | {file: $file, line: ($source[:$match.offset] | split("\n") | length),
         pr, input, package, target, marker: $match.string,
         replacement: (.indent + .package + "\n"), source: $source}
    ')
  done < <(git ls-files -z '*.nix')
}

check_patch() {
  local stats file count=0
  stats="$(mktemp)"
  if ! git apply --numstat -z < "$2" > "$stats"; then
    rm -f -- "$stats"
    return 1
  fi
  while IFS= read -r -d '' file; do
    file="${file#*$'\t'}"
    file="${file#*$'\t'}"
    if ! jq -e --arg file "$file" 'any(.[]; .file == $file)' "$1" >/dev/null; then
      rm -f -- "$stats"
      return 1
    fi
    count=$((count + 1))
  done < "$stats"
  rm -f -- "$stats"
  [ "$count" -gt 0 ]
}

validate() {
  local file candidate target count=0
  [ -z "$(git diff HEAD --summary)" ] || return 1
  while IFS= read -r -d '' file; do
    candidate="$(jq -ce --arg file "$file" '.[] | select(.file == $file)' "$1")" || return 1
    [ -f "$file" ] && [ ! -L "$file" ] || return 1
    jq -e --rawfile actual "$file" '
      .marker as $marker | (.source | index($marker)) as $offset
      | (.source[:$offset] + .replacement + .source[$offset + (.marker | length):]) == $actual
    ' <<< "$candidate" >/dev/null || return 1
    count=$((count + 1))
  done < <(git diff HEAD --name-only -z)
  [ "$count" -gt 0 ] || return 1
  while IFS= read -r -d '' file; do
    target="$(jq -r --arg file "$file" '.[] | select(.file == $file) | .target' "$1")"
    nix build --no-link ".#$target" >&2 || return 1
  done < <(git diff HEAD --name-only -z)
}

case "${1:-}" in
  collect) collect_candidates | jq -s . ;;
  check-patch) check_patch "$2" "$3" ;;
  validate) validate "$2" ;;
  *) printf 'Expected collect, validate <candidates.json>, or check-patch <candidates.json> <patch>\n' >&2; exit 1 ;;
esac
