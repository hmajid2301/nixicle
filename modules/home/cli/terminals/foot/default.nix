{delib, ...}:
delib.module {
  name = "cli-terminals-foot";

  options.cli.terminals.foot = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, ...}:
  with lib;
  with lib.nixicle;
  let
    cfg = config.cli.terminals.foot;
  in
  mkIf cfg.enable {
    programs.foot = {
      enable = true;

      settings = {
        main = {
          shell = "fish";
          pad = "15x15";
          selection-target = "clipboard";
        };

        scrollback = {
          lines = 10000;
        };
      };
    };
  };
}
