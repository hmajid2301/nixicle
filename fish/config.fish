set PATH $HOME/.pyenv/bin $HOME/.poetry/bin $HOME/.local/bin $HOME/go/bin /usr/local/bin $PATH
set -x GOPATH $HOME/go
set -x EDITOR vim
# ~/.tmux/plugins
fish_add_path $HOME/.tmux/plugins/t-smart-tmux-session-manager/bin
# ~/.config/tmux/plugins
fish_add_path $HOME/.config/tmux/plugins/t-smart-tmux-session-manager/bin

starship init fish | source
zoxide init fish | source
source /opt/asdf-vm/asdf.fish
source ~/.config/fish/extra.fish
