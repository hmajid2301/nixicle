# pyenv init
if command -v pyenv 1>/dev/null 2>&1
    pyenv init - | source
end

# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/google-cloud-sdk/path.fish.inc" ]
    . "$HOME/google-cloud-sdk/path.fish.inc"
end

# The next line updates PATH for Netlify's Git Credential Helper.
test -f "$HOME/.config/netlify/helper/path.fish.inc" && source '/home/haseeb/.config/netlify/helper/path.fish.inc'

# pnpm
set -gx PNPM_HOME "/home/haseeb/.local/share/pnpm"
set -gx PATH "$PNPM_HOME" $PATH
alias pn=pnpm
# pnpm end
