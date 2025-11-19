{delib, ...}:
delib.module {
  name = "roles-social";

  options.roles.social = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, pkgs, ...}:
  with lib;
  let
    cfg = config.roles.social;
  in
  mkIf cfg.enable {
    xdg.configFile."BetterDiscord/data/stable/custom.css" = {
      source = ./custom.css;
    };

    programs = {
      discord = {
        enable = true;
        package = pkgs.goofcord;
      };
    };

    home.packages = with pkgs; [
      shotwell
    ];
  };
}
