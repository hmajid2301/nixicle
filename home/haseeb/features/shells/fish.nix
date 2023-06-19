{ lib, pkgs, config, ... }:

let
  inherit (config) colorscheme;
  inherit (colorscheme) colors;
in
{
  programs.fish = {
    enable = true;
    interactiveShellInit =
      # Open command buffer in vim when alt+e is pressed
      ''
        bind \ee edit_command_buffer 
      '' +

      # Source scripts
      ''
        any-nix-shell fish --info-right | source
      '' +

      # fifc setup
      ''
        set -Ux fifc_editor nvim
        set -U fifc_keybinding \cx
      '' +

      # FZF
      ''
        export FZF_DEFAULT_OPTS="
        --bind 'j:down,k:up,ctrl-j:preview-down,ctrl-k:preview-up'
        --color=bg+:#${colors.base02},bg:#${colors.base00},spinner:#${colors.base06},hl:#${colors.base08}
        --color=fg:#${colors.base05},header:#${colors.base08},info:#${colors.base0E},pointer:#${colors.base06}
        --color=marker:#${colors.base06},fg+:#${colors.base05},prompt:#${colors.base0E},hl+:#${colors.base08}
        "
      '' +

      ''
        set -g fish_color_normal ${colors.base05}
        set -g fish_color_command ${colors.base0D}
        set -g fish_color_param ${colors.base0F}
        set -g fish_color_keyword ${colors.base08}
        set -g fish_color_quote ${colors.base0B}
        set -g fish_color_redirection f4b8e4
        set -g fish_color_end ${colors.base09}
        set -g fish_color_comment 838ba7
        set -g fish_color_error ${colors.base08}
        set -g fish_color_gray 737994
        set -g fish_color_selection --background=${colors.base02}
        set -g fish_color_search_match --background=${colors.base02}
        set -g fish_color_option ${colors.base0B}
        set -g fish_color_operator f4b8e4
        set -g fish_color_escape ea999c
        set -g fish_color_autosuggestion 737994
        set -g fish_color_cancel ${colors.base08}
        set -g fish_color_cwd ${colors.base0A}
        set -g fish_color_user ${colors.base0C}
        set -g fish_color_host ${colors.base0D}
        set -g fish_color_host_remote ${colors.base0B}
        set -g fish_color_status ${colors.base08}
        set -g fish_pager_color_progress 737994
        set -g fish_pager_color_prefix f4b8e4
        set -g fish_pager_color_completion ${colors.base05}
        set -g fish_pager_color_description 737994
      '' +

      # Use vim bindings and cursors
      ''
        fish_vi_key_bindings
        set fish_cursor_default     block      blink
        set fish_cursor_insert      line       blink
        set fish_cursor_replace_one underscore blink
        set fish_cursor_visual      block
        bind --mode insert --sets-mode default jk repaint
      '';
    shellAliases = {
      l = "exa --group --header --group-directories-first --long --git --all --binary --all --icons";
    };
    shellAbbrs = {
      # abbr existing commands
      vim = "nvim";
      n = "nvim";
      cd = "z";
      grep = "rga";
      dig = "dog";
      cat = "bat";
      curl = "curlie";
      rm = "trash";
      ping = "gping";
      ls = "exa";
      sl = "exa";
      cava = "TERM=st-256color cava";

      # nix
      hms = "home-manager switch --flake ~/dotfiles#haseeb@framework";
      nrs = "sudo nixos-rebuild switch --flake ~/dotfiles#framework";

      # new commads
      kp = "ps -ef | sed 1d | eval \"fzf $FZF_DEFAULT_OPTS -m --header=\'[kill:process]\'\" | awk \'{print $2}\'";
      weather = "curl wttr.in/London";
      cbr = "git branch --sort=-committerdate | fzf --color=always --header \"Checkout Recent Branch\" --preview \"git diff {1}\" | xargs git checkout'";
      gdub = "git fetch -p && git branch -vv | grep ': gone]' | awk '{print }' | xargs git branch -D $argv;";
      tldrf = "tldr --list | fzf --preview \"tldr {1} --color=always\" --preview-window=right,70% | xargs tldr";
      dk = "docker kill (docker ps -q)";
      ds = "docker stop (docker ps -a -q)";
      drm = "docker rm (docker ps -a -q)";
    };
    functions = {
      envsource = ''
        for line in (cat $argv | grep -v '^#')
          set item (string split -m 1 '=' $line)
          set -gx $item[1] $item[2]
          echo "Exported key $item[1]"
        end
      '';
      chtshfzf = ''
        curl --silent "cheat.sh/$(__fzf_cheat_selector)?style=rtt" | bat --style=plain
      '';
      __fzf_cheat_selector = ''
        curl --silent "cheat.sh/:list" \
            | fzf-tmux \
            -p 70%,60% \
            --layout=reverse --multi \
            --preview \
            "curl --silent cheat.sh/{}\?style=rtt" \
            --bind "?:toggle-preview" \
            --preview-window hidden,60%
      '';
      fish_greeting = {
        description = "Greeting to show when starting a fish shell";
        body = "fortune | lolcat -f | chara say -c kitten";
      };

    };
    plugins = [
      { name = "bass"; src = pkgs.fishPlugins.bass.src; }
      { name = "fzf-fish"; src = pkgs.fishPlugins.fzf-fish.src; }
      {
        name = "nix";
        src = pkgs.fetchFromGitHub {
          owner = "kidonng";
          repo = "nix.fish";
          rev = "19cfe6c7f1e8ae60865b22197fc43506d78888f8";
          sha256 = "sha256-gVHF7qJrqoiUJm0EirP5uAG37P0rbsFIIlc1TtSKsWE=";
        };
      }
      {
        name = "abbr-tips";
        src = pkgs.fetchFromGitHub {
          owner = "gazorby";
          repo = "fish-abbreviation-tips";
          rev = "75f7f66ca092d53197c1a97c7d8e93b1402fdc15";
          sha256 = "sha256-uo8pAIwq7FRQNWHh+cvXAR9Imd2PvNmlrqEiDQHWvEY=";
        };
      }
      {
        name = "fifc";
        src = pkgs.fetchFromGitHub {
          owner = "gazorby";
          repo = "fifc";
          rev = "v0.1.1";
          sha256 = "sha256-p5E4Mx6j8hcM1bDbeftikyhfHxQ+qPDanuM1wNqGm6E=";
        };
      }
      {
        name = "nix.fish";
        src = pkgs.fetchFromGitHub {
          owner = "kidonng";
          repo = "nix.fish";
          rev = "19cfe6c7f1e8ae60865b22197fc43506d78888f8";
          sha256 = "sha256-gVHF7qJrqoiUJm0EirP5uAG37P0rbsFIIlc1TtSKsWE=";
        };
      }
      {
        name = "git-abbr";
        src = pkgs.fetchFromGitHub {
          owner = "lewisacidic";
          repo = "fish-git-abbr";
          rev = "0.2.1";
          sha256 = "sha256-wye76M1fkKEmEGJI9zXBIgLr7T8dBIgJudwTXWOIFjg=";
        };
      }
      {
        name = "tmux-abbr";
        src = pkgs.fetchFromGitHub {
          owner = "lewisacidic";
          repo = "fish-tmux-abbr";
          rev = "v0.1.0";
          sha256 = "sha256-f9o+BD5G6uOkz9oSQYMXvZYdEVhKnf3rq1bDAvi6Pvg=";
        };
      }
    ];
  };
  xdg.configFile."fish/themes/Catppuccin Frappe.theme".text = builtins.readFile (pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/catppuccin/fish/main/themes/Catppuccin%20Frappe.theme";
    sha256 = "sha256-DX02wNghAaOhcqqEGo5StwV7Gdr2Hej82EYNkqCXEOM=";
  });

}
