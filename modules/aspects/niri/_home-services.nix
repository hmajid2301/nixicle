{ pkgs, lib, ... }:
{
  xdg.configFile."wlogout/icons" = {
    recursive = true;
    source = ./wlogout-icons;
  };

  systemd.user.services.cliphist = {
    Unit = {
      Description = "Clipboard history service";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
