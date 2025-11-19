{delib, ...}:
delib.module {
  name = "cli-multiplexers-tmux";

  options.cli.multiplexers.tmux = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, pkgs, ...}:
  with lib;
  with lib.nixicle;
  let
    cfg = config.cli.multiplexers.tmux;

    tmux-floax = pkgs.tmuxPlugins.mkTmuxPlugin {
      pluginName = "tmux-floax";
      version = "08-05-2024";
      src = pkgs.fetchFromGitHub {
        owner = "omerxx";
        repo = "tmux-floax";
        rev = "ecc0507a792a9f55529952c806e849c11093a168";
        sha256 = "sha256-lX5P1l4yHV8jiuHsa7GkbgGT+wk0BdyvSSUu/L6G4eQ=";
      };
    };
  in
  mkIf cfg.enable {
    home.packages = with pkgs; [
      sesh
      lsof
      # for tmux super fingers
      python311
    ];

    programs.tmux = {
      enable = true;
      shell = "${pkgs.fish}/bin/fish";
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
        tmux-floax
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
            set -g @catppuccin_status_left_separator  ""
            set -g @catppuccin_status_right_separator ""
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

        bind-key e send-keys "tmux capture-pane -p -S - | nvim -c 'set buftype=nofile' +" Enter

        # '@pane-is-vim' is a pane-local option that is set by the plugin on load,
        # and unset when Neovim exits or suspends; note that this means you'll probably
        # not want to lazy-load smart-splits.nvim, as the variable won't be set until
        # the plugin is loaded

        # Smart pane switching with awareness of Neovim splits.
        bind-key -n C-h if -F "#{@pane-is-vim}" 'send-keys C-h'  'select-pane -L'
        bind-key -n C-j if -F "#{@pane-is-vim}" 'send-keys C-j'  'select-pane -D'
        bind-key -n C-k if -F "#{@pane-is-vim}" 'send-keys C-k'  'select-pane -U'
        bind-key -n C-l if -F "#{@pane-is-vim}" 'send-keys C-l'  'select-pane -R'

        # Smart pane resizing with awareness of Neovim splits.
        bind-key -n M-h if -F "#{@pane-is-vim}" 'send-keys M-h' 'resize-pane -L 3'
        bind-key -n M-j if -F "#{@pane-is-vim}" 'send-keys M-j' 'resize-pane -D 3'
        bind-key -n M-k if -F "#{@pane-is-vim}" 'send-keys M-k' 'resize-pane -U 3'
        bind-key -n M-l if -F "#{@pane-is-vim}" 'send-keys M-l' 'resize-pane -R 3'

        tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
        if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
            "bind-key -n 'C-\\' if -F \"#{@pane-is-vim}\" 'send-keys C-\\'  'select-pane -l'"
        if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
            "bind-key -n 'C-\\' if -F \"#{@pane-is-vim}\" 'send-keys C-\\\\'  'select-pane -l'"

        bind-key -T copy-mode-vi 'C-h' select-pane -L
        bind-key -T copy-mode-vi 'C-j' select-pane -D
        bind-key -T copy-mode-vi 'C-k' select-pane -U
        bind-key -T copy-mode-vi 'C-l' select-pane -R
        bind-key -T copy-mode-vi 'C-\' select-pane -l        # Bind Keys
        bind-key -T prefix C-g split-window \
        	"$SHELL --login -i -c 'navi --print | head -c -1 | tmux load-buffer -b tmp - ; tmux paste-buffer -p -t {last} -b tmp -d'"
      '';
    };
  };
}
