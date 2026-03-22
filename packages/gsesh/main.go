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
	// Check for --debug in args before CLI parsing so debug works anywhere
	for _, arg := range os.Args {
		if arg == "--debug" || arg == "-d" {
			os.Setenv("GSESH_DEBUG", "1")
			break
		}
	}

	app := &cli.App{
		Name:                 "gsesh",
		Usage:                "Git session manager for worktrees + zellij",
		Version:              version,
		EnableBashCompletion: true,
		Flags: []cli.Flag{
			&cli.BoolFlag{
				Name:    "debug",
				Aliases: []string{"d"},
				EnvVars: []string{"GSESH_DEBUG"},
				Usage:   "Enable debug logging to /tmp/gsesh-debug.log",
			},
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
				Value:   ".worktrees",
				Usage:   "Base directory for worktrees (relative to repo root)",
			},
			&cli.StringFlag{
				Name:    "claude-prefix",
				EnvVars: []string{"CLAUDE_CODE_SESSION_PREFIX"},
				Value:   "claude",
				Usage:   "Prefix for Claude Code session names",
			},
			&cli.BoolFlag{
				Name:    "ai",
				Aliases: []string{"a"},
				Usage:   "Start AI assistant (claude/opencode) in a split pane",
			},
			&cli.StringFlag{
				Name:    "ai-tool",
				EnvVars: []string{"GSESH_AI_TOOL"},
				Value:   "opencode",
				Usage:   "AI tool to use (claude or opencode)",
			},
			&cli.StringFlag{
				Name:    "layout",
				Aliases: []string{"L"},
				Usage:   "Zellij layout to use for new sessions",
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
			{
				Name:    "jump",
				Aliases: []string{"j"},
				Usage:   "Jump to any project/worktree globally (via zoxide)",
				Flags: []cli.Flag{
					&cli.BoolFlag{
						Name:    "ai",
						Aliases: []string{"a"},
						Usage:   "Start AI assistant in a split pane",
					},
				},
				Action: runJumpMode,
			},
			{
				Name:      "new",
				Aliases:   []string{"n"},
				Usage:     "Create new branch/worktree/session quickly",
				ArgsUsage: "<branch-name>",
				Flags: []cli.Flag{
					&cli.BoolFlag{
						Name:    "ai",
						Aliases: []string{"a"},
						Usage:   "Start AI assistant in a split pane",
					},
					&cli.StringFlag{
						Name:    "base",
						Aliases: []string{"B"},
						Usage:   "Base branch to create from",
						Value:   "",
					},
				},
				Action: runNewMode,
			},
			{
				Name:      "attach",
				Aliases:   []string{"at"},
				Usage:     "Attach to existing worktree/session quickly",
				ArgsUsage: "<branch-name>",
				Flags: []cli.Flag{
					&cli.BoolFlag{
						Name:    "ai",
						Aliases: []string{"a"},
						Usage:   "Start AI assistant in a split pane",
					},
				},
				Action: runAttachMode,
			},
			{
				Name:    "status",
				Aliases: []string{"st"},
				Usage:   "Show git status across all worktrees",
				Action:  runStatusMode,
			},
			{
				Name:   "context",
				Usage:  "Show context files for current worktree",
				Action: runContextMode,
			},
			{
				Name:    "dashboard",
				Aliases: []string{"d"},
				Usage:   "Interactive TUI dashboard",
				Action:  runDashboard,
			},
			{
				Name:    "pr",
				Aliases: []string{"p"},
				Usage:   "Checkout GitHub PRs",
				Action:  runPRMode,
			},
			{
				Name:    "kill",
				Aliases: []string{"k"},
				Usage:   "Kill zellij sessions",
				Action:  runKillMode,
			},
			{
				Name:  "config",
				Usage: "Manage gsesh configuration",
				Subcommands: []*cli.Command{
					{
						Name:   "show",
						Usage:  "Show current configuration",
						Action: runConfigShowCmd,
					},
					{
						Name:   "edit",
						Usage:  "Edit configuration file",
						Action: runConfigEditCmd,
					},
				},
			},
			{
				Name:  "branch",
				Usage: "Manage git branches",
				Subcommands: []*cli.Command{
					{
						Name:      "create",
						Usage:     "Create a new branch",
						ArgsUsage: "<branch-name>",
						Action:    runBranchCreate,
					},
					{
						Name:      "delete",
						Usage:     "Delete branches",
						ArgsUsage: "<branch-name>",
						Flags: []cli.Flag{
							&cli.BoolFlag{
								Name:    "force",
								Aliases: []string{"f"},
								Usage:   "Force delete",
							},
						},
						Action: runBranchDelete,
					},
					{
						Name:      "merge",
						Usage:     "Merge a branch into current",
						ArgsUsage: "<branch-name>",
						Action:    runBranchMerge,
					},
					{
						Name:  "list",
						Usage: "List branches",
						Flags: []cli.Flag{
							&cli.BoolFlag{
								Name:    "remote",
								Aliases: []string{"r"},
								Usage:   "List remote branches",
							},
						},
						Action: runBranchList,
					},
				},
			},
			{
				Name:  "session",
				Usage: "Manage zellij sessions",
				Subcommands: []*cli.Command{
					{
						Name:   "kill",
						Usage:  "Kill sessions",
						Action: runKillMode,
					},
					{
						Name:      "rename",
						Usage:     "Rename a session",
						ArgsUsage: "<old-name> <new-name>",
						Action:    runRenameSession,
					},
				},
			},
			{
				Name:  "completion",
				Usage: "Generate shell completions",
				Subcommands: []*cli.Command{
					{
						Name:   "bash",
						Usage:  "Generate bash completions",
						Action: generateBashCompletion,
					},
					{
						Name:   "zsh",
						Usage:  "Generate zsh completions",
						Action: generateZshCompletion,
					},
					{
						Name:   "fish",
						Usage:  "Generate fish completions",
						Action: generateFishCompletion,
					},
				},
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
