{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  t-smart-manager = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "t-smart-tmux-session-manager";
    version = "unstable-2024-01-18";
    rtpFilePath = "t-smart-tmux-session-manager.tmux";
    src = pkgs.fetchFromGitHub {
      owner = "joshmedeski";
      repo = "t-smart-tmux-session-manager";
      rev = "3726950525ac9966412ea3f2093bf2ffe06aa023";
      sha256 = "0pnr1d582znbypclqc724lsfzmzz7s4sc468qgsi7dfmf6iriiq0";
    };
  };
  cfg = config.modules.multiplexers.tmux;
in {
  options.modules.multiplexers.tmux = {
    enable = mkEnableOption "enable tmux multiplexer";
  };

  config = mkIf cfg.enable {
    programs.fish.shellInit = ''
      fish_add_path ${t-smart-manager}/share/tmux-plugins/t-smart-tmux-session-manager/bin/
    '';

    home.packages = with pkgs; [
      lsof
      # for tmux super fingers
      python311
    ];

    programs.tmux = {
      enable = true;
      shell = "${config.my.settings.default.shell}";
      terminal = "tmux-256color";
      historyLimit = 100000;
      keyMode = "vi";
      prefix = "C-a";
      sensibleOnTop = true;
      mouse = true;

      plugins = with pkgs.tmuxPlugins; [
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
            version = "unstable-2023-10-03";
            src = pkgs.fetchFromGitHub {
              owner = "artemave";
              repo = "tmux_super_fingers";
              rev = "518044ef78efa1cf3c64f2e693fef569ae570ddd";
              sha256 = "1710pqvjwis0ki2c3mdrp2zia3y3i8g4rl6v42pg9nk4igsz39w8";
            };
          };
          extraConfig = ''
            set -g @super-fingers-key f
          '';
        }
        {
          plugin = mkTmuxPlugin {
            pluginName = "tmux.nvim";
            version = "unstable-2024-02-12";
            src = pkgs.fetchFromGitHub {
              owner = "aserowy";
              repo = "tmux.nvim";
              rev = "9c02adf16ff2f18c8e236deba91e9cf4356a02d2";
              sha256 = "0lg3zcyd76qfbz90i01jwhxfglsnmggynh6v48lnbz0kj1prik4y";
            };
          };
        }
        # must be before continuum edits right status bar
        {
          plugin = catppuccin;
          extraConfig = ''
            set -g @catppuccin_flavour 'mocha'
            set -g @catppuccin_window_left_separator "█"
            set -g @catppuccin_window_right_separator "█ "
            set -g @catppuccin_window_middle_separator " █"
            set -g @catppuccin_window_number_position "right"

            set -g @catppuccin_window_default_fill "number"
            set -g @catppuccin_window_default_text "#W"

            set -g @catppuccin_window_current_fill "number"
            set -g @catppuccin_window_current_text "#W"

            set -g @catppuccin_status_modules "application session date_time"
            set -g @catppuccin_status_left_separator  ""
            set -g @catppuccin_status_right_separator ""
            set -g @catppuccin_status_right_separator_inverse "no"
            set -g @catppuccin_status_fill "icon"
            #set -g @catppuccin_status_connect_separator "no"

            set -g @catppuccin_directory_text "#{pane_current_path}"
          '';
        }
        {
          plugin = resurrect;
          extraConfig =
            ''
              set -g @resurrect-strategy-vim 'session'
              set -g @resurrect-strategy-nvim 'session'
              set -g @resurrect-capture-pane-contents 'on'
            ''
            + ''
              # Taken from: https://github.com/p3t33/nixos_flake/blob/5a989e5af403b4efe296be6f39ffe6d5d440d6d6/home/modules/tmux.nix
              resurrect_dir="$XDG_CACHE_HOME/.tmux/resurrect"
              set -g @resurrect-dir $resurrect_dir

              set -g @resurrect-hook-post-save-all 'target=$(readlink -f $resurrect_dir/last); sed "s| --cmd .*-vim-pack-dir||g; s|/etc/profiles/per-user/$USER/bin/||g; s|/home/$USER/.nix-profile/bin/||g" $target | sponge $target'
            '';
        }
        {
          plugin = continuum;
          extraConfig = ''
            set -g @continuum-restore 'on'
            set -g @continuum-boot 'on'
            set -g @continuum-save-interval '10'
            set -g @continuum-systemd-start-cmd 'start-server'
          '';
        }
      ];
      extraConfig = ''
        set -ag terminal-overrides ",xterm-256color:RGB"
        set-environment -g TMUX_PLUGIN_MANAGER_PATH '~/.local/share/tmux/plugins'
        # Quicker escape in neovim
        set -sg escape-time 0
        set-option -g set-titles on
        set-option -g set-titles-string "#S / #W"

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

        set -g allow-passthrough on
        set -ga update-environment TERM
        set -ga update-environment TERM_PROGRAM

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
  };
}
