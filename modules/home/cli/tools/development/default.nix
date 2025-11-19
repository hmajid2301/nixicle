{delib, ...}:
delib.module {
  name = "cli-tools-development";

  options.cli.tools.development = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, pkgs, ...}:
  with lib;
  with lib.nixicle;
  let
    cfg = config.cli.tools.development;
  in
  mkIf cfg.enable {
    home.packages = with pkgs; [
      # Go development
      go
      goose
      golangci-lint
      air
      templ
      sqlc
      golines
      gotools
      go-task
      go-mockery
      gotestsum
      delve
      # prism  # Go dependency visualization tool - uncomment when confirmed available in nixpkgs

      # Node.js development
      nodejs_24
      bun
      pnpm

      # General development
      gnumake
    ];
  };
}
