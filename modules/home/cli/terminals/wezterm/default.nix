{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.cli.terminals.wezterm;
in {
  options.cli.terminals.wezterm = {
    enable = mkEnableOption "enable wezterm terminal emulator";
  };

  config = mkIf cfg.enable {
    programs.wezterm = {
      enable = true;
      extraConfig = builtins.readFile ./config.lua;
    };
  };
}
