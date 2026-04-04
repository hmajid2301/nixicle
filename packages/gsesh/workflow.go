package main

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/urfave/cli/v2"
)

func info(msg string) {
	fmt.Println(infoStyle.Render("• " + msg))
}

func success(msg string) {
	fmt.Println(successStyle.Render("✓ " + msg))
}

func warning(msg string) {
	fmt.Println(warningStyle.Render("⚠ " + msg))
}

var debugLogFile *os.File

func debug(msg string) {
	if os.Getenv("GSESH_DEBUG") == "" {
		return
	}

	if debugLogFile == nil {
		logPath := os.Getenv("GSESH_DEBUG_LOG")
		if logPath == "" {
			logPath = "/tmp/gsesh-debug.log"
		}
		var err error
		debugLogFile, err = os.OpenFile(logPath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
		if err != nil {
			return
		}
	}

	fmt.Fprintf(debugLogFile, "[%s] %s\n", fmt.Sprintf("%d", os.Getpid()), msg)
	debugLogFile.Sync()
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
	return runDefaultModeWithAI(c, project)
}

func runCleanMode(c *cli.Context) error {
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

	mergedBranches, err := getMergedBranches()
	if err != nil {
		return fmt.Errorf("failed to get merged branches: %w", err)
	}

	if len(mergedBranches) == 0 {
		success("No merged branches found")
		return nil
	}

	worktrees, err := listWorktrees()
	if err != nil {
		return fmt.Errorf("failed to list worktrees: %w", err)
	}

	var mergedWorktrees []multiSelectItem
	var worktreePaths []string

	for _, worktree := range worktrees {
		isMerged := false
		for _, merged := range mergedBranches {
			if worktree.Branch == merged {
				isMerged = true
				break
			}
		}

		if isMerged {
			mergedWorktrees = append(mergedWorktrees, multiSelectItem{
				title:       worktree.Branch,
				description: worktree.Path,
				selected:    true,
				value:       worktree.Branch,
			})
			worktreePaths = append(worktreePaths, worktree.Path)
		}
	}

	if len(mergedWorktrees) == 0 {
		success("No merged worktrees to clean")
		return nil
	}

	info(fmt.Sprintf("Found %d merged worktree(s)", len(mergedWorktrees)))

	selected, err := runMultiSelect("Select worktrees to remove", mergedWorktrees)
	if err != nil {
		return err
	}

	if len(selected) == 0 {
		info("No worktrees selected for removal")
		return nil
	}

	if !dryRun {
		confirmed, err := runConfirmDialog(
			"Confirm Removal",
			fmt.Sprintf("Remove %d worktree(s)? This cannot be undone.", len(selected)),
		)
		if err != nil {
			return err
		}
		if !confirmed {
			info("Operation cancelled")
			return nil
		}
	}

	var removedCount int
	for i, branch := range selected {
		if dryRun {
			info(fmt.Sprintf("Would remove worktree: %s (%s)", branch, worktreePaths[i]))
			removedCount++
			continue
		}

		info(fmt.Sprintf("Removing worktree: %s", branch))
		if err := removeWorktree(worktreePaths[i]); err != nil {
			warning(fmt.Sprintf("Failed to remove %s: %v", branch, err))
			continue
		}

		sessionName := getSessionName(filepath.Base(worktreePaths[i]), branch)
		if sessionExists(sessionName) {
			if err := killSession(sessionName); err != nil {
				warning(fmt.Sprintf("Failed to kill session %s: %v", sessionName, err))
			} else {
				info(fmt.Sprintf("Killed session: %s", sessionName))
			}
		}

		success(fmt.Sprintf("Removed worktree: %s", branch))
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
