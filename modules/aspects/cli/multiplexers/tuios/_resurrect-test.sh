#!/usr/bin/env bash
set -euo pipefail

if [[ ${1:-} != --isolated ]]; then
  root=$(mktemp -d /tmp/tuios-resurrect-test.XXXXXX)
  echo "Test state: $root"
  mkdir -p "$root"/{home,config,state,data,run}
  chmod 700 "$root/run"
  exec env -i PATH="$PATH" HOME="$root/home" XDG_CONFIG_HOME="$root/config" \
    XDG_STATE_HOME="$root/state" XDG_DATA_HOME="$root/data" XDG_RUNTIME_DIR="$root/run" \
    SHELL="${TUIOS_TEST_SHELL:-$(command -v bash)}" TERM=xterm-256color \
    bash "$0" --isolated "$@"
fi
shift
plugin=$1
tuios=${2:-tuios}
trap '"$tuios" kill-server >/dev/null 2>&1 || true' EXIT
printf 'export PATH=%q\n' "$PATH" > "$HOME/.bashrc"
printf 'source "$HOME/.bashrc"\n' > "$HOME/.bash_profile"
mkdir -p "$XDG_CONFIG_HOME/fish"
IFS=: read -r -a paths <<< "$PATH"
{
  printf 'set -gx PATH'
  printf ' %q' "${paths[@]}"
  printf '\n'
} > "$XDG_CONFIG_HOME/fish/config.fish"

mkdir -p "$XDG_CONFIG_HOME/tuios/plugin-config/ntindle.herdr-resurrect" "$HOME/project with spaces"
cat > "$XDG_CONFIG_HOME/tuios/config.toml" <<EOF
[plugins]
dirs = ["$plugin"]
enabled = ["ntindle.herdr-resurrect"]
[agents.permissions]
mode = "strict"
grants = ["read", "write", "fan"]
[appearance]
preferred_shell = "$SHELL"
EOF
printf '%s\n' '{"autoRestore":true,"agentResume":false,"autoRestoreSettleMs":1000}' \
  > "$XDG_CONFIG_HOME/tuios/plugin-config/ntindle.herdr-resurrect/settings.json"
printf '*\n' > "$XDG_CONFIG_HOME/tuios/plugin-config/ntindle.herdr-resurrect/allowlist.txt"
printf '%s\n' '{"scripts":{"dev":"node -e \"setInterval(() => {}, 1000)\""}}' > "$HOME/project with spaces/package.json"

"$tuios" new restore-test --detach --cwd "$HOME/project with spaces"
"$tuios" plugins approve ntindle.herdr-resurrect --grant admin --yes
"$tuios" send-text -s restore-test $'sleep 600\n'
for spec in 'editor:nvim --clean -u NONE "file with spaces.txt"' 'monitor:htop' 'server:npm run dev'; do
  name=${spec%%:*}
  "$tuios" new-window -s restore-test "$name" >/dev/null
  "$tuios" send-text -s restore-test -w "$name" "${spec#*:}"$'\n'
done

wait_for_commands() {
  for _ in {1..60}; do
    "$tuios" list-windows -s restore-test --json > "$XDG_STATE_HOME/windows.json"
    if jq -e '[.windows[] | select(.foreground_cmd != null)] | length == 4' "$XDG_STATE_HOME/windows.json" >/dev/null; then
      return 0
    fi
    sleep 1
  done
  "$tuios" plugins log ntindle.herdr-resurrect
  for name in editor monitor server; do
    "$tuios" capture-pane -s restore-test -w "$name" --lines 15
  done
  return 1
}
wait_for_commands

for _ in {1..45}; do
  snapshot=$(find "$XDG_STATE_HOME/tuios/plugins" -name last.json -print -quit)
  if [[ -n $snapshot ]] && jq -e '[.workspaces[].tabs[].panes[] | select(.command.restorable)] | length == 4' "$snapshot" >/dev/null; then
    break
  fi
  sleep 1
done
jq -e '[.workspaces[].tabs[].panes[] | select(.command.restorable)] | length == 4' "$snapshot" >/dev/null
cp "$snapshot" "$XDG_STATE_HOME/before.json"
jq -e '
  [.workspaces[].tabs[].panes[]] as $panes
  | any($panes[]; .label == "editor" and (.command.argv | index("file with spaces.txt")) != null)
    and any($panes[]; .label == "server" and .command.argv == ["npm", "run", "dev"])
' "$snapshot" >/dev/null
"$tuios" kill-server
"$tuios" start-server
wait_for_commands
"$tuios" plugins log ntindle.herdr-resurrect
jq -e --arg cwd "$HOME/project with spaces" '.total == 4 and all(.windows[]; .cwd == $cwd)' "$XDG_STATE_HOME/windows.json" >/dev/null
"$tuios" plugins run ntindle.herdr-resurrect restore
sleep 3
"$tuios" list-windows -s restore-test --json | jq -e '.total == 4' >/dev/null
"$tuios" plugins log ntindle.herdr-resurrect
printf 'PASS: periodic capture, restart restore, working directories with spaces, and busy-pane skipping\n'
