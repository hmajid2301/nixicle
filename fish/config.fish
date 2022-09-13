starship init fish | source
set -x PATH $PATH $HOME/.pyenv/bin $HOME/.poetry/bin $HOME/.local/bin 
set -x GOPATH $HOME/go

# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/google-cloud-sdk/path.fish.inc" ]
    . "$HOME/google-cloud-sdk/path.fish.inc"
end


# pyenv init
if command -v pyenv 1>/dev/null 2>&1
    pyenv init - | source
end

zoxide init fish | source
