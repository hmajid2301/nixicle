{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.desktops.addons.swayidle;

  # Detect which compositor and addons are being used
  isNiri = config.desktops.niri.enable or false;
  isHyprland = config.desktops.hyprland.enable or false;
  isNoctalia = config.desktops.addons.noctalia.enable or false;

  # Compositor-specific commands
  dpmsOn = if isHyprland then "${pkgs.hyprland}/bin/hyprctl dispatch dpms on"
           else if isNiri then "niri msg action power-on-monitors"
           else "echo 'No compositor-specific dpms on command'";

  dpmsOff = if isHyprland then "${pkgs.hyprland}/bin/hyprctl dispatch dpms off"
            else if isNiri then "niri msg action power-off-monitors"
            else "echo 'No compositor-specific dpms off command'";

  lockCmd = if isHyprland then "${pkgs.hyprlock}/bin/hyprlock"
            else if (isNiri && isNoctalia) then "${pkgs.quickshell}/bin/qs ipc --newest call lockScreen lock"
            else "${pkgs.systemd}/bin/loginctl lock-session";
in
{
  options.desktops.addons.swayidle = with types; {
    enable = mkBoolOpt false "Whether to enable swayidle (compatible with older Wayland compositors)";
    
    timeouts = mkOption {
      type = types.attrs;
      default = {
        lock = 300;      # Lock after 5 minutes
        dpms = 330;      # Turn off displays after 5.5 minutes
        suspend = 1800;  # Suspend after 30 minutes
      };
      description = "Timeout values in seconds";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.swayidle ];

    systemd.user.services.swayidle = {
      Unit = {
        Description = "Idle manager for Wayland";
        Documentation = "man:swayidle(1)";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = ''
          ${pkgs.swayidle}/bin/swayidle -w \
            timeout ${toString cfg.timeouts.lock} '${lockCmd}' \
            timeout ${toString cfg.timeouts.dpms} '${dpmsOff}' \
              resume '${dpmsOn}' \
            timeout ${toString cfg.timeouts.suspend} '${pkgs.systemd}/bin/systemctl suspend' \
            before-sleep '${pkgs.systemd}/bin/loginctl lock-session'
        '';
        Restart = "on-failure";
        RestartSec = 1;
        Environment = [
          "PATH=${pkgs.lib.makeBinPath [ pkgs.bash pkgs.coreutils pkgs.systemd pkgs.quickshell ]}:/run/current-system/sw/bin:/usr/bin"
          "XDG_CONFIG_HOME=${config.xdg.configHome}"
          "HOME=${config.home.homeDirectory}"
        ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
