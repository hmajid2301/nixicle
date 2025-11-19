{delib, ...}:
delib.module {
  name = "cli-tools-eza";

  options.cli.tools.eza = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, pkgs, ...}:
  with lib;
  with lib.nixicle;
  let
    cfg = config.cli.tools.eza;
  in
  mkIf cfg.enable {
    programs.eza = {
      enable = true;
    };
  };
}
