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
      den.aspects.shellPromptHistory
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
        # pactl is absent from PATH on the NixOS desktop hosts (the audio
        # aspect shells out to ${pkgs.pulseaudio} directly); the store copy
        # speaks the Pulse protocol to any Pulse/PipeWire server.
        elgato-fix = pkgs.writeShellScriptBin "elgato-fix" ''
          export PATH="${pkgs.pulseaudio}/bin:$PATH"
          ${builtins.readFile ./scripts/elgato-fix}
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
                    header = base07;
                    hl = base08;
                    "hl+" = base08;
                    info = base0A;
                    marker = base06;
                    pointer = base06;
                    prompt = base07;
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
              yazi = {
                enable = true;
                enableFishIntegration = true;
                shellWrapperName = "y";
                theme =
                  let
                    accent = lib.mkForce config.lib.stylix.colors.withHashtag.base07;
                  in
                  {
                    tabs.active.bg = accent;
                    tabs.inactive.fg = accent;
                    mode.normal_main.bg = accent;
                    mode.normal_alt.fg = accent;
                    pick.border.fg = accent;
                    input.border.fg = accent;
                    completion.border.fg = accent;
                    tasks.border.fg = accent;
                  };
              };
              superfile = {
                enable = true;
                settings.theme = "stylix";
                themes.stylix = with config.lib.stylix.colors.withHashtag; {
                  code_syntax_highlight = "catppuccin-mocha";
                  full_screen_fg = base04;
                  full_screen_bg = base00;
                  gradient_color = [
                    base07
                    base0F
                  ];
                  file_panel_fg = base04;
                  file_panel_bg = base00;
                  file_panel_border = base03;
                  file_panel_border_active = base07;
                  file_panel_top_directory_icon = base0B;
                  file_panel_top_path = base07;
                  file_panel_item_selected_fg = base07;
                  file_panel_item_selected_bg = base00;
                  footer_fg = base04;
                  footer_bg = base00;
                  footer_border = base03;
                  footer_border_active = base07;
                  sidebar_fg = base04;
                  sidebar_bg = base00;
                  sidebar_title = base07;
                  sidebar_border = base00;
                  sidebar_border_active = base07;
                  sidebar_item_selected_fg = base07;
                  sidebar_item_selected_bg = base00;
                  sidebar_divider = base03;
                  modal_fg = base04;
                  modal_bg = base00;
                  modal_border_active = base07;
                  modal_cancel_fg = base01;
                  modal_cancel_bg = "#eba0ac";
                  modal_confirm_fg = base01;
                  modal_confirm_bg = "#89dceb";
                  help_menu_hotkey = "#89dceb";
                  help_menu_title = "#eba0ac";
                  cursor = base06;
                  correct = base0B;
                  error = base08;
                  hint = "#74c7ec";
                  cancel = "#eba0ac";
                };
              };
              zoxide = {
                enable = true;
                enableFishIntegration = false;
              };
              fish.interactiveShellInit = ''
                source ${
                  pkgs.runCommand "zoxide-init.fish" { } ''
                    ${lib.getExe config.programs.zoxide.package} init fish > $out
                  ''
                }
              '';
            };

            home.packages = [
              open-in-terminal
              elgato-fix
            ];
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
