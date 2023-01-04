starship init fish | source
set -x PATH $PATH $HOME/.pyenv/bin $HOME/.poetry/bin $HOME/.local/bin $HOME/go/bin
set -x GOPATH $HOME/go
set -x EDITOR vim

# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/google-cloud-sdk/path.fish.inc" ]
    . "$HOME/google-cloud-sdk/path.fish.inc"
end

# pyenv init
if command -v pyenv 1>/dev/null 2>&1
    pyenv init - | source
end

zoxide init fish | source

# The next line updates PATH for Netlify's Git Credential Helper.
test -f '/home/haseeb/.config/netlify/helper/path.fish.inc' && source '/home/haseeb/.config/netlify/helper/path.fish.inc'
# pnpm
set -gx PNPM_HOME "/home/haseeb/.local/share/pnpm"
set -gx PATH "$PNPM_HOME" $PATH
alias pn=pnpm
# pnpm end
