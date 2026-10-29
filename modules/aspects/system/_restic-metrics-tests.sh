set -euo pipefail

script="$(dirname "${BASH_SOURCE[0]}")/restic-metrics.sh"
directory=$(mktemp -d)
trap 'rm -rf "$directory"' EXIT
started=$(( $(date +%s) - 2 ))
bash "$script" "$directory" home "$started"
metric="$directory/restic-home.prom"
grep -Eq '^restic_backup_last_success_timestamp_seconds\{backup="home"\} [0-9]+$' "$metric"
grep -Eq '^restic_backup_duration_seconds\{backup="home"\} [0-9]+$' "$metric"
[[ $(stat -c %a "$metric") == 644 ]]
[[ $(wc -l < "$metric") == 2 ]]
cp "$metric" "$directory/original"
if bash "$script" "$directory" '../unsafe' "$started"; then
  exit 1
fi
if bash "$script" "$directory" home invalid; then
  exit 1
fi
if bash "$script" "$directory" home "$(( $(date +%s) + 3600 ))"; then
  exit 1
fi
cmp "$metric" "$directory/original"
[[ -z $(find "$directory" -name '.restic-*' -print -quit) ]]
printf 'Restic metrics tests passed\n'
