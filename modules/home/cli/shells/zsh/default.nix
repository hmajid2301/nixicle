{delib, ...}:
delib.module {
  name = "cli-shells-zsh";

  options.cli.shells.zsh = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, pkgs, host, ...}:
  with lib;
  with lib.nixicle;
  let
    cfg = config.cli.shells.zsh;
  in
  mkIf cfg.enable {
    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
    };
  };
}
