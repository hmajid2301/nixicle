{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.programs.discord;
in {
  options.programs.discord = with types; {
    enable = mkBoolOpt false "Whether or not to manage discord";
  };

  config = mkIf cfg.enable {
    xdg.configFile."BetterDiscord/data/stable/custom.css" = {source = ./custom.css;};
    home.packages = with pkgs; [goofcord];
  };
}
