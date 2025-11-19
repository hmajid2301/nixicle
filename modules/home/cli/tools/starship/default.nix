{delib, ...}:
delib.module {
  name = "cli-tools-starship";

  options.cli.tools.starship = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, pkgs, ...}:
  with lib;
  with lib.nixicle;
  let
    cfg = config.cli.tools.starship;
  in
  mkIf cfg.enable {
    programs.starship = {
      enable = true;
      enableFishIntegration = true;
      settings = { };
    };
  };
}
