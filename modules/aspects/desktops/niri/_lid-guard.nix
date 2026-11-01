{
  pkgs,
  lib,
  lockSuspendArgs,
  ...
}:
pkgs.writeShellScript "desktop-shell-lid-guard" ''
  for f in /sys/class/power_supply/A*/online; do
    [ -r "$f" ] || continue
    read -r ac < "$f"
    [ "$ac" = "1" ] && exit 0
  done

  external=$(${pkgs.niri}/bin/niri msg --json outputs | ${pkgs.jq}/bin/jq '[.[] | select(.name != "eDP-1" and .current_mode != null)] | length')
  [ "$external" -gt 0 ] && exit 0

  exec ${lib.escapeShellArgs lockSuspendArgs}
''
