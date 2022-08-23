# Created by newuser for 5.9

HISTFILE=~/.histfile
HISTSIZE=1000000000
SAVEHIST=1000000000
setopt HIST_FIND_NO_DUPS
setopt INC_APPEND_HISTORY
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=242"

eval "$(starship init zsh)"

fpath=(~/.zsh/zsh-completions/src ~/.zsh/completions $fpath)

source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/fzf-zsh-plugin/fzf-zsh-plugin.plugin.zsh
source ~/.zsh/zsh-history-substring-search/zsh-history-substring-search.zsh
source ~/.zsh/zsh-abbr/zsh-abbr.zsh
source ~/.zsh/exa-zsh/exa-zsh.plugin.zsh
source ~/.zsh/zsh-auto-notify/auto-notify.plugin.zsh
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

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

# pyenv and nvm
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
source /usr/share/nvm/init-nvm.sh

# Auto-add ssh keys to your ssh agent
[ -z "$SSH_AUTH_SOCK" ] && eval "$(ssh-agent -s)"

# FZF colours
export FZF_DEFAULT_OPTS=" \
--color=bg+:#414559,bg:#303446,spinner:#f2d5cf,hl:#e78284 \
--color=fg:#c6d0f5,header:#e78284,info:#ca9ee6,pointer:#f2d5cf \
--color=marker:#f2d5cf,fg+:#c6d0f5,prompt:#ca9ee6,hl+:#e78284"

# graphite.dev gt completions
_gt_yargs_completions()
{
  local reply
  local si=$IFS
  IFS=$'
' reply=($(COMP_CWORD="$((CURRENT-1))" COMP_LINE="$BUFFER" COMP_POINT="$CURSOR" gt --get-yargs-completions "${words[@]}"))
  IFS=$si
  _describe 'values' reply
}
compdef _gt_yargs_completions gt


# Aliases
alias docker-kill="docker kill $(docker ps -q)"
alias docker-rm="docker rm $(docker ps -a -q)"
alias docker-rmi="docker rmi $(docker images -q)"
alias clip="xclip -sel clip"

# WSL Setup
export DISPLAY=:0
# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/haseeb/google-cloud-sdk/path.zsh.inc' ]; then . '/home/haseeb/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/haseeb/google-cloud-sdk/completion.zsh.inc' ]; then . '/home/haseeb/google-cloud-sdk/completion.zsh.inc'; fi
