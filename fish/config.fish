fish_config theme choose "Catppuccin Frappe"
set PATH $HOME/.local/bin $HOME/go/bin /usr/local/bin $HOME/.cargo/bin $HOME/.tmux/plugins/t-smart-tmux-session-manager/bin $PATH
set -x GOPATH $HOME/
set -x EDITOR vim

starship init fish | source
zoxide init fish | source
rtx activate fish | source

fish_vi_key_bindings
bind --mode insert --sets-mode default jk repaint

export FZF_DEFAULT_OPTS="
--color=bg+:#414559,bg:#303446,spinner:#f2d5cf,hl:#e78284 
--color=fg:#c6d0f5,header:#e78284,info:#ca9ee6,pointer:#f2d5cf 
--color=marker:#f2d5cf,fg+:#c6d0f5,prompt:#ca9ee6,hl+:#e78284
"

source ~/dotfiles/fish/extra.fish
source ~/dotfiles/fish/conf.d/abbr.fish
