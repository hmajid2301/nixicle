{ pkgs, lib, config, host, ... }:
with lib;
with lib.nixicle;
let cfg = config.cli.shells.fish;
in {
  options.cli.shells.fish = with types; {
    enable = mkBoolOpt false "enable fish shell";
  };

  config = mkIf cfg.enable {
    stylix.targets.fish.enable = false;
    programs.carapace.enable = true;
    programs.fish = {
      enable = true;
      interactiveShellInit = ''
        ${pkgs.nix-your-shell}/bin/nix-your-shell --nom fish | source
        set -x GOPATH $XDG_DATA_HOME/go
        set -x GOPRIVATE "git.curve.tools,go.curve.tools,gitlab.com/imaginecurve"
        set -gx PATH /usr/local/bin /usr/bin ~/.local/bin $GOPATH/bin/ $PATH $HOME/.krew/bin

        # fifc setup
        set -Ux fifc_editor nvim
        set -U fifc_keybinding \cx
        bind \cx _fifc
        bind -M insert \cx _fifc

        fzf_configure_bindings

        fish_vi_key_bindings
        set fish_cursor_default     block      blink
        set fish_cursor_insert      line       blink
        set fish_cursor_replace_one underscore blink
        set fish_cursor_visual      block

        # Correct cursor for ghostty when in VI mode.
        if string match -q -- '*ghostty*' $TERM
          set -g fish_vi_force_cursor 1
        end

        function __auto_zellij_update_tabname --on-variable PWD --description "Update zellij tab name on directory change"
          _zellij_update_tabname
        end

        eval (zellij setup --generate-auto-start fish | string collect)
      '';

      shellAliases = {
        wget = ''wget --hsts-file="$XDG_DATA_HOME/wget-hsts"'';
      };
      shellAbbrs = {
        # abbr existing commands
        vim = "regularCats";
        n = "regularCats";
        nvim = "regularCats";
        ss = "zellij -l welcome";
        cd = "z";
        cdi = "zi";
        cp = "xcp";
        grep = "rg";
        dig = "dog";
        cat = "bat";
        curl = "curlie";
        rm = "gomi";
        ping = "gping";
        ls = "eza";
        sl = "eza";
        l =
          "eza --group --header --group-directories-first --long --git --all --binary --all --icons always";
        tree = "eza --tree";
        sudo = "sudo -E -s";
        k = "kubectl";
        kgp = "kubectl get pods";

        tsu = "tailscale up";
        tsd = "tailscale down";

        # nix
        nhh = "nh home switch";
        nho = "nh os switch";
        nhu = "nh os --update";

        nd = "nix develop";
        nfu = "nix flake update";
        hms =
          "home-manager switch --flake ~/nixicle#${config.nixicle.user.name}@${host}";
        nrs = "sudo nixos-rebuild switch --flake ~/nixicle#${host}";

        # new commads
        weather = "curl wttr.in/London";

        pfile =
          "fzf --preview 'bat --style=numbers --color=always --line-range :500 {}'";
        gdub =
          "git fetch -p && git branch -vv | grep ': gone]' | awk '{print }' | xargs git branch -D $argv;";
        tldrf = ''
          ${pkgs.tldr}/bin/tldr --list | fzf --preview "${pkgs.tldr}/bin/tldr {1} --color" --preview-window=right,70% | xargs tldr'';
        docker-compose = "podman-compose";
      };

      functions = {
        fish_greeting = "";

        _zellij_update_tabname = ''
          if set -q ZELLIJ
            set current_dir $PWD
            if test $current_dir = $HOME
                set tab_name "~"
            else
                set tab_name (basename $current_dir)
            end

            if fish_git_prompt >/dev/null
                # we are in a git repo

                # if we are in a git superproject, use the superproject name
                # otherwise, use the toplevel repo name
                set git_root (git rev-parse --show-superproject-working-tree)
                if test -z $git_root
                    set git_root (git rev-parse --show-toplevel)
                end

                #  if we are in a subdirectory of the git root, use the relative path
                if test (string lower "$git_root") != (string lower "$current_dir")
                    set tab_name (basename $git_root)/(basename $current_dir)
                end
            end

            nohup zellij action rename-tab $tab_name >/dev/null 2>&1
          end
        '';

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
          home-manager generations | awk '{print $7}' | tac | fzf --preview "echo {} | xargs -I % sh -c 'nvd --color=always diff $current_gen %' | xargs -I{} bash {}/activate"
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
          name = "bass";
          inherit (pkgs.fishPlugins.bass) src;
        }
        {
          name = "fzf-fish";
          inherit (pkgs.fishPlugins.fzf-fish) src;
        }
        {
          name = "fifc";
          inherit (pkgs.fishPlugins.fifc) src;
        }
        # {
        #   name = "kubectl-abbr";
        #   src = pkgs.fetchFromGitHub {
        #     owner = "lewisacidic";
        #     repo = "fish-kubectl-abbr";
        #     rev = "161450ab83da756c400459f4ba8e8861770d930c";
        #     sha256 = "sha256-iKNaD0E7IwiQZ+7pTrbPtrUcCJiTcVpb9ksVid1J6A0=";
        #   };
        # }
        {
          name = "git-abbr";
          inherit (pkgs.fishPlugins.git-abbr) src;
        }
      ];
    };
  };
}
