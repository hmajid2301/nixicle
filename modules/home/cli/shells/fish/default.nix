{
  pkgs,
  lib,
  config,
  host,
  ...
}:
with lib;
with lib.nixicle; let
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
        ${pkgs.nix-your-shell}/bin/nix-your-shell --nom fish | source
        set -x GOPATH $XDG_DATA_HOME/go
        set -x GOPRIVATE "git.curve.tools,go.curve.tools,gitlab.com/imaginecurve"
        # set -x GONOSUMDB "git.curve.tools,go.curve.tools,gitlab.com/imaginecurve"
        set -gx PATH $PATH $HOME/.krew/bin
        fish_add_path --path --append $GOPATH/bin/
        fish_add_path --path --append /usr/local/bin /usr/bin ~/.local/bin

        # fifc setup
        set -Ux fifc_editor nvim
        set -U fifc_keybinding \cx
        bind \cx _fifc
        bind -M insert \cx _fifc

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
        ss = "zellij -l welcome";
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
        l = "eza --group --header --group-directories-first --long --git --all --binary --all --icons always";
        tree = "eza --tree";
        sudo = "sudo -E -s";

        # nix
        nhh = "nh home switch";
        nho = "nh os switch";
        nhu = "nh os --update";

        nd = "nix develop";
        nfu = "nix flake update";
        hms = "home-manager switch --flake ~/dotfiles#${config.nixicle.user.name}@${host}";
        nrs = "sudo nixos-rebuild switch --flake ~/dotfiles#${host}";

        # new commads
        weather = "curl wttr.in/London";

        pfile = "fzf --preview 'bat --style=numbers --color=always --line-range :500 {}'";
        gdub = "git fetch -p && git branch -vv | grep ': gone]' | awk '{print }' | xargs git branch -D $argv;";
        tldrf = "${pkgs.tldr}/bin/tldr --list | fzf --preview \"${pkgs.tldr}/bin/tldr {1} --color=always\" --preview-window=right,70% | xargs tldr";
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

        gcrb = ''
            set result (git branch -a --color=always | grep -v '/HEAD\s' | sort |
              fzf --height 50% --border --ansi --tac --preview-window right:70% \
                --preview 'git log --oneline --graph --date=short --pretty="format:%C(auto)%cd %h%d %s" (string sub -s 3 (string split ' ' {})[1]) | head -'$LINES |
              string sub -s 3 | string split ' ' -m 1)[1]

            if test -n "$result"
              if string match -r "^remotes/.*" $result > /dev/null
                git checkout --track (string replace -r "^remotes/" "" $result)
              else
                git checkout $result
              end
            end
          end
        '';

        hmg = ''
          set current_gen (home-manager generations | head -n 1 | awk '{print $7}')
          home-manager generations | awk '{print $7}' | tac | fzf --preview "echo {} | xargs -I % sh -c 'nvd --color=always diff $current_gen %' | xargs -I{} bash {}/activate""
        '';

        rgvim = ''
          rg --color=always --line-number --no-heading --smart-case "$argv" |
            fzf --ansi \
                --color "hl:-1:underline,hl+:-1:underline:reverse" \
                --delimiter : \
                --preview 'bat --color=always {1} --highlight-line {2}' \
                --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
                --bind 'enter:become(nvim {1} +{2})'
        '';

        fish_command_not_found = ''
          # If you run the command with comma, running the same command
          # will not prompt for confirmation for the rest of the session
          if contains $argv[1] $__command_not_found_confirmed_commands
            or ${pkgs.gum}/bin/gum confirm --selected.background=2 "Run using comma?"

            # Not bothering with capturing the status of the command, just run it again
            if not contains $argv[1] $__command_not_found_confirmed_commands
              set -ga __fish_run_with_comma_commands $argv[1]
            end

            comma -- $argv
            return 0
          else
            __fish_default_command_not_found_handler $argv
          end
        '';
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
            rev = "a3256cf49846ee4de072c3a9af7a58aad4021693";
            sha256 = "sha256-3M0dU30SrdjInp6MWEC0q7MTInrZNtY6Z9mhBw43PKs=";
          };
        }
        {
          name = "fifc";
          inherit (pkgs.fishPlugins.fifc) src;
        }
        {
          name = "kubectl-abbr";
          src = pkgs.fetchFromGitHub {
            owner = "lewisacidic";
            repo = "fish-kubectl-abbr";
            rev = "161450ab83da756c400459f4ba8e8861770d930c";
            sha256 = "sha256-iKNaD0E7IwiQZ+7pTrbPtrUcCJiTcVpb9ksVid1J6A0=";
          };
        }
        {
          name = "git-abbr";
          src = pkgs.fetchFromGitHub {
            owner = "lewisacidic";
            repo = "fish-git-abbr";
            rev = "dc590a5b9d9d2095f95f7d90608b48e55bea0b0e";
            sha256 = "sha256-6z3Wr2t8CP85xVEp6UCYaM2KC9PX4MDyx19f/wjHkb0=";
          };
        }
      ];
    };
  };
}
