{
  pkgs,
  lib,
  config,
  host,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.cli.shells.fish;
in
{
  options.cli.shells.fish = with types; {
    enable = mkBoolOpt false "enable fish shell";
  };

  config = mkIf cfg.enable {
    stylix.targets.fish.enable = false;
    programs.carapace.enable = true;
    programs.fish = {
      enable = true;
      interactiveShellInit = ''
        ${pkgs.nix-your-shell}/bin/nix-your-shell fish | source
        set -x GOPATH $XDG_DATA_HOME/go
        set -x GOPRIVATE "github.com/NalaMoney"
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
      '';

      shellAliases = {
        wget = ''wget --hsts-file="$XDG_DATA_HOME/wget-hsts"'';
      };
      shellAbbrs = {
        # abbr existing commands
        vim = "regularCats";
        n = "regularCats";
        nvim = "regularCats";
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
        l = "eza --group --header --group-directories-first --long --git --all --binary --all --icons always";
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
        hms = "home-manager switch --flake ~/nixicle#${config.nixicle.user.name}@${host}";
        nrs = "sudo nixos-rebuild switch --flake ~/nixicle#${host}";

        # new commands
        weather = "curl wttr.in/London";

        pfile = "fzf --preview 'bat --style=numbers --color=always --line-range :500 {}'";
        gdub = "git fetch -p && git branch -vv | grep ': gone]' | awk '{print }' | xargs git branch -D $argv;";
        tldrf = ''${pkgs.tldr}/bin/tldr --list | fzf --preview "${pkgs.tldr}/bin/tldr {1} --color" --preview-window=right,70% | xargs tldr'';

        wcat = "wellcat";
      };

      functions = {
        fish_greeting = "";

        envsource = ''
          for line in (cat $argv | grep -v '^\s*#' | grep -v '^\s*$')
              set item (string split -m 1 '=' $line)
              if test (count $item) -eq 2
                  set -gx $item[1] $item[2]
                  echo "Exported key $item[1]"
              end
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

        nz = ''
          # get first argument
          set -l dir $argv[1]
          set -l current_dir (pwd)

          # if directory is provided, cd into it first
          if test -n "$dir"
            if test -d "$dir"
              z "$dir"
            else
              echo "Directory '$dir' does not exist"
              return 1
            end
          end

          # Use fd to find files and fzf with preview like rgvim
          set file (fd --type f --hidden --follow --exclude .git --exclude node_modules |
            fzf --ansi \
                --preview 'bat --color=always --style=numbers --line-range :500 {} 2>/dev/null || echo "Binary file or preview not available"' \
                --preview-window 'up,60%,border-bottom' \
                --header 'Select file to edit (Ctrl-/ toggle preview, Ctrl-C cancel)' \
                --bind 'ctrl-/:change-preview-window(down|hidden|up)' \
                --bind 'ctrl-y:execute-silent(echo {} | wl-copy 2>/dev/null || echo {} | xclip -selection clipboard 2>/dev/null || echo "Clipboard not available")')

          if test -n "$file"
            nvim "$file"
          else
            echo "No file selected"
            # If we changed directory and no file was selected, ask if user wants to stay
            if test -n "$dir" -a (pwd) != "$current_dir"
              if gum confirm "Stay in directory $(pwd)?"
                echo "Staying in $(pwd)"
              else
                cd "$current_dir"
                echo "Returned to $current_dir"
              end
            end
          end
        '';

        wellcat = ''
          if test (count $argv) -eq 0
            echo "Usage: wellcat <file_or_directory>"
            return 1
          end

          for item in $argv
            if not test -e "$item"
              echo "Error: '$item' does not exist"
              continue
            end

            # if file extension ends with .md or .mdx, use glow
            if string match -q "*.md" "$item"; or string match -q "*.mdx" "$item"
              glow "$item"
            else if test -f "$item"
              # Check if it's an image file
              set mime_type (file --mime-type -b "$item")
              if string match -q "image/*" "$mime_type"
                # Use ghostty for image display instead of kitty icat
                if string match -q -- '*ghostty*' $TERM
                  # Note: ghostty doesn't have a direct image display command like kitty
                  # Using chafa as a fallback for now
                  if command -v chafa >/dev/null
                    chafa "$item"
                  else
                    echo "Image '$item': $mime_type (preview not available)"
                  end
                else
                  # Fallback to other image viewers
                  if command -v chafa >/dev/null
                    chafa "$item"
                  else
                    echo "Image '$item': $mime_type (preview not available)"
                  end
                end
              else
                # Regular file, use bat
                bat --style=plain --theme ansi "$item"
              end
            # if it is a directory, use eza
            else if test -d "$item"
              eza --icons -l "$item"
            end
          end
        '';

        pkill_fzf = ''
          ps aux | fzf --header-lines=1 \
                        --preview 'echo "Process Info:"; ps -p {2} -o pid,ppid,user,time,args' \
                        --bind 'enter:execute(kill {2})' \
                        --bind 'ctrl-k:execute(kill -9 {2})'
        '';

        pkill_port = ''
          # Get listening ports and processes
          set port_process (ss -tulpn | grep LISTEN | \
            awk '{
              # Extract port from local address (format: *:port or ip:port)
              split($5, addr, ":");
              port = addr[length(addr)];

              # Extract PID from process info (format: users:(("process",pid=123,fd=4)))
              if (match($7, /pid=([0-9]+)/, pid_match)) {
                pid = pid_match[1];
                # Get process name
                cmd = "ps -p " pid " -o comm= 2>/dev/null";
                cmd | getline process_name;
                close(cmd);
                if (process_name == "") process_name = "unknown";
                print port "\t" pid "\t" process_name "\t" $5;
              }
            }' | \
            fzf --header "PORT PID PROCESS LOCAL_ADDRESS" \
                --preview 'echo "Port Details:"; ss -tulpn | grep :{1}; echo ""; echo "Process Details:"; ps -p {2} -o pid,ppid,user,time,args 2>/dev/null || echo "Process not found"' \
                --bind 'enter:execute(kill {2})' \
                --bind 'ctrl-k:execute(kill -9 {2})' \
                --bind 'ctrl-s:execute(sudo kill {2})' \
                --bind 'ctrl-x:execute(sudo kill -9 {2})')

          if test -n "$port_process"
            set pid (echo "$port_process" | awk '{print $2}')
            set port (echo "$port_process" | awk '{print $1}')
            set process (echo "$port_process" | awk '{print $3}')
            echo "Selected: Port $port (PID: $pid, Process: $process)"
          else
            echo "No port selected"
          end
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
        {
          name = "nvm.fish";
          src = pkgs.fetchFromGitHub {
            owner = "jorgebucaran";
            repo = "nvm.fish";
            rev = "846f1f20b2d1d0a99e344f250493c41a450f9448";
            sha256 = "sha256-u3qhoYBDZ0zBHbD+arDxLMM8XoLQlNI+S84wnM3nDzg=";
          };
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

        # INFO: Using this to get shell completion for programs added to the path through nix+direnv.
        # Issue to upstream into direnv:Add commentMore actions
        # https://github.com/direnv/direnv/issues/443
        {
          name = "completion-sync";
          src = pkgs.fetchFromGitHub {
            owner = "iynaix";
            repo = "fish-completion-sync";
            rev = "4f058ad2986727a5f510e757bc82cbbfca4596f0";
            sha256 = "sha256-kHpdCQdYcpvi9EFM/uZXv93mZqlk1zCi2DRhWaDyK5g=";
          };
        }
      ];
    };
  };
}
