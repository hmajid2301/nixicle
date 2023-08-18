{
  pkgs,
  config,
  ...
}: let
  inherit (config) colorscheme;
  inherit (colorscheme) colors;
in {
  programs.fish = {
    enable = true;
    interactiveShellInit =
      # Open command buffer in vim when alt+e is pressed
      ''
        bind \ee edit_command_buffer
      ''
      +
      # Source scripts
      ''
        any-nix-shell fish --info-right | source
        fish_add_path ~/go/bin/
        set -x GOPATH $HOME/go
      ''
      +
      # fifc setup
      ''
        set -Ux fifc_editor nvim
        set -U fifc_keybinding \cx
      ''
      +
      # FZF
      ''
        export FZF_DEFAULT_OPTS="
        --bind 'j:down,k:up,ctrl-j:preview-down,ctrl-k:preview-up'
        --color=bg+:#${colors.base02},bg:#${colors.base00},spinner:#${colors.base06},hl:#${colors.base08}
        --color=fg:#${colors.base05},header:#${colors.base08},info:#${colors.base0E},pointer:#${colors.base06}
        --color=marker:#${colors.base06},fg+:#${colors.base05},prompt:#${colors.base0E},hl+:#${colors.base08}
        "
      ''
      + ''
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
      ''
      +
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
      cp = "xcp";
      grep = "rg";
      dig = "dog";
      cat = "bat";
      curl = "curlie";
      rm = "trash";
      ping = "gping";
      ls = "exa";
      sl = "exa";
      cava = "TERM=st-256color cava";

      # nix
      hms = "home-manager switch --flake ~/dotfiles#mesmer";
      nrs = "sudo nixos-rebuild switch --flake ~/dotfiles#mesmer";

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
      {
        name = "bass";
        src = pkgs.fishPlugins.bass.src;
      }
      {
        name = "fzf-fish";
        src = pkgs.fishPlugins.fzf-fish.src;
      }
      {
        name = "nix";
        src = pkgs.fetchFromGitHub {
          owner = "kidonng";
          repo = "nix.fish";
          rev = "ad57d970841ae4a24521b5b1a68121cf385ba71e";
          sha256 = "13x3bfif906nszf4mgsqxfshnjcn6qm4qw1gv7nw89wi4cdp9i8q";
        };
      }
      {
        name = "abbr-tips";
        src = pkgs.fetchFromGitHub {
          owner = "gazorby";
          repo = "fish-abbreviation-tips";
          rev = "8ed76a62bb044ba4ad8e3e6832640178880df485";
          sha256 = "05b5qp7yly7mwsqykjlb79gl24bs6mbqzaj5b3xfn3v2b7apqnqp";
        };
      }
      {
        name = "fifc";
        src = pkgs.fetchFromGitHub {
          owner = "gazorby";
          repo = "fifc";
          rev = "8bd370c4a5db3b71f52a3079b758f0f2ed082044";
          sha256 = "19mxl9wp335scmg4r4sijgwlhar2kiiir7fl7amahx3fih2ps4f2";
        };
      }
      {
        name = "nix.fish";
        src = pkgs.fetchFromGitHub {
          owner = "kidonng";
          repo = "nix.fish";
          rev = "ad57d970841ae4a24521b5b1a68121cf385ba71e";
          sha256 = "13x3bfif906nszf4mgsqxfshnjcn6qm4qw1gv7nw89wi4cdp9i8q";
        };
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
      {
        name = "tmux-abbr";
        src = pkgs.fetchFromGitHub {
          owner = "lewisacidic";
          repo = "fish-tmux-abbr";
          rev = "47d633a36bec3fe0ed150473e93bdb54000a5216";
          sha256 = "1y1ypbw05hsnmgmzv7aab08iv5mx2y1l24nsryjf7sj67q23xnkz";
        };
      }
    ];
  };
  xdg.configFile."fish/themes/Catppuccin Frappe.theme".text = builtins.readFile (pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/catppuccin/fish/main/themes/Catppuccin%20Frappe.theme";
    sha256 = "sha256-DX02wNghAaOhcqqEGo5StwV7Gdr2Hej82EYNkqCXEOM=";
  });
}
