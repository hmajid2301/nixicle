{delib, ...}:
delib.module {
  name = "cli-tools-modern-unix";

  options.cli.tools.modern-unix = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, pkgs, ...}:
  with lib;
  with lib.nixicle;
  let
    cfg = config.cli.tools.modern-unix;
  in
  mkIf cfg.enable {
    cli.tools = {
      core-tools.enable = true;
      development.enable = true;
      ai-tools.enable = true;
      homelab.enable = true;
      tui.enable = true;
    };
  };
}
