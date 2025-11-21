# Zellij Terminal Multiplexer Configuration
#
# This module provides Zellij configuration with:
# - Custom status bar with zjstatus plugin
# - Multiple layouts (default, dev) for different workflows
# - Session management with sesh script
# - Zoxide integration for quick directory switching
# - Tmate integration for remote pair programming
#
# The module has been split into focused files for better maintainability:
# - sesh.nix: Session management script with zoxide and layout selection
# - statusbar.nix: Styled status bar template using zjstatus plugin
# - layouts.nix: Layout definitions (default and dev layouts)

{
  pkgs,
  lib,
  config,
  mkOpt ? null,
  mkBoolOpt ? null,
  enabled ? null,
  disabled ? null,
  ...
}:
with lib;

let
  cfg = config.cli.multiplexers.zellij;

  # Import the sub-modules
  sesh = import ./sesh.nix { inherit pkgs; };
  statusbar = import ./statusbar.nix { inherit config pkgs; };
  layouts = import ./layouts.nix { inherit statusbar; };
in
{
  options.cli.multiplexers.zellij = with types; {
    enable = mkBoolOpt false "enable zellij multiplexer";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.tmate
      sesh
    ];

    xdg.configFile."zellij/config.kdl".source = ./config.kdl;
    xdg.configFile."zellij/layouts/dev.kdl".text = layouts.dev;
    xdg.configFile."zellij/layouts/default.kdl".text = layouts.default;

    programs.zellij = {
      enable = true;
    };
  };
}
