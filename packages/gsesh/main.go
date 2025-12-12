package main

import (
	"fmt"
	"os"

	"github.com/urfave/cli/v2"
)

var (
	version = "dev"
)

func main() {
	app := &cli.App{
		Name:                 "gsesh",
		Usage:                "Git session manager for worktrees + zellij",
		Version:              version,
		EnableBashCompletion: true,
		Flags: []cli.Flag{
			&cli.BoolFlag{
				Name:    "sesh",
				Aliases: []string{"s"},
				Usage:   "Use sesh mode (zoxide-based directory switching)",
			},
			&cli.BoolFlag{
				Name:    "no-fetch",
				Aliases: []string{"n"},
				Usage:   "Don't fetch latest branches from remote",
			},
			&cli.StringFlag{
				Name:    "branch",
				Aliases: []string{"b"},
				Usage:   "Specify branch name directly (skip interactive selection)",
			},
			&cli.BoolFlag{
				Name:    "list",
				Aliases: []string{"l"},
				Usage:   "List and switch to existing worktrees/sessions",
			},
			&cli.StringFlag{
				Name:    "worktree-base",
				EnvVars: []string{"WORKTREE_BASE"},
				Value:   os.Getenv("HOME") + "/worktrees",
				Usage:   "Base directory for worktrees",
			},
			&cli.StringFlag{
				Name:    "claude-prefix",
				EnvVars: []string{"CLAUDE_CODE_SESSION_PREFIX"},
				Value:   "claude",
				Usage:   "Prefix for Claude Code session names",
			},
		},
		Commands: []*cli.Command{
			{
				Name:    "clean",
				Aliases: []string{"c"},
				Usage:   "Clean up worktrees for merged/deleted branches",
				Flags: []cli.Flag{
					&cli.BoolFlag{
						Name:    "dry-run",
						Aliases: []string{"d"},
						Usage:   "Show what would be removed without actually removing",
					},
				},
				Action: runCleanMode,
			},
			{
				Name:    "sessions",
				Aliases: []string{"ss"},
				Usage:   "List all zellij sessions and their status",
				Action:  runSessionsMode,
			},
			{
				Name:    "switch",
				Aliases: []string{"sw"},
				Usage:   "Switch to a zellij session using interactive UI",
				Action:  runSwitchMode,
			},
		},
		Action: run,
	}

	if err := app.Run(os.Args); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}

func run(c *cli.Context) error {
	// Sesh mode - zoxide-based directory switching
	if c.Bool("sesh") {
		return runSeshMode(c)
	}

	// Check if we're in a git repository
	isRepo, err := isGitRepo()
	if err != nil {
		return err
	}
	if !isRepo {
		return fmt.Errorf("not in a git repository - run 'git init' or cd to a git repository")
	}

	// Get project name
	project, err := getProjectName()
	if err != nil {
		return fmt.Errorf("failed to get project name: %w", err)
	}

	// List mode - select from existing worktrees
	if c.Bool("list") {
		return runListMode(c, project)
	}

	// Default mode - create/switch to branch
	return runDefaultMode(c, project)
}
