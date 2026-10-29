set -euo pipefail

directory=$1
backup=$2
started=$3
[[ "$backup" =~ ^[a-zA-Z0-9_-]+$ ]]
[[ "$started" =~ ^[0-9]+$ ]]
now=$(date +%s)
(( started <= now ))
umask 022
temporary=$(mktemp "$directory/.restic-$backup.XXXXXX")
trap 'rm -f "$temporary"' EXIT
printf 'restic_backup_last_success_timestamp_seconds{backup="%s"} %s\n' "$backup" "$now" > "$temporary"
printf 'restic_backup_duration_seconds{backup="%s"} %s\n' "$backup" "$((now - started))" >> "$temporary"
chmod 0644 "$temporary"
mv -f "$temporary" "$directory/restic-$backup.prom"
