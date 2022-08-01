abbr g=git
abbr ga='git add'
abbr gaa='git add --all'
abbr gapa='git add --patch'
abbr gap='git apply'
abbr gb='git branch -vv'
abbr gba='git branch -a -v'
abbr gban='git branch -a -v --no-merged'
abbr gbd='git branch -d'
abbr gbD='git branch -D'
abbr gbl        git blame -b -w
abbr gbs        git bisect
abbr gbsb       git bisect bad
abbr gbsg       git bisect good
abbr gbsr       git bisect reset
abbr gbss       git bisect start
abbr gc         git commit -v
abbr gc!        git commit -v --amend
abbr gcn!       git commit -v --no-edit --amend
abbr gca        git commit -v -a
abbr gca!       git commit -v -a --amend
abbr gcan!      git commit -v -a --no-edit --amend
abbr gcv        git commit -v --no-verify
abbr gcav       git commit -a -v --no-verify
abbr gcav!      git commit -a -v --no-verify --amend
abbr gcm        git commit -m
abbr gcam       git commit -a -m
abbr gscam      git commit -S -a -m
abbr gcfx       git commit --fixup
abbr gcf        git config --list
abbr gcl='git clone'
abbr gclean     git clean -di
abbr gclean!    git clean -dfx
abbr gclean!!   "git reset --hard; and git clean -dfx"
abbr gcount     git shortlog -sn
abbr gcp        git cherry-pick
abbr gcpa       git cherry-pick --abort
abbr gcpc       git cherry-pick --continue
abbr gd         git diff
abbr gdca       git diff --cached
abbr gds        git diff --stat
abbr gdsc       git diff --stat --cached
abbr gdw        git diff --word-diff
abbr gdwc       git diff --word-diff --cached
abbr gignore    git update-index --assume-unchanged
abbr gf         git fetch
abbr gfa        git fetch --all --prune
abbr gfm        "git fetch origin master --prune; and git merge FETCH_HEAD"
abbr gfo        git fetch origin
abbr gl         git pull
abbr gll        git pull origin
abbr glr        git pull --rebase
abbr glg        git log --stat --max-count=10
abbr glgg       git log --graph --max-count=10
abbr glgga      git log --graph --decorate --all
abbr glo        git log --oneline --decorate --color
abbr glog       git log --oneline --decorate --color --graph
abbr glom       git log --oneline --decorate --color master..
abbr glod       git log --oneline --decorate --color develop..
abbr gloo       "git log --pretty=format:'%C(yellow)%h %Cred%ad %Cblue%an%Cgreen%d %Creset%s' --date=short"
abbr gm         git merge
abbr gmt        git mergetool --no-prompt
abbr gp='git push'
abbr gp!        git push --force-with-lease
abbr gpo        git push origin
abbr gpo!       git push --force-with-lease origin
abbr gpv        git push --no-verify
abbr gpv!       git push --no-verify --force-with-lease
abbr ggp!       ggp --force-with-lease
abbr gpu        ggp --set-upstream
abbr gr         git remote -vv
abbr gra        git remote add
abbr grb        git rebase
abbr grba       git rebase --abort
abbr grbc       git rebase --continue
abbr grbi       git rebase --interactive
abbr grbm       git rebase master
abbr grbmi      git rebase master --interactive
abbr grbmia     git rebase master --interactive --autosquash
abbr grbd       git rebase develop
abbr grbdi      git rebase master --interactive
abbr grbdia     git rebase master --interactive --autosquash
abbr grbs       git rebase --skip
abbr grev       git revert
abbr grh        git reset
abbr grhh       git reset --hard
abbr grm        git rm
abbr grmc       git rm --cached
abbr grmv       git remote rename
abbr grrm       git remote remove
abbr grs        git restore
abbr grset      git remote set-url
abbr grss       git restore --source
abbr grup       git remote update
abbr grv        git remote -v
abbr gsh        git show
abbr gsd        git svn dcommit
abbr gsr        git svn rebase
abbr gss        git status -s
abbr gst        git status
abbr gsta       git stash
abbr gstd       git stash drop
abbr gstp       git stash pop
abbr gsts       git stash show --text
abbr gsu        git submodule update
abbr gsur       git submodule update --recursive
abbr gsuri      git submodule update --recursive --init
abbr gts        git tag -s
abbr gtv        git tag | sort -V
abbr gsw        git switch
abbr gswc       git switch --create
abbr gunignore  git update-index --no-assume-unchanged
abbr gup        git pull --rebase
abbr gwch       git whatchanged -p --abbrev-commit --pretty=medium
