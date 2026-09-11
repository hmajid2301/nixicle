#!/bin/sh
# Action entrypoint: open the picker pane declared in herdr-plugin.toml.
set -u
BIN="${HERDR_BIN_PATH:-herdr}"
exec "$BIN" plugin pane open \
  --plugin "${HERDR_PLUGIN_ID:-agent-session-sync}" \
  --entrypoint picker
