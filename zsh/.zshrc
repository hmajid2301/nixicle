# Created by newuser for 5.9

HISTFILE=~/.histfile
HISTSIZE=100000
SAVEHIST=1000
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=242"

eval "$(starship init zsh)"

fpath=(~/.zsh/zsh-completions/src $fpath)

source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/fzf-zsh-plugin/fzf-zsh-plugin.plugin.zsh
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ~/.zsh/zsh-history-substring-search/zsh-history-substring-search.zsh
source ~/.zsh/zsh-abbr/zsh-abbr.zsh
source ~/.zsh/exa-zsh/exa-zsh.plugin.zsh
source ~/.zsh/zsh-auto-notify/auto-notify.plugin.zsh

eval "$(zoxide init zsh)"
autoload -Uz compinit && compinit
bindkey  "^[[H"   beginning-of-line
bindkey  "^[[F"   end-of-line
bindkey  "^[[3~"  delete-char
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word
bindkey \^u backward-kill-line

# Created by `pipx` on 2022-08-01 08:31:14
export PATH="$PATH:/home/haseeb/.local/bin"
export PATH="$HOME/.poetry/bin:$PATH"
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

if [ $(ps ax | grep "[s]sh-agent" | wc -l) -eq 0 ] ; then
    eval $(ssh-agent -s) > /dev/null
    if [ "$(ssh-add -l)" = "The agent has no identities." ] ; then
        # Auto-add ssh keys to your ssh agent
        ssh-add ~/.ssh/id_ed25519 > /dev/null 2>&1
    fi
fi

