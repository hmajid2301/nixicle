{ pkgs, ... }:
let
  # TODO: move to official trepo
  t-smart-manager = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "t-smart-tmux-session-manager";
    version = "unstable-2023-06-05";
    rtpFilePath = "t-smart-tmux-session-manager.tmux";
    src = pkgs.fetchFromGitHub {
      owner = "joshmedeski";
      repo = "t-smart-tmux-session-manager";
      rev = "0a4c77c5c3858814621597a8d3997948b3cdd35d";
      sha256 = "1dr5w02a0y84q2iw4jp1psxvkyj4g6pr87gc22syw1jd4ibkn925";
    };
  };
in
{
  # TODO: what if this is defined in another file? Merge it!
  programs.fish = {
    shellInit = ''
      fish_add_path ${t-smart-manager}/share/tmux-plugins/t-smart-tmux-session-manager/bin/
    '';
  };

  home.packages = with pkgs; [
    lsof
    # for tmux super fingers
    python311
  ];

  programs.tmux = {
    enable = true;
    shell = "${pkgs.fish}/bin/fish";
    terminal = "tmux-256color";
    historyLimit = 100000;
    plugins = with pkgs.tmuxPlugins;
      [
        sensible
        better-mouse-mode
        yank
        tmux-thumbs
        {
          plugin = t-smart-manager;
          extraConfig = ''
            set -g @t-fzf-prompt '  '
            set -g @t-bind "T"
          '';
        }
        {
          plugin = mkTmuxPlugin {
            pluginName = "tmux-super-fingers";
            version = "unstable-2023-05-31";
            src = pkgs.fetchFromGitHub {
              owner = "artemave";
              repo = "tmux_super_fingers";
              rev = "2c12044984124e74e21a5a87d00f844083e4bdf7";
              sha256 = "sha256-cPZCV8xk9QpU49/7H8iGhQYK6JwWjviL29eWabuqruc=";
            };
          };
          extraConfig = ''
            set -g @super-fingers-key f
          '';
        }
        {
          plugin = mkTmuxPlugin {
            pluginName = "tmux-super-fingers";
            version = "unstable-2023-05-31";
            src = pkgs.fetchFromGitHub {
              owner = "artemave";
              repo = "tmux_super_fingers";
              rev = "2c12044984124e74e21a5a87d00f844083e4bdf7";
              sha256 = "sha256-cPZCV8xk9QpU49/7H8iGhQYK6JwWjviL29eWabuqruc=";
            };
          };
          extraConfig = ''
            set -g @super-fingers-key f
          '';
        }
        {
          plugin = mkTmuxPlugin {
            pluginName = "tmux-browser";
            version = "unstable-2022-10-24";
            src = pkgs.fetchFromGitHub {
              owner = "ofirgall";
              repo = "tmux-browser";
              rev = "c3e115f9ebc5ec6646d563abccc6cf89a0feadb8";
              sha256 = "sha256-ngYZDzXjm4Ne0yO6pI+C2uGO/zFDptdcpkL847P+HCI=";
            };
          };
          extraConfig = ''
            set -g @browser_close_on_deattach '1'
          '';
        }
        {
          plugin = mkTmuxPlugin {
            pluginName = "tmux.nvim";
            version = "unstable-2023-01-06";
            src = pkgs.fetchFromGitHub {
              owner = "aserowy";
              repo = "tmux.nvim";
              rev = "57220071739c723c3a318e9d529d3e5045f503b8";
              sha256 = "sha256-zpg7XJky7PRa5sC7sPRsU2ZOjj0wcepITLAelPjEkSI=";
            };
          };
        }
        # must be before continuum edits right status bar
        {
          plugin = catppuccin;
          extraConfig = '' 
            set -g @catppuccin_flavour 'frappe'
            set -g @catppuccin_window_tabs_enabled on
            set -g @catppuccin_date_time "%H:%M"
          '';
        }
        {
          plugin = resurrect;
          extraConfig = ''
            set -g @resurrect-strategy-vim 'session'
            set -g @resurrect-strategy-nvim 'session'
            set -g @resurrect-capture-pane-contents 'on'
          '';
        }
        {
          plugin = continuum;
          extraConfig = ''
            set -g @continuum-restore 'on'
            set -g @continuum-boot 'on'
            set -g @continuum-save-interval '10'
          '';
        }
      ];
    extraConfig = ''
      set -g default-terminal "tmux-256color"
      set -ag terminal-overrides ",xterm-256color:RGB"

      set-option -g prefix C-a
      unbind-key C-b
      bind-key C-a send-prefix

      set -g mouse on

      # Change splits to match nvim and easier to remember
      # Open new split at cwd of current split
      unbind %
      unbind '"'
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # Use vim keybindings in copy mode
      set-window-option -g mode-keys vi

      # v in copy mode starts making selection
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

      # Escape turns on copy mode
      bind Escape copy-mode

      # Easier reload of config
      bind r source-file ~/.config/tmux/tmux.conf

      set-option -g status-position top

      # make Prefix p paste the buffer.
      unbind p
      bind p paste-buffer

      
      bind-key -T copy-mode-vi M-h resize-pane -L 1
      bind-key -T copy-mode-vi M-j resize-pane -D 1
      bind-key -T copy-mode-vi M-k resize-pane -U 1
      bind-key -T copy-mode-vi M-l resize-pane -R 1

      # Bind Keys
      bind-key -T prefix C-g split-window \
        "$SHELL --login -i -c 'navi --print | head -c -1 | tmux load-buffer -b tmp - ; tmux paste-buffer -p -t {last} -b tmp -d'"
      bind-key -T prefix C-l switch -t notes
      bind-key -T prefix C-d switch -t dotfiles
      bind-key e send-keys "tmux capture-pane -p -S - | nvim -c 'set buftype=nofile' +" Enter
    '';
  };
}
