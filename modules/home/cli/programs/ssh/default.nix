{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.cli.programs.ssh;
in {
  options.cli.programs.ssh = with types; {
    enable = mkBoolOpt false "Whether or not to enable ssh";
  };

  config = mkIf cfg.enable {
    programs.ssh = {
      enable = true;
    };
  };
}
