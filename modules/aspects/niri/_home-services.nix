{ pkgs, lib, ... }:
{
  services.wlsunset = {
    enable = true;
    latitude = "51.5072";
    longitude = "-0.1275";
    temperature = {
      day = 6500;
      night = 4000;
    };
  };

  systemd.user.services.wlsunset = {
    Unit = {
      BindsTo = [ "niri.service" ];
      After = [ "niri.service" ];
      PartOf = lib.mkForce [ "niri.service" ];
    };
    Install.WantedBy = lib.mkForce [ ];
  };

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
