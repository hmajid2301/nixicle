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
          local act = wezterm.action
          return {
          	color_scheme = "Catppuccin Mocha",
          	default_prog = { "${config.my.settings.default.shell}" },
          	font = wezterm.font "${config.my.settings.fonts.monospace}",
          	font_size = 14.0,
          	enable_tab_bar = false,
          }
        '';
    };
  };
}
