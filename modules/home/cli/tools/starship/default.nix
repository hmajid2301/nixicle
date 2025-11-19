{
  config,
  lib,
  pkgs,
mkOpt ? null,
mkBoolOpt ? null,
enabled ? null,
disabled ? null,
  ...
}:
with lib;

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
