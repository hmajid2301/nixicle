{delib, ...}:
delib.module {
  name = "cli-tools-database";

  options.cli.tools.db = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, pkgs, ...}:
  with lib;
  with lib.nixicle;
  let
    cfg = config.cli.tools.db;
  in
  mkIf cfg.enable {
    home.packages = with pkgs; [
      dbeaver-bin
      termdbms
    ];
  };
}
