{ pkgs, ... }:
{
  systemd.user.services.niri-env-setup = {
    Unit = {
      Description = "Import NIRI_SOCKET into systemd user environment";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
      ConditionEnvironment = "XDG_CURRENT_DESKTOP=niri";
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.writeShellScript "niri-env-setup" ''
        sleep 2
        NIRI_SOCKET=$(ls /run/user/$(id -u)/niri.sock* 2>/dev/null | head -1)
        if [ -n "$NIRI_SOCKET" ]; then
          ${pkgs.systemd}/bin/systemctl --user set-environment NIRI_SOCKET="$NIRI_SOCKET"
          echo "Set NIRI_SOCKET=$NIRI_SOCKET"
        else
          echo "Warning: NIRI_SOCKET not found, retrying..."
          sleep 3
          NIRI_SOCKET=$(ls /run/user/$(id -u)/niri.sock* 2>/dev/null | head -1)
          if [ -n "$NIRI_SOCKET" ]; then
            ${pkgs.systemd}/bin/systemctl --user set-environment NIRI_SOCKET="$NIRI_SOCKET"
            echo "Set NIRI_SOCKET=$NIRI_SOCKET"
          fi
        fi
      ''}";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
