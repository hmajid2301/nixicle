{ config, lib, ... }:

with lib;
let
  cfg = config.modules.terminals.wezterm;
in
{
  options.modules.terminals.wezterm = {
    enable = mkEnableOption "enable wezterm terminal emulator";
  };

  config = mkIf cfg.enable {
    programs.wezterm = {
      enable = true;
      colorSchemes = { };
      extraConfig =
        # lua
        ''
          local wezterm = require 'wezterm'
          return {
          	color_scheme = "Catppuccin Mocha",
          	font = wezterm.font  ${config.fontProfiles.monospace.family},
          	font_size = 14.0,
          	enable_tab_bar = false,
          }
        '';
    };
  };
}
