{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.cli.tools.direnv;
in
{
  options.cli.tools.direnv = with types; {
    enable = mkBoolOpt false "Whether or not to enable direnv";
  };

  config = mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
