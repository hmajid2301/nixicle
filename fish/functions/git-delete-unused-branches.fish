# Defined in - @ line 1
function git-delete-unused-branches --wraps=git\ fetch\ -p\ \&\&\ git\ branch\ -vv\ \|\ grep\ \':\ gone\]\'\ \|\ awk\ \'\{print\ \}\'\ \|\ xargs\ git\ branch\ -D --description alias\ git-delete-unused-branches=git\ fetch\ -p\ \&\&\ git\ branch\ -vv\ \|\ grep\ \':\ gone\]\'\ \|\ awk\ \'\{print\ \}\'\ \|\ xargs\ git\ branch\ -D
  git fetch -p && git branch -vv | grep ': gone]' | awk '{print }' | xargs git branch -D $argv;
end
