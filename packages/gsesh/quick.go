package main

import (
	"fmt"
	"os"

	"github.com/urfave/cli/v2"
)

func runNewMode(c *cli.Context) error {
	isRepo, err := isGitRepo()
	if err != nil {
		return err
	}
	if !isRepo {
		return fmt.Errorf("not in a git repository")
	}

	branchName := c.Args().First()
	if branchName == "" {
		return fmt.Errorf("branch name required: gsesh new <branch-name>")
	}

	if err := validateBranchName(branchName); err != nil {
		return fmt.Errorf("invalid branch name: %w", err)
	}

	project, err := getProjectName()
	if err != nil {
		return fmt.Errorf("failed to get project name: %w", err)
	}

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
		layout = "default"
	}

	info(fmt.Sprintf("Creating session '%s'...", sessionName))
	return createSessionWithAI(sessionName, worktreePath, layout, c.Bool("ai"))
}

func runAttachMode(c *cli.Context) error {
	isRepo, err := isGitRepo()
	if err != nil {
		return err
	}
	if !isRepo {
		return fmt.Errorf("not in a git repository")
	}

	branchName := c.Args().First()
	if branchName == "" {
		return fmt.Errorf("branch name required: gsesh attach <branch-name>")
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
