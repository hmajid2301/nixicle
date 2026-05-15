{ ... }:
let
  fishPlugins = pkgs: [
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
    {
      name = "git-abbr";
      inherit (pkgs.fishPlugins.git-abbr) src;
    }
    {
      name = "completion-sync";
      src = pkgs.fetchFromGitHub {
        owner = "iynaix";
        repo = "fish-completion-sync";
        rev = "4f058ad2986727a5f510e757bc82cbbfca4596f0";
        sha256 = "sha256-kHpdCQdYcpvi9EFM/uZXv93mZqlk1zCi2DRhWaDyK5g=";
      };
    }
    {
      name = "hm-generation-reload";
      src = pkgs.writeTextDir "conf.d/hm-generation-reload.fish" ''
        function __hm_generation_reload --on-event fish_prompt
          set -l hm_gen_file ~/.local/state/home-manager/gcroots/current-home
          if test -L $hm_gen_file
            set -l current_gen (readlink $hm_gen_file)
            if set -q __hm_last_generation; and test "$__hm_last_generation" != "$current_gen"
              echo "🔄 Home Manager generation changed, reloading fish..."
              set -e __hm_last_generation
              exec fish
            end
            set -g __hm_last_generation $current_gen
          end
        end
      '';
    }
  ];
in
{
  den.aspects.fish = {
    nixos = {
      programs.fish.enable = true;
    };

    homeManager =
      { pkgs, config, ... }:
      {
        programs.fish = {
          enable = true;
          interactiveShellInit = ''
            ${pkgs.nix-your-shell}/bin/nix-your-shell fish | source
            set -x GOPATH $XDG_DATA_HOME/go
            set -x GOPRIVATE "github.com/NalaMoney"
            set -gx PATH /usr/local/bin /usr/bin ~/.local/bin $GOPATH/bin/ $PATH

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
          shellAliases.wget = ''wget --hsts-file="$XDG_DATA_HOME/wget-hsts"'';
          shellAbbrs = {
            vim = "nvim";
            n = "nvim";
            cd = "z";
            cdi = "zi";
            cp = "xcp";
            grep = "rg";
            dig = "doggo";
            cat = "bat";
            curl = "curlie";
            rm = "gomi";
            ping = "gping";
            ls = "eza";
            sl = "eza";
            l = "eza --group --header --group-directories-first --long --git --all --binary --all --icons always";
            tree = "eza --tree";
            sudo = "sudo -E";
            k = "kubectl";
            kgp = "kubectl get pods";
            tsu = "tailscale up";
            tsd = "tailscale down";
            nhh = "nh home switch";
            nho = "nh os switch";
            nhu = "nh os --update";
            nd = "nix develop";
            nfu = "nix flake update";
            hms = "home-manager switch --flake ~/nixicle#${config.home.username}@(hostname)";
            nrs = "sudo nixos-rebuild switch --flake ~/nixicle#(hostname)";
            weather = "curl wttr.in/London";
            pfile = "fzf --preview 'bat --style=numbers --color=always --line-range :500 {}'";
            gdub = "git fetch -p && git branch -vv | grep ': gone]' | awk '{print }' | xargs git branch -D $argv;";
            tldrf = ''${pkgs.tldr}/bin/tldr --list | fzf --preview "${pkgs.tldr}/bin/tldr {1} --color" --preview-window=right,70% | xargs tldr'';
            wcat = "wellcat";
            imp = "sudo ${pkgs.fd}/bin/fd --one-file-system --base-directory / --type f --hidden --exclude '{tmp,etc/passwd,var/lib/systemd/coredump,proc,sys,dev,run,nix,boot}'";
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
              set selected (home-manager generations | tac | fzf --preview "nvd --color=always diff $current_gen (echo {} | awk '{print \$7}')" | awk '{print $7}')
              if test -n "$selected"
                bash $selected/activate
              end
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
              set -l dir $argv[1]
              set -l current_dir (pwd)
              if test -n "$dir"
                if test -d "$dir"
                  z "$dir"
                else
                  echo "Directory '$dir' does not exist"
                  return 1
                end
              end
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
                if string match -q "*.md" "$item"; or string match -q "*.mdx" "$item"
                  glow "$item"
                else if test -f "$item"
                  set mime_type (file --mime-type -b "$item")
                  if string match -q "image/*" "$mime_type"
                    if command -v chafa >/dev/null
                      chafa "$item"
                    else
                      echo "Image '$item': $mime_type (preview not available)"
                    end
                  else
                    bat --style=plain --theme ansi "$item"
                  end
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
            fish_command_not_found = ''
              if contains $argv[1] $__command_not_found_confirmed_commands
                or ${pkgs.gum}/bin/gum confirm --selected.background=2 "Run using comma?"
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
          plugins = fishPlugins pkgs;
        };

        stylix.targets.fish.enable = false;
      };
  };
}
