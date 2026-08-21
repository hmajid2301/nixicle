# Noctalia v5 migration handoff

This document captures the v5 migration for the `niri` / Noctalia desktop stack.

## 1. Core migration (breaking)

- Flake inputs moved from `noctalia/legacy-v4` to `noctalia-dev/noctalia`.
- Removed the legacy `noctalia-qs`, `noctalia-plugins` and `pam-shim` inputs.
- Replaced `programs.noctalia-shell` with `programs.noctalia` across all home-manager modules and host idle settings.
- Updated Niri keybinds from `qs`/`noctalia-shell ipc call ...` to the new `noctalia msg ...` protocol.
- Added `focus=false` to workspace-move keybinds to match Niri semantics.
- Removed the manual `wlsunset` service; nightlight is now handled inside Noctalia.
- Disabled `hypridle` on Niri hosts because Noctalia v5 has its own idle service.

## 2. NixOS greeter + lid handling

- Integrated `noctalia-greeter` via the upstream NixOS module.
- Replaced `tuigreet` with `noctalia-greeter-session` in `greetd`.
- Added `greeter` system user/group and moved persistent state to `/var/lib/noctalia-greeter`.
- Configured logind to ignore lid switches so the compositor / Noctalia can decide policy.

## 3. Plugins and lid-guard

- Added `noctalia-community-plugins` and `noctalia-official-plugins` flake inputs.
- Wired the Nix-managed plugin path into `programs.noctalia.plugins.source`.
- Enabled `niri-displays`, `bitwarden`, `phone-connect` and `battery-power-management` plugins.
- Added runtime deps (`bitwarden-cli`, `glib.bin`, `sshfs`, `upower`) needed by the plugins.
- Added the `_lid-guard.nix` helper and used it for NixOS and non-NixOS lid-close hooks.
- Added `battery_ctl` group + udev rule for charge-threshold control.

## 4. Host-specific idle timeouts

- Desktop: 300s lock, 330s screen-off, 1800s suspend.
- Framework: 300s lock, 330s screen-off, 900s suspend.
- Framebox: 300s lock, 330s screen-off, 0s suspend.
- Dell (Ubuntu): 300s lock, 330s screen-off, 900s suspend; removed the old swayidle workaround.
