package main

import (
	"fmt"

	"github.com/urfave/cli/v2"
)

func generateBashCompletion(c *cli.Context) error {
	script := `#!/bin/bash
_gsesh_completion() {
    local cur prev words cword
    _init_completion || return

    local commands="clean sessions switch jump new attach status context completion"
    local aliases="c ss sw j n at st"

    if [[ ${prev} == "gsesh" ]]; then
        COMPREPLY=($(compgen -W "${commands} ${aliases}" -- "${cur}"))
        return
    fi

    case ${prev} in
        new|n|attach|at)
            local branches=$(git branch -a 2>/dev/null | sed 's/^[* ]*//' | sed 's|remotes/[^/]*/||' | sort -u)
            COMPREPLY=($(compgen -W "${branches}" -- "${cur}"))
            return
            ;;
        --layout|-L)
            local layouts=$(ls ~/.config/zellij/layouts/*.kdl 2>/dev/null | xargs -I {} basename {} .kdl)
            COMPREPLY=($(compgen -W "${layouts} default compact strider" -- "${cur}"))
            return
            ;;
        --ai-tool)
            COMPREPLY=($(compgen -W "claude opencode aider" -- "${cur}"))
            return
            ;;
        completion)
            COMPREPLY=($(compgen -W "bash zsh fish" -- "${cur}"))
            return
            ;;
    esac

    if [[ ${cur} == -* ]]; then
        COMPREPLY=($(compgen -W "--debug --sesh --no-fetch --branch --list --worktree-base --claude-prefix --ai --ai-tool --layout --help" -- "${cur}"))
        return
    fi
}

complete -F _gsesh_completion gsesh
`
	fmt.Println(script)
	return nil
}

func generateZshCompletion(c *cli.Context) error {
	script := `#compdef gsesh

_gsesh() {
    local -a commands
    commands=(
        'clean:c:Clean up worktrees for merged/deleted branches'
        'sessions:ss:List all zellij sessions and their status'
        'switch:sw:Switch to a zellij session using interactive UI'
        'jump:j:Jump to any project/worktree globally (via zoxide)'
        'new:n:Create new branch/worktree/session quickly'
        'attach:at:Attach to existing worktree/session quickly'
        'status:st:Show git status across all worktrees'
        'context:Show context files for current worktree'
        'completion:Generate shell completions'
    )

    if (( CURRENT == 2 )); then
        _describe 'command' commands
        return
    fi

    local cmd="${words[2]}"

    case $cmd in
        new|n|attach|at)
            _arguments \
                '--ai[Start AI assistant]' \
                '--layout[Zellij layout]:layout:_gsesh_layouts' \
                '--base[Base branch to create from]:branch:_git_branches' \
                '1:branch:_git_branches'
            return
            ;;
        jump|j)
            _arguments \
                '--ai[Start AI assistant]'
            return
            ;;
        clean|c)
            _arguments \
                '--dry-run[Show what would be removed]'
            return
            ;;
        completion)
            _describe 'shell' '(bash zsh fish)'
            return
            ;;
    esac
}

_gsesh_layouts() {
    local -a layouts
    layouts=(default compact strider)
    local layout_dir="$HOME/.config/zellij/layouts"
    if [[ -d "$layout_dir" ]]; then
        for f in "$layout_dir"/*.kdl(N); do
            layouts+=("$(basename "$f" .kdl)")
        done
    fi
    _describe 'layout' layouts
}

_git_branches() {
    local -a branches
    branches=(${(f)"$(git branch -a 2>/dev/null | sed 's/^[* ]*//' | sed 's|remotes/[^/]*/||' | sort -u)"})
    _describe 'branch' branches
}

_gsesh
`
	fmt.Println(script)
	return nil
}

func generateFishCompletion(c *cli.Context) error {
	script := `# gsesh completions for fish

complete -c gsesh -f

# Commands
complete -c gsesh -n '__fish_use_subcommand' -a 'clean' -d 'Clean up worktrees for merged/deleted branches'
complete -c gsesh -n '__fish_use_subcommand' -a 'c' -d 'Clean up worktrees for merged/deleted branches'
complete -c gsesh -n '__fish_use_subcommand' -a 'sessions' -d 'List all zellij sessions and their status'
complete -c gsesh -n '__fish_use_subcommand' -a 'ss' -d 'List all zellij sessions and their status'
complete -c gsesh -n '__fish_use_subcommand' -a 'switch' -d 'Switch to a zellij session using interactive UI'
complete -c gsesh -n '__fish_use_subcommand' -a 'sw' -d 'Switch to a zellij session using interactive UI'
complete -c gsesh -n '__fish_use_subcommand' -a 'jump' -d 'Jump to any project/worktree globally (via zoxide)'
complete -c gsesh -n '__fish_use_subcommand' -a 'j' -d 'Jump to any project/worktree globally (via zoxide)'
complete -c gsesh -n '__fish_use_subcommand' -a 'new' -d 'Create new branch/worktree/session quickly'
complete -c gsesh -n '__fish_use_subcommand' -a 'n' -d 'Create new branch/worktree/session quickly'
complete -c gsesh -n '__fish_use_subcommand' -a 'attach' -d 'Attach to existing worktree/session quickly'
complete -c gsesh -n '__fish_use_subcommand' -a 'at' -d 'Attach to existing worktree/session quickly'
complete -c gsesh -n '__fish_use_subcommand' -a 'status' -d 'Show git status across all worktrees'
complete -c gsesh -n '__fish_use_subcommand' -a 'st' -d 'Show git status across all worktrees'
complete -c gsesh -n '__fish_use_subcommand' -a 'context' -d 'Show context files for current worktree'
complete -c gsesh -n '__fish_use_subcommand' -a 'completion' -d 'Generate shell completions'

# Global flags
complete -c gsesh -l debug -d 'Enable debug logging'
complete -c gsesh -l sesh -d 'Use sesh mode (zoxide-based directory switching)'
complete -c gsesh -l no-fetch -d 'Do not fetch latest branches from remote'
complete -c gsesh -l branch -d 'Specify branch name directly' -r
complete -c gsesh -l list -d 'List and switch to existing worktrees/sessions'
complete -c gsesh -l worktree-base -d 'Base directory for worktrees' -r
complete -c gsesh -l claude-prefix -d 'Prefix for Claude Code session names' -r
complete -c gsesh -l ai -d 'Start AI assistant in a split pane'
complete -c gsesh -l ai-tool -d 'AI tool to use (claude or opencode)' -xa 'claude opencode aider'
complete -c gsesh -l layout -d 'Zellij layout to use for new sessions' -r

# Command-specific flags
complete -c gsesh -n '__fish_seen_subcommand_from clean c' -l dry-run -d 'Show what would be removed'
complete -c gsesh -n '__fish_seen_subcommand_from new n' -l base -d 'Base branch to create from' -r
complete -c gsesh -n '__fish_seen_subcommand_from new n' -l ai -d 'Start AI assistant'
complete -c gsesh -n '__fish_seen_subcommand_from attach at' -l ai -d 'Start AI assistant'
complete -c gsesh -n '__fish_seen_subcommand_from jump j' -l ai -d 'Start AI assistant'

# Completion subcommands
complete -c gsesh -n '__fish_seen_subcommand_from completion' -a 'bash' -d 'Generate bash completions'
complete -c gsesh -n '__fish_seen_subcommand_from completion' -a 'zsh' -d 'Generate zsh completions'
complete -c gsesh -n '__fish_seen_subcommand_from completion' -a 'fish' -d 'Generate fish completions'

# Branch completion for new/attach
complete -c gsesh -n '__fish_seen_subcommand_from new n attach at' -a '(__fish_git_branches)'

function __fish_gsesh_layouts
    set -l layouts default compact strider
    if test -d ~/.config/zellij/layouts
        for f in ~/.config/zellij/layouts/*.kdl
            set -a layouts (basename $f .kdl)
        end
    end
    printf '%s\n' $layouts
end

complete -c gsesh -n '__fish_seen_subcommand_from new n attach at jump j' -l layout -a '(__fish_gsesh_layouts)'
`
	fmt.Println(script)
	return nil
}
