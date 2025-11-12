{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.roles.social;
in
{
  options.roles.social = {
    enable = mkEnableOption "Enable social suite";
  };

  config = mkIf cfg.enable {
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
