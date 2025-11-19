{delib, ...}:
delib.module {
  name = "cli-tools-tui";

  options.cli.tools.tui = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, pkgs, ...}:
  with lib;
  with lib.nixicle;
  let
    cfg = config.cli.tools.tui;
  in
  mkIf cfg.enable {
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
