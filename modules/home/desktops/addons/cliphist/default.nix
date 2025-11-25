{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.desktops.addons.cliphist;
in
{
  options.desktops.addons.cliphist = with types; {
    enable = mkBoolOpt false "Enable cliphist clipboard history manager";
    maxItems = mkOption {
      type = int;
      default = 1000;
      description = "Maximum number of items to store in clipboard history";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      cliphist
      wl-clipboard
    ];

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

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    home.sessionVariables = mkIf (cfg.maxItems != 1000) {
      CLIPHIST_MAX_ITEMS = toString cfg.maxItems;
    };
  };
}
