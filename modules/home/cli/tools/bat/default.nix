{delib, ...}:
delib.module {
  name = "cli-tools-bat";

  options.cli.tools.bat = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, ...}:
  with lib;
  with lib.nixicle;
  let
    cfg = config.cli.tools.bat;
  in
  mkIf cfg.enable {
    programs.bat = {
      enable = true;
    };
  };
}
