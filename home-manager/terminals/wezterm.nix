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
          return {
          	color_scheme = "Catppuccin Mocha",
          }
        '';
    };
  };
}
