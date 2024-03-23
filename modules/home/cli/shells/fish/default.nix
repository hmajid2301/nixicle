{
  pkgs,
  lib,
  config,
  host,
  ...
}:
with lib;
with lib.nixicle; let
  inherit (config.colorScheme) palette;
  cfg = config.cli.shells.fish;
in {
  options.cli.shells.fish = with types; {
    enable = mkBoolOpt false "enable fish shell";
  };

  config = mkIf cfg.enable {
    programs.fish = {
      enable = true;
      interactiveShellInit = ''
        # Open command buffer in vim when alt+e is pressed
        bind \ee edit_command_buffer
        nix-your-shell fish | source
        fish_add_path --path --prepend /usr/local/bin /usr/bin ~/.local/bin
        set -x GOPATH $XDG_DATA_HOME/go
        set -x GOPRIVATE "git.curve.tools,gitlab.com/imaginecurve"
        fish_add_path --path --append $GOPATH/bin/

        # fifc setup
        set -Ux fifc_editor nvim
        set -U fifc_keybinding \cx
        bind \cx _fifc
        bind -M insert \cx _fifc

        # FZF
        export FZF_DEFAULT_OPTS="
        	--color=bg+:#${palette.base02},bg:#${palette.base00},spinner:#${palette.base06},hl:#${palette.base08}
        	--color=fg:#${palette.base05},header:#${palette.base08},info:#${palette.base0E},pointer:#${palette.base06}
        	--color=marker:#${palette.base06},fg+:#${palette.base05},prompt:#${palette.base0E},hl+:#${palette.base08}
        "
        bind \cr _fzf_search_history
        bind -M insert \cr _fzf_search_history

        set -g fish_color_normal ${palette.base05}
        set -g fish_color_command ${palette.base0D}
        set -g fish_color_param ${palette.base0F}
        set -g fish_color_keyword ${palette.base08}
        set -g fish_color_quote ${palette.base0B}
        set -g fish_color_redirection f4b8e4
        set -g fish_color_end ${palette.base09}
        set -g fish_color_comment 838ba7
        set -g fish_color_error ${palette.base08}
        set -g fish_color_gray 737994
        set -g fish_color_selection --background=${palette.base02}
        set -g fish_color_search_match --background=${palette.base02}
        set -g fish_color_option ${palette.base0B}
        set -g fish_color_operator f4b8e4
        set -g fish_color_escape ea999c
        set -g fish_color_autosuggestion 737994
        set -g fish_color_cancel ${palette.base08}
        set -g fish_color_cwd ${palette.base0A}
        set -g fish_color_user ${palette.base0C}
        set -g fish_color_host ${palette.base0D}
        set -g fish_color_host_remote ${palette.base0B}
        set -g fish_color_status ${palette.base08}
        set -g fish_pager_color_progress 737994
        set -g fish_pager_color_prefix f4b8e4
        set -g fish_pager_color_completion ${palette.base05}
        set -g fish_pager_color_description 737994

        fish_vi_key_bindings
        set fish_cursor_default     block      blink
        set fish_cursor_insert      line       blink
        set fish_cursor_replace_one underscore blink
        set fish_cursor_visual      block
        bind --mode insert --sets-mode default jk repaint
      '';
      shellAliases = {
        wget = "wget --hsts-file=\"$XDG_DATA_HOME/wget-hsts\"";
      };
      shellAbbrs = {
        # abbr existing commands
        vim = "nvim";
        n = "nvim";
        cd = "z";
        cdi = "zi";
        cp = "xcp";
        grep = "rg";
        dig = "dog";
        cat = "bat";
        curl = "curlie";
        rm = "trash";
        ping = "gping";
        ls = "eza";
        sl = "eza";
        l = "eza --group --header --group-directories-first --long --git --all --binary --all --icons";
        tree = "eza --tree";
        sudo = "sudo -E -s";

        # nix
        nd = "nix develop";
        nfu = "nix flake update";
        hms = "home-manager switch --flake ~/dotfiles#${host}";
        hmr = "home-manager generations | fzf --tac | awk '{print $7}' | xargs -I{} bash {}/activate";
        nrs = "sudo nixos-rebuild switch --flake ~/dotfiles#${host}";
        niso = "nix build .#nixosConfigurations.iso.config.system.build.isoImage";

        # new commads
        weather = "curl wttr.in/London";

        gdub = "git fetch -p && git branch -vv | grep ': gone]' | awk '{print }' | xargs git branch -D $argv;";
        tldrf = "tldr --list | fzf --preview \"tldr {1} --color=always\" --preview-window=right,70% | xargs tldr";
        dk = "docker kill (docker ps -q)";
        ds = "docker stop (docker ps -a -q)";
        drm = "docker rm (docker ps -a -q)";
        docker-compose = "podman-compose";
      };

      functions = {
        fish_greeting = '''';

        envsource = ''
          for line in (cat $argv | grep -v '^#')
            set item (string split -m 1 '=' $line)
            set -gx $item[1] $item[2]
            echo "Exported key $item[1]"
          end
        '';

        # fish_command_not_found = ''
        #   # If you run the command with comma, running the same command
        #   # will not prompt for confirmation for the rest of the session
        #   if contains $argv[1] $__command_not_found_confirmed_commands
        #     or gum confirm --selected.background=2 "Run using comma?"
        #
        #     # Not bothering with capturing the status of the command, just run it again
        #     if not contains $argv[1] $__command_not_found_confirmed_commands
        #       set -ga __fish_run_with_comma_commands $argv[1]
        #     end
        #
        #     comma -- $argv
        #     return 0
        #   else
        #     __fish_default_command_not_found_handler $argv
        #   end
        # '';
      };
      plugins = [
        {
          name = "forgit";
          inherit (pkgs.fishPlugins.forgit) src;
        }
        {
          name = "bass";
          inherit (pkgs.fishPlugins.bass) src;
        }
        {
          name = "fzf-fish";
          inherit (pkgs.fishPlugins.fzf-fish) src;
        }
        {
          # TODO: until MR is merged in
          name = "nix.fish";
          src = pkgs.fetchFromGitHub {
            owner = "Animeshz";
            repo = "nix.fish";
            rev = "ad57d970841ae4a24521b5b1a68121cf385ba71e";
            sha256 = "sha256-GMV0GyORJ8Tt2S9wTCo2lkkLtetYv0rc19aA5KJbo48=";
          };
        }
        {
          name = "fifc";
          inherit (pkgs.fishPlugins.fifc) src;
        }
        {
          name = "git-abbr";
          src = pkgs.fetchFromGitHub {
            owner = "lewisacidic";
            repo = "fish-git-abbr";
            rev = "dc590a5b9d9d2095f95f7d90608b48e55bea0b0e";
            sha256 = "1gciqw4gypszqzrc1q6psc5qmkb8k10fjaaiqlwzy23wdfpxcggb";
          };
        }
      ];
    };
  };
}
