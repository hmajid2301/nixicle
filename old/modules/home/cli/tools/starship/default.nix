{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle;

let
  cfg = config.cli.tools.starship;
in
{
  options.cli.tools.starship = with types; {
    enable = mkBoolOpt false "Whether or not to enable starship";
  };

  config = mkIf cfg.enable {
    programs.starship = {
      enable = true;
      enableFishIntegration = true;
      settings = { };
    };
  };
}
