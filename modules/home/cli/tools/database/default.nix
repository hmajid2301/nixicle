{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.cli.tools.db;
in {
  options.cli.tools.db = with types; {
    enable = mkBoolOpt false "Whether or not to manage db";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      dbeaver-bin
      termdbms
    ];
  };
}
