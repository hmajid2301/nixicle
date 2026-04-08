{ den, inputs, ... }:
{
  flake-file.inputs.nix-index-database.url = "github:nix-community/nix-index-database";
  den.aspects.development = {
    includes = [ den.aspects.neovim den.aspects.ai den.aspects.zellij den.aspects.git den.aspects.gpg den.aspects.ssh den.aspects.attic ];
    homeManager =
      { pkgs, lib, config, ... }:
      let
        atuin-export-fish = pkgs.buildGoModule rec {
          pname = "atuin-export-fish-history";
          version = "0.1.0";
          src = pkgs.fetchFromGitLab {
            owner = "hmajid2301";
            repo = pname;
            rev = "v${version}";
            sha256 = "sha256-2egZYLnaekcYm2IzPdWAluAZogdi4Nf/oXWLw8+AnMk=";
          };
          vendorHash = "sha256-hLEmRq7Iw0hHEAla0Ehwk1EfmpBv6ddBuYtq12XdhVc=";
          ldflags = [ "-s" "-w" ];
        };

        open-in-terminal = pkgs.writeShellScriptBin "open-in-terminal" ''
          #!/usr/bin/env bash
          FILE="''${1:-}"
          LINE="''${2:-1}"
          COL="''${3:-1}"
          if [ -z "$FILE" ]; then echo "Usage: open-in-terminal <file> [line] [column]"; exit 1; fi
          if [ ! -f "$FILE" ]; then echo "Error: File does not exist: $FILE"; exit 1; fi
          ${pkgs.ghostty}/bin/ghostty -e ${pkgs.neovim}/bin/nvim "+call cursor($LINE,$COL)" "$FILE" &
          disown
        '';
      in
      {
        imports = [ inputs.nix-index-database.homeModules.nix-index ];
        xdg.desktopEntries = lib.optionalAttrs pkgs.stdenv.isLinux {
          neovim = {
            name = "Neovim";
            genericName = "editor";
            exec = "nvim -f %F";
            mimeType = [
              "text/html" "text/xml" "text/plain" "text/english" "text/x-makefile"
              "text/x-c++hdr" "text/x-tex" "application/x-shellscript"
            ];
            terminal = false;
            type = "Application";
          };
        };


        # Atuin — shell history sync
        programs.atuin = {
          enable = true;
          flags = [ "--disable-up-arrow" "--disable-ctrl-r" ];
          settings = {
            sync_address = "https://atuin.haseebmajid.dev";
            sync_frequency = "15m";
            dialect = "uk";
            enter_accept = false;
            records = true;
            search_mode = "skim";
          };
        };

        # Simple program enables
        programs = {
          bat.enable = true;
          bottom.enable = true;
          direnv = { enable = true; nix-direnv.enable = true; };
          eza.enable = true;
          fzf = {
            enable = true;
            enableFishIntegration = false;
            colors = with config.lib.stylix.colors.withHashtag; lib.mkForce {
              "bg" = base00; "bg+" = base02; "fg" = base05; "fg+" = base05;
              "header" = base0E; "hl" = base08; "hl+" = base08; "info" = base0A;
              "marker" = base06; "pointer" = base06; "prompt" = base0E; "spinner" = base06;
            };
          };
          htop = {
            enable = true;
            settings = {
              hide_userland_threads = 1;
              highlight_base_name = 1;
              show_cpu_temperature = 1;
              show_program_path = 0;
            };
          };
          nix-index = { enable = true; enableBashIntegration = true; };
          nix-index-database.comma.enable = true;
          starship = { enable = true; enableFishIntegration = true; settings = { }; };
          yazi = { enable = true; enableFishIntegration = true; shellWrapperName = "y"; };
          zoxide = { enable = true; enableFishIntegration = true; };
        };

        home.packages = [ atuin-export-fish ] ++ (with pkgs; [
          # Database tools
          dbeaver-bin
          termdbms

          # Network tools
          tshark
          termshark
          kubeshark

          # TUI tools
          gh-dash
          gum

          # Core tools (modern unix)
          open-in-terminal
          broot erdtree fd xcp entr
          choose ripgrep silver-searcher sd grex yq-go
          duf dust dysk gdu procs gping viddy
          hexyl delta chafa ouch jqp jnv
          curlie doggo
          hyperfine tokei
          gomi tailspin
          sshx glow
          (lib.hiPrio parallel) moreutils unzip gnupg
          optinix

          # Development tools
          go goose golangci-lint air templ sqlc golines gotools
          go-task go-mockery gotestsum delve
          nodejs_24 bun pnpm
          gnumake

          # Homelab tools
          pgcli openbao kind kaf

          # Container tools
          arion docker docker-compose dive amazon-ecr-credential-helper

          # Yazi media preview tools
          imagemagick ffmpegthumbnailer fontpreview unar poppler
        ]);
      };
  };
}
