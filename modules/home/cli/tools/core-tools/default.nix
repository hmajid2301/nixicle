{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle;

let
  cfg = config.cli.tools.core-tools;

  # Script to open current file in a new Ghostty terminal
  open-in-terminal = pkgs.writeShellScriptBin "open-in-terminal" ''
    #!/usr/bin/env bash

    # Open current file in a new Ghostty terminal with Neovim
    # Usage: open-in-terminal.sh <file> [line] [column]

    FILE="''${1:-}"
    LINE="''${2:-1}"
    COL="''${3:-1}"

    if [ -z "$FILE" ]; then
        echo "Usage: open-in-terminal <file> [line] [column]"
        echo "Example: open-in-terminal /path/to/file.md 10 5"
        exit 1
    fi

    if [ ! -f "$FILE" ]; then
        echo "Error: File does not exist: $FILE"
        exit 1
    fi

    # Open in Ghostty with Neovim at the specified position
    ${pkgs.ghostty}/bin/ghostty -e ${pkgs.neovim}/bin/nvim "+call cursor($LINE,$COL)" "$FILE" &
    disown

    echo "Opened $FILE in new Ghostty terminal at line $LINE, column $COL"
  '';
in
{
  options.cli.tools.core-tools = with types; {
    enable = mkBoolOpt false "Whether or not to enable modern unix core tools";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Custom scripts
      open-in-terminal
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

      # Core Unix utilities
      (lib.hiPrio parallel) # GNU parallel - prioritize over moreutils version
      moreutils # Additional Unix utilities (sponge, vidir, etc)
      unzip # Archive extraction
      gnupg # GPG encryption and signing

      # Nix utilities
      optinix # Nix flake utilities
    ];
  };
}
