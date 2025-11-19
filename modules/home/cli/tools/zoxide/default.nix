{delib, ...}:
delib.module {
  name = "cli-tools-zoxide";

  options.cli.tools.zoxide = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, pkgs, ...}:
  with lib;
  with lib.nixicle;
  let
    cfg = config.cli.tools.zoxide;
  in
  mkIf cfg.enable {
    programs.zoxide = {
      enable = true;
      enableFishIntegration = true;
    };
  };
}
