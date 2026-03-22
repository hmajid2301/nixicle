package main

import (
	"fmt"
	"os"
	"strings"

	"github.com/urfave/cli/v2"
)

func runNewMode(c *cli.Context) error {
	branchName := c.Args().First()

	// If no branch name provided, use zoxide to select project
	if branchName == "" {
		return runNewWithZoxide(c)
	}

	isRepo, err := isGitRepo()
	if err != nil {
		return err
	}
	if !isRepo {
		return fmt.Errorf("not in a git repository")
	}

	if err := validateBranchName(branchName); err != nil {
		return fmt.Errorf("invalid branch name: %w", err)
	}

	project, err := getProjectName()
	if err != nil {
		return fmt.Errorf("failed to get project name: %w", err)
	}

	return createNewBranch(branchName, project, c)
}

func runNewWithZoxide(c *cli.Context) error {
	info("Loading projects from zoxide...")

	projects, err := getZoxideProjects()
	if err != nil {
		return fmt.Errorf("failed to get projects: %w", err)
	}

	if len(projects) == 0 {
		return fmt.Errorf("no projects found in zoxide. Use 'zoxide add <dir>' to add projects")
	}

	selected, err := selectProject(projects)
	if err != nil {
		return err
	}

	if selected == nil {
		return nil
	}

	info(fmt.Sprintf("Selected: %s", selected.name))

	if !selected.isRepo {
		return fmt.Errorf("selected project is not a git repository")
	}

	// Use the existing handleGitProject from jump.go
	return handleGitProject(selected, c)
}

func createNewBranch(branchName, project string, c *cli.Context) error {
	info(fmt.Sprintf("Creating new branch: %s", branchName))

	baseBranch := c.String("base")
	if baseBranch != "" {
		if err := checkoutBaseBranch(baseBranch); err != nil {
			warning(fmt.Sprintf("Failed to checkout base branch %s: %v", baseBranch, err))
		}
	}

	worktreePath, err := getWorktreePath(branchName, project, c.String("worktree-base"))
	if err != nil {
		return fmt.Errorf("failed to get worktree path: %w", err)
	}

	sessionName := getSessionName(project, branchName)

	if worktreeExists(branchName) {
		info(fmt.Sprintf("Worktree already exists at '%s'", worktreePath))
	} else {
		info(fmt.Sprintf("Creating worktree at '%s'...", worktreePath))
		if err := createWorktree(branchName, worktreePath); err != nil {
			return fmt.Errorf("failed to create worktree: %w", err)
		}
		success(fmt.Sprintf("Worktree created at '%s'", worktreePath))
	}

	if err := createClaudeSessionHint(project, branchName, worktreePath, c.String("claude-prefix")); err != nil {
		warning("Failed to create Claude session hint")
	}

	showContextOnAttach(worktreePath)

	layout := c.String("layout")
	if layout == "" {
		var err error
		layout, err = selectLayout()
		if err != nil {
			warning(fmt.Sprintf("Failed to select layout: %v, using default", err))
			layout = "default"
		}
		if layout == "" {
			layout = "default"
		}
	}

	info(fmt.Sprintf("Creating session '%s' with layout '%s'...", sessionName, layout))
	return createSessionWithAI(sessionName, worktreePath, layout, c.Bool("ai"))
}

func runAttachMode(c *cli.Context) error {
	branchName := c.Args().First()

	// If no branch name provided, use jump mode
	if branchName == "" {
		return runJumpMode(c)
	}

	isRepo, err := isGitRepo()
	if err != nil {
		return err
	}
	if !isRepo {
		return fmt.Errorf("not in a git repository")
	}

	project, err := getProjectName()
	if err != nil {
		return fmt.Errorf("failed to get project name: %w", err)
	}

	sessionName := getSessionName(project, branchName)

	worktreePath, err := getWorktreePath(branchName, project, c.String("worktree-base"))
	if err != nil {
		return fmt.Errorf("failed to get worktree path: %w", err)
	}

	if !worktreeExists(branchName) {
		return fmt.Errorf("worktree for branch '%s' not found. Use 'gsesh new %s' to create it", branchName, branchName)
	}

	showContextOnAttach(worktreePath)

	layout := c.String("layout")
	if layout == "" {
		layout = "default"
	}

	if sessionExists(sessionName) {
		info(fmt.Sprintf("Attaching to session '%s'...", sessionName))
		return attachSessionWithAI(sessionName, worktreePath, c.Bool("ai"), layout)
	}

	info(fmt.Sprintf("Creating session '%s'...", sessionName))
	return createSessionWithAI(sessionName, worktreePath, layout, c.Bool("ai"))
}

func checkoutBaseBranch(branch string) error {
	currentDir, err := os.Getwd()
	if err != nil {
		return err
	}
	defer os.Chdir(currentDir)

	mainWorktree, err := getMainWorktree()
	if err != nil {
		return err
	}

	if err := os.Chdir(mainWorktree); err != nil {
		return err
	}

	return fetchBranches()
}

// Helper functions

func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}

func unique(slice []string) []string {
	keys := make(map[string]bool)
	var result []string
	for _, item := range slice {
		if !keys[item] {
			keys[item] = true
			result = append(result, item)
		}
	}
	return result
}

func mapSlice(slice []string, fn func(string) string) []string {
	result := make([]string, len(slice))
	for i, item := range slice {
		result[i] = fn(item)
	}
	return result
}

func filterSlice(slice []string, fn func(string) bool) []string {
	var result []string
	for _, item := range slice {
		if fn(item) {
			result = append(result, item)
		}
	}
	return result
}

func joinStrings(slice []string, sep string) string {
	return strings.Join(slice, sep)
}
