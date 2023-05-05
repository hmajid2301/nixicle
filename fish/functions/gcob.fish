function gcb
    set result (git branch -a --color=always | grep -v '/HEAD\s' | sort |
    fzf --height 50% --border --ansi --tac --preview-window right:70% \
      --preview 'git log --oneline --graph --date=short --pretty="format:%C(auto)%cd %h%d %s" $(sed s/^..// <<< {} | cut -d" " -f1) | head -'$LINES | sed 's/^..//' | cut -d' ' -f1)

    if $result != ""
        if $result == remotes/*
            git checkout --track $(echo $result | sed 's#remotes/##')
        else
            git checkout "$result"
        end
    end
end
