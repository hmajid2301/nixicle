package main

import (
	"fmt"
	"path/filepath"

	"github.com/charmbracelet/lipgloss"
	"github.com/urfave/cli/v2"
)

var (
	infoStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("39")).
			Bold(true)

	successStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("42")).
			Bold(true)

	errorStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("196")).
			Bold(true)
)

func info(msg string) {
	fmt.Println(infoStyle.Render("• " + msg))
}

func success(msg string) {
	fmt.Println(successStyle.Render("✓ " + msg))
}

func warning(msg string) {
	fmt.Println(errorStyle.Render("⚠ " + msg))
}

func runListMode(c *cli.Context, project string) error {
	info("Loading existing worktrees...")

	// Get all worktrees
	worktrees, err := listWorktrees()
	if err != nil {
		return fmt.Errorf("failed to list worktrees: %w", err)
	}

	// Select worktree
	selected, err := selectWorktree(worktrees, project)
	if err != nil {
		return err
	}

	if selected == nil {
		return fmt.Errorf("no worktree selected")
	}

	info(fmt.Sprintf("Selected: %s", selected.branch))

	// Attach to session
	if err := attachSession(selected.sessionName, selected.path); err != nil {
		return fmt.Errorf("failed to attach to session: %w", err)
	}

	return nil
}

func runDefaultMode(c *cli.Context, project string) error {
	var branch string

	// Check if branch was specified via flag
	if c.String("branch") != "" {
		branch = c.String("branch")
		// Validate branch name
		if err := validateBranchName(branch); err != nil {
			return fmt.Errorf("invalid branch name: %w", err)
		}
	} else {
		// Fetch branches if needed
		if !c.Bool("no-fetch") {
			info("Fetching latest branches from remote...")
			if err := fetchBranches(); err != nil {
				warning("Failed to fetch from remote - using local branch data")
			}
		}

		// Get current branch
		currentBranch, err := getCurrentBranch()
		if err != nil {
			currentBranch = ""
		}

		// Get remote branches
		branches, err := listRemoteBranches()
		if err != nil {
			return fmt.Errorf("failed to list branches: %w", err)
		}

		if len(branches) == 0 {
			return fmt.Errorf("no branches found")
		}

		// Interactive branch selection
		selectedBranch, err := selectBranch(branches, currentBranch)
		if err != nil {
			return err
		}

		if selectedBranch == "" {
			return fmt.Errorf("no branch selected")
		}

		branch = selectedBranch
	}

	info(fmt.Sprintf("Selected branch: %s", branch))

	// Get worktree path
	worktreePath, err := getWorktreePath(branch, project, c.String("worktree-base"))
	if err != nil {
		return fmt.Errorf("failed to get worktree path: %w", err)
	}

	// Get session name
	sessionName := getSessionName(project, branch)

	// Check if session already exists
	if sessionExists(sessionName) {
		info(fmt.Sprintf("Session '%s' already exists. Attaching...", sessionName))
		return attachSession(sessionName, worktreePath)
	}

	// Create worktree if it doesn't exist
	if !worktreeExists(branch) {
		info(fmt.Sprintf("Creating worktree at '%s'...", worktreePath))
		if err := createWorktree(branch, worktreePath); err != nil {
			return fmt.Errorf("failed to create worktree: %w", err)
		}
		success(fmt.Sprintf("Worktree created at '%s'", worktreePath))
	} else {
		info(fmt.Sprintf("Worktree already exists at '%s'", worktreePath))
	}

	// Create Claude Code session hint
	if err := createClaudeSessionHint(project, branch, worktreePath, c.String("claude-prefix")); err != nil {
		warning("Failed to create Claude session hint")
	} else {
		claudeSession := c.String("claude-prefix") + "-" + sanitizeName(project) + "-" + sanitizeName(branch)
		info(fmt.Sprintf("Claude Code session: %s", claudeSession))
	}

	// Attach to session
	info(fmt.Sprintf("Creating session '%s'...", sessionName))
	if err := attachSession(sessionName, worktreePath); err != nil {
		return fmt.Errorf("failed to attach to session: %w", err)
	}

	return nil
}

func runCleanMode(c *cli.Context) error {
	// Check if we're in a git repository
	isRepo, err := isGitRepo()
	if err != nil {
		return err
	}
	if !isRepo {
		return fmt.Errorf("not in a git repository")
	}

	dryRun := c.Bool("dry-run")

	if dryRun {
		info("Running in dry-run mode (no changes will be made)")
	}

	info("Finding merged branches...")

	// Get merged branches
	mergedBranches, err := getMergedBranches()
	if err != nil {
		return fmt.Errorf("failed to get merged branches: %w", err)
	}

	if len(mergedBranches) == 0 {
		success("No merged branches found")
		return nil
	}

	// Get all worktrees
	worktrees, err := listWorktrees()
	if err != nil {
		return fmt.Errorf("failed to list worktrees: %w", err)
	}

	var removedCount int
	for _, worktree := range worktrees {
		// Check if worktree branch is merged
		isMerged := false
		for _, merged := range mergedBranches {
			if worktree.Branch == merged {
				isMerged = true
				break
			}
		}

		if !isMerged {
			continue
		}

		if dryRun {
			info(fmt.Sprintf("Would remove worktree: %s (%s)", worktree.Branch, worktree.Path))
		} else {
			info(fmt.Sprintf("Removing worktree: %s", worktree.Branch))
			if err := removeWorktree(worktree.Path); err != nil {
				warning(fmt.Sprintf("Failed to remove %s: %v", worktree.Branch, err))
				continue
			}

			// Also kill associated session if it exists
			sessionName := getSessionName(filepath.Base(worktree.Path), worktree.Branch)
			if sessionExists(sessionName) {
				if err := killSession(sessionName); err != nil {
					warning(fmt.Sprintf("Failed to kill session %s: %v", sessionName, err))
				} else {
					info(fmt.Sprintf("Killed session: %s", sessionName))
				}
			}

			success(fmt.Sprintf("Removed worktree: %s", worktree.Branch))
		}
		removedCount++
	}

	if removedCount == 0 {
		success("No worktrees to clean")
	} else if dryRun {
		info(fmt.Sprintf("Would remove %d worktree(s)", removedCount))
	} else {
		success(fmt.Sprintf("Removed %d worktree(s)", removedCount))
	}

	return nil
}

func runSessionsMode(c *cli.Context) error {
	info("Listing all zellij sessions...")

	// Get all sessions
	sessions, err := listAllSessions()
	if err != nil {
		return fmt.Errorf("failed to list sessions: %w", err)
	}

	if len(sessions) == 0 {
		info("No active zellij sessions")
		return nil
	}

	// Get all worktrees to check which sessions have associated worktrees
	var worktrees []Worktree
	isRepo, _ := isGitRepo()
	if isRepo {
		worktrees, _ = listWorktrees()
	}

	fmt.Println("\nActive Sessions:")
	fmt.Println("================")

	for _, session := range sessions {
		hasWorktree := false
		for _, wt := range worktrees {
			if session == getSessionName(filepath.Base(wt.Path), wt.Branch) {
				hasWorktree = true
				fmt.Printf("%s %s (worktree: %s)\n", successStyle.Render("✓"), session, wt.Path)
				break
			}
		}

		if !hasWorktree {
			fmt.Printf("  %s (no worktree)\n", session)
		}
	}

	fmt.Printf("\nTotal: %d session(s)\n", len(sessions))

	return nil
}

// SessionInfo represents a zellij session with optional worktree path
type SessionInfo struct {
	Name string
	Path string
}

func runSwitchMode(c *cli.Context) error {
	info("Loading available sessions...")

	// Get all zellij sessions
	sessions, err := listAllSessions()
	if err != nil {
		return fmt.Errorf("failed to list sessions: %w", err)
	}

	if len(sessions) == 0 {
		warning("No active zellij sessions found")
		return nil
	}

	// Get all worktrees to find associated paths
	worktrees, _ := listWorktrees()

	var sessionList []SessionInfo
	for _, session := range sessions {
		si := SessionInfo{Name: session}

		// Try to find associated worktree
		for _, wt := range worktrees {
			expectedSession := getSessionName(filepath.Base(wt.Path), wt.Branch)
			if session == expectedSession {
				si.Path = wt.Path
				break
			}
		}

		sessionList = append(sessionList, si)
	}

	// Use UI to select session
	selected, err := selectSession(sessionList)
	if err != nil {
		return err
	}

	if selected.Name == "" {
		return nil
	}

	// Determine working directory
	workDir := selected.Path
	if workDir == "" {
		// Default to current directory if no worktree found
		workDir = "."
	}

	// Switch to the session using pipe
	return switchToSession(selected.Name, workDir)
}
