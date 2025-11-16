{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.cli.tools.eza;
in {
  options.cli.tools.eza = with types; {
    enable = mkBoolOpt false "Whether or not to enable eza";
  };

  config = mkIf cfg.enable {
    programs.eza = {
      enable = true;
    };
  };
}
