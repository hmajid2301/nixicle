# Created by newuser for 5.9
HISTFILE=~/.histfile
HISTSIZE=100000
SAVEHIST=1000

eval "$(starship init zsh)"

fpath=(~/.zsh/zsh-completions/src $fpath)

source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/fzf-zsh-plugin/fzf-zsh-plugin.plugin.zsh
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ~/.zsh/zsh-history-substring-search/zsh-history-substring-search.zsh
source ~/.zsh/zsh-abbr/zsh-abbr.zsh
source ~/.zsh/exa-zsh.plugin.zsh
source ~/.zsh/zsh-auto-notify/auto-notify.plugin.zsh

eval "$(zoxide init zsh)"
autoload -Uz compinit && compinit
bindkey  "^[[H"   beginning-of-line
bindkey  "^[[F"   end-of-line
bindkey  "^[[3~"  delete-char
