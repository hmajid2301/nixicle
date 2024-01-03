{pkgs, ...}: {
  programs.wlogout = {
    enable = true;
    layout = [
      {
        label = "lock";
        action = "${pkgs.swaylock-effects}/bin/swaylock --screenshots --clock --indicator --effect-pixelate 4 --effect-blur 4x4";
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
}
