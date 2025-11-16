{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.cli.tools.tui;
in
{
  options.cli.tools.tui = with types; {
    enable = mkBoolOpt false "Whether or not to enable terminal UI applications";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # GitHub TUI
      gh-dash

      # Interactive prompts and UI
      gum

      # REST API client (modern rest api tool for terminal)
      # posting  # Enable once available in nixpkgs - modern REST API client
    ];
  };
}