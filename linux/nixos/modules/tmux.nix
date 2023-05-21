{pkgs, ...}:
let 
  tmux-nvim = pkgs.tmuxPlugins.mkTmuxPlugin 
    { 
      pluginName = "tmux.nvim"; 
      version = "unstable-2023-01-06";
      src = pkgs.fetchFromGitHub {
        owner = "aserowy";
        repo = "tmux.nivm";
        rev = "57220071739c723c3a318e9d529d3e5045f503b8";
        sha256 = "sha256-ymmCI6VYvf94Ot7h2GAboTRBXPIREP+EB33+px5aaJk=";
      }; 
    };
  tmux-browser = pkgs.tmuxPlugins.mkTmuxPlugin 
    { 
      pluginName = "browser"; 
      version = "unstable-2023-01-06";
      src = pkgs.fetchFromGitHub {
        owner = "ofirgall";
        repo = "tmux-brower";
        rev = "c3e115f9ebc5ec6646d563abccc6cf89a0feadb8";
        sha256 = "sha256-ymmCI6VYvf94Ot7h2GAboTRBXPIREP+EB33+px5aaJk=";
      }; 
    };
  tmux-super-fingers= pkgs.tmuxPlugins.mkTmuxPlugin 
    { 
      pluginName = "tmux-super-fingers"; 
      version = "unstable-2023-01-06";
      src = pkgs.fetchFromGitHub {
        owner = "artemave";
        repo = "tmux_super_finers";
        rev = "2c12044984124e74e21a5a87d00f844083e4bdf7";
        sha256 = "sha256-ymmCI6VYvf94Ot7h2GAboTRBXPIREP+EB33+px5aaJk=";
      }; 
    };
  t-smart-manager = pkgs.tmuxPlugins.mkTmuxPlugin 
    { 
      pluginName = "t"; 
      version = "unstable-2023-01-06";
      src = pkgs.fetchFromGitHub {
        owner = "joshmedeski";
        repo = "t-smart-tmux-session-manager";
        rev = "a1e91b427047d0224d2c9c8148fb84b47f651866";
        sha256 = "sha256-ymmCI6VYvf94Ot7h2GAboTRBXPIREP+EB33+px5aaJk=";
      }; 
    };
in
{
  programs.tmux = {
    enable = true;
     plugins = with pkgs;
      [
        t-smart-manager
        tmux-super-fingers
        tmux-browser
        tmux-nvim
        tmuxPlugins.sensible
        tmuxPlugins.resurrect
        tmuxPlugins.continuum
        tmuxPlugins.better-mouse-mode
        tmuxPlugins.yank
        tmuxPlugins.catppuccin
        
      ];
    extraConfig = ''
      set-option -g prefix C-a
      unbind-key C-b
      bind-key C-a send-prefix

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

      # Set a larger scroll back
      set-option -g history-limit 100000

      # Bind Keys
      bind-key -T prefix C-g split-window \
        "$SHELL --login -i -c 'navi --print | head -c -1 | tmux load-buffer -b tmp - ; tmux paste-buffer -p -t {last} -b tmp -d'"
      bind-key -T prefix C-l switch -t notes
      bind-key -T prefix C-d switch -t dotfiles


      # plugin options
      set -g @t-fzf-prompt '  '

      # Close tmux browser session when session detaches
      set -g @browser_close_on_deattach '1'

      # Theme settings
      set -g status-left "#[fg=#000000]%R#{pomodoro_status}"
      set -g @catppuccin_flavour 'frappe'
      set -g @catppuccin_date_time "%H:%M"
      # set -g @catppuccin_right_status "#{pomodoro_status}"

      # Save and restore sessions
      set -g @resurrect-strategy-nvim 'session'
      set -g @resurrect-capture-pane-contents 'on'
      set -g @continuum-restore 'on'
      set -g @continuum-boot 'on'

      set -g @pomodoro_notifications 'on'        # Enable desktop notifications from your terminal
      set -g @pomodoro_sound 'on'                # Sound for desktop notifications (Run `ls /System/Library/Sounds` for a list of sounds to use
    '';
  };
}
