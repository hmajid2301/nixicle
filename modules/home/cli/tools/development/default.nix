{
  pkgs,
  config,
  lib,
mkOpt ? null,
mkBoolOpt ? null,
enabled ? null,
disabled ? null,
  ...
}:
with lib;

let
  cfg = config.cli.tools.development;
in
{
  options.cli.tools.development = with types; {
    enable = mkBoolOpt false "Whether or not to enable development tools";
  };

  config = mkIf cfg.enable {
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