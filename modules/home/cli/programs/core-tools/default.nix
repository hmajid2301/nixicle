{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.cli.programs.core-tools;
in
{
  options.cli.programs.core-tools = with types; {
    enable = mkBoolOpt false "Whether or not to enable modern unix core tools";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # File management and navigation
      broot
      erdtree
      fd
      xcp
      entr

      # Text processing and search
      choose
      ripgrep
      silver-searcher
      sd
      grex
      yq-go

      # System monitoring and utilities
      duf
      dust
      dysk
      gdu
      procs
      gping
      viddy

      # Data and file manipulation
      hexyl
      delta
      chafa
      ouch
      jqp
      jnv

      # Network and API tools
      curlie
      doggo

      # Performance and benchmarking
      hyperfine
      tokei

      # Cleanup and maintenance
      gomi
      tailspin

      # SSH and remote access
      sshx

      # Markdown viewer
      glow
    ];
  };
}

