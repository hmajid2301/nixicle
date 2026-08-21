{ pkgs, noctalia, ... }:
pkgs.writeShellScript "noctalia-lid-guard" ''
  # Suspend+lock on lid close only when not on AC and no external monitor.

  for f in /sys/class/power_supply/A*/online; do
    [ -r "$f" ] || continue
    read -r ac < "$f"
    [ "$ac" = "1" ] && exit 0
  done

  external=$(${pkgs.niri}/bin/niri msg --json outputs | ${pkgs.jq}/bin/jq '[.[] | select(.connected and .name != "eDP-1")] | length')
  [ "$external" -gt 0 ] && exit 0

  exec ${noctalia}/bin/noctalia msg session lock-and-suspend
''
