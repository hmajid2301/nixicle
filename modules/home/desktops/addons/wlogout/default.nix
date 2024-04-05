{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.desktops.addons.wlogout;
in {
  options.desktops.addons.wlogout = {
    enable = mkEnableOption "Enable wlogout screen for managing sessions.";
  };

  config = mkIf cfg.enable {
    programs.wlogout = {
      enable = true;
      layout = [
        {
          label = "lock";
          action = "${pkgs.hyprlock}/bin/hyprlock";
          text = "Lock";
          keybind = "l";
        }
        {
          label = "hibernate";
          action = "${pkgs.systemd}/bin/systemctl hibernate";
          text = "Hibernate";
          keybind = "h";
        }
        {
          label = "logout";
          action = "${pkgs.systemd}/bin/loginctl terminate-user $USER";
          text = "Logout";
          keybind = "L";
        }
        {
          label = "shutdown";
          action = "${pkgs.systemd}/bin/systemctl poweroff";
          text = "Shutdown";
          keybind = "S";
        }
        {
          label = "suspend";
          action = "${pkgs.systemd}/bin/systemctl suspend-then-hibernate";
          text = "Suspend";
          keybind = "s";
        }
        {
          label = "reboot";
          action = "${pkgs.systemd}/bin/systemctl reboot";
          text = "Reboot";
          keybind = "r";
        }
      ];
      style = builtins.readFile ./style.css;
    };

    xdg.configFile."wlogout/icons" = {
      recursive = true;
      source = ./icons;
    };
  };
}
