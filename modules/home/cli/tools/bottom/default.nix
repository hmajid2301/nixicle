{delib, ...}:
delib.module {
  name = "cli-tools-bottom";

  options.cli.tools.bottom = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, ...}:
  with lib;
  with lib.nixicle;
  let
    cfg = config.cli.tools.bottom;
  in
  mkIf cfg.enable {
    programs.bottom = {
      enable = true;
    };
  };
}
