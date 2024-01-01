{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.terminals.wezterm;
in {
  options.modules.terminals.wezterm = {
    enable = mkEnableOption "enable wezterm terminal emulator";
  };

  config = mkIf cfg.enable {
    programs.wezterm = {
      enable = true;
      package = pkgs.wezterm-nightly;
      extraConfig = builtins.readFile ./config.lua;
    };
  };
}
