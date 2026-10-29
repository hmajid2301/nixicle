{ den, inputs, ... }:
{
  flake-file.inputs.nix-index-database.url = "github:nix-community/nix-index-database";
  flake-file.inputs.glci = {
    url = "git+https://gitlab.com/gitlab-org/ci-cd/runner-tools/glci.git";
    flake = false;
  };

  den.aspects.kubernetesCli = {
    homeManager =
      { pkgs, ... }:
      {
        programs.k9s.enable = true;

        home.packages = with pkgs; [
          kubectl
          kubectx
          kubelogin
          kubelogin-oidc
          stern
          kubernetes-helm
          kustomize
          fluxcd
          kubefwd
        ];
      };
  };

  den.aspects.development = {
    includes = [
      den.aspects.neovim
      den.aspects.pi-coding-agent
      den.aspects.skills
      den.aspects.zellij
      den.aspects.tuios
      den.aspects.herdr-cli
      den.aspects.histerClient
      den.aspects.worktrunk
      den.aspects.git
      den.aspects.gpg
      den.aspects.ssh
      den.aspects.attic-client
      den.aspects.devGo
      den.aspects.devJs
      den.aspects.devContainers
      den.aspects.devDb
      den.aspects.devHomelab
      den.aspects.devTools
    ];

    homeManager =
      {
        pkgs,
        lib,
        config,
        ...
      }:
      let
        secretsFileText = builtins.readFile ../../../secrets.yaml;
        hasSecret = name: lib.hasInfix "${name}:" secretsFileText;

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

        config = lib.mkMerge [
          {
            xdg.desktopEntries = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
              neovim = {
                name = "Neovim";
                genericName = "editor";
                exec = "nvim -f %F";
                mimeType = [
                  "text/html"
                  "text/xml"
                  "text/plain"
                  "text/english"
                  "text/x-makefile"
                  "text/x-c++hdr"
                  "text/x-tex"
                  "application/x-shellscript"
                ];
                terminal = false;
                type = "Application";
              };
            };

            programs.atuin = {
              enable = true;
              flags = [
                "--disable-up-arrow"
                "--disable-ctrl-r"
              ];
              settings = {
                sync_address = "https://atuin.${lib.nixicle.domains.root}";
                sync_frequency = "15m";
                dialect = "uk";
                enter_accept = false;
                records = true;
                search_mode = "skim";
              };
            };

            programs = {
              bat.enable = true;
              bottom.enable = true;
              direnv = {
                enable = true;
                nix-direnv.enable = true;
              };
              eza.enable = true;
              fzf = {
                enable = true;
                enableFishIntegration = false;
                colors =
                  with config.lib.stylix.colors.withHashtag;
                  lib.mkForce {
                    bg = base00;
                    "bg+" = base02;
                    fg = base05;
                    "fg+" = base05;
                    header = base0E;
                    hl = base08;
                    "hl+" = base08;
                    info = base0A;
                    marker = base06;
                    pointer = base06;
                    prompt = base0E;
                    spinner = base06;
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
              nix-index = {
                enable = true;
                enableBashIntegration = true;
              };
              nix-index-database.comma.enable = true;
              starship = {
                enable = true;
                enableFishIntegration = true;
                settings = { };
              };
              yazi = {
                enable = true;
                enableFishIntegration = true;
                shellWrapperName = "y";
              };
              superfile.enable = true;
              zoxide = {
                enable = true;
                enableFishIntegration = true;
              };
            };

            home.packages = [ open-in-terminal ];
          }
          (lib.mkIf (hasSecret "ketch_context7_api_key") {
            nixicle.ketch.secrets.context7ApiKey = "ketch_context7_api_key";
          })
          (lib.mkIf (hasSecret "ketch_github_token") {
            nixicle.ketch.secrets.githubToken = "ketch_github_token";
          })
          (lib.mkIf (hasSecret "ketch_brave_api_key") {
            nixicle.ketch.secrets.braveApiKey = "ketch_brave_api_key";
          })
        ];
      };
  };
}
