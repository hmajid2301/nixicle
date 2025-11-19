{delib, ...}:
delib.module {
  name = "cli-terminals-wezterm";

  options.cli.terminals.wezterm = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, ...}:
  with lib;
  let
    cfg = config.cli.terminals.wezterm;
  in
  mkIf cfg.enable {
    programs.wezterm = {
      enable = true;
      extraConfig = builtins.readFile ./config.lua;
    };
  };
}
