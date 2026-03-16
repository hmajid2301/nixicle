package main

import (
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/urfave/cli/v2"
)

func attachSessionWithAI(sessionName, worktreePath string, startAI bool, layout string) error {
	if startAI {
		return attachOrCreateWithAI(sessionName, worktreePath, layout, true)
	}
	return attachSession(sessionName, worktreePath)
}

func createSessionWithAI(sessionName, worktreePath, layout string, startAI bool) error {
	if startAI {
		return attachOrCreateWithAI(sessionName, worktreePath, layout, true)
	}
	return createZellijSession(sessionName, worktreePath, layout)
}

func attachOrCreateWithAI(sessionName, worktreePath, layout string, startAI bool) error {
	inZellij := os.Getenv("ZELLIJ") != ""
	currentSession := getCurrentSession()

	if inZellij && currentSession == sessionName {
		info(fmt.Sprintf("Already in session '%s'", sessionName))
		if startAI {
			return startAIPane()
		}
		return nil
	}

	if sessionExists(sessionName) {
		info(fmt.Sprintf("Attaching to session '%s' with AI...", sessionName))
	} else {
		info(fmt.Sprintf("Creating session '%s' with AI...", sessionName))
	}

	if inZellij {
		args := fmt.Sprintf("cwd=%s,name=%s", worktreePath, sessionName)
		if layout != "" && layout != "default" {
			args += fmt.Sprintf(",layout=%s", layout)
		}

		cmd := exec.Command("zellij", "pipe", "-p", "session-manager", "-n", "switch-session", "--args", args)
		if err := cmd.Run(); err != nil {
			warning("Pipe failed, using fallback")
			return fallbackAttachWithAI(sessionName, worktreePath, startAI)
		}

		if startAI {
			return startAIPane()
		}
		return nil
	}

	if err := os.Chdir(worktreePath); err != nil {
		return fmt.Errorf("failed to change directory: %w", err)
	}

	sessionArgs := []string{"attach", "-c", sessionName}
	if layout != "" && layout != "default" {
		sessionArgs = []string{"--layout", layout, "attach", "-c", sessionName}
	}

	if startAI {
		return startZellijWithAI(sessionArgs)
	}

	cmd := exec.Command("zellij", sessionArgs...)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func createZellijSession(sessionName, worktreePath, layout string) error {
	inZellij := os.Getenv("ZELLIJ") != ""
	currentSession := getCurrentSession()

	if inZellij && currentSession == sessionName {
		info(fmt.Sprintf("Already in session '%s'", sessionName))
		return nil
	}

	if inZellij {
		info(fmt.Sprintf("Creating session '%s'...", sessionName))

		args := fmt.Sprintf("cwd=%s,name=%s", worktreePath, sessionName)
		if layout != "" && layout != "default" {
			args += fmt.Sprintf(",layout=%s", layout)
		}

		cmd := exec.Command("zellij", "pipe", "-p", "session-manager", "-n", "switch-session", "--args", args)
		if err := cmd.Run(); err != nil {
			warning("Pipe failed, using fallback")
			return fallbackCreateSession(sessionName, worktreePath, layout)
		}
		return nil
	}

	if err := os.Chdir(worktreePath); err != nil {
		return fmt.Errorf("failed to change directory: %w", err)
	}

	args := []string{"attach", "-c", sessionName}
	if layout != "" && layout != "default" {
		args = []string{"--layout", layout, "attach", "-c", sessionName}
	}

	cmd := exec.Command("zellij", args...)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func fallbackAttachWithAI(sessionName, worktreePath string, startAI bool) error {
	if err := exec.Command("zellij", "action", "detach").Run(); err != nil {
		return fmt.Errorf("failed to detach: %w", err)
	}

	if err := os.Chdir(worktreePath); err != nil {
		return fmt.Errorf("failed to change directory: %w", err)
	}

	if startAI {
		return startZellijWithAI([]string{"attach", "-c", sessionName})
	}

	cmd := exec.Command("zellij", "attach", "-c", sessionName)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func fallbackCreateSession(sessionName, worktreePath, layout string) error {
	if err := exec.Command("zellij", "action", "detach").Run(); err != nil {
		return fmt.Errorf("failed to detach: %w", err)
	}

	if err := os.Chdir(worktreePath); err != nil {
		return fmt.Errorf("failed to change directory: %w", err)
	}

	args := []string{"attach", "-c", sessionName}
	if layout != "" && layout != "default" {
		args = []string{"--layout", layout, "attach", "-c", sessionName}
	}

	cmd := exec.Command("zellij", args...)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func startZellijWithAI(sessionArgs []string) error {
	aiTool := getAITool()
	aiCommand := buildAICommand(aiTool)

	zellijArgs := append(sessionArgs, "--", "sh", "-c", fmt.Sprintf("%s; exec $SHELL", aiCommand))

	cmd := exec.Command("zellij", zellijArgs...)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func startAIPane() error {
	aiTool := getAITool()
	aiCommand := buildAICommand(aiTool)

	cmd := exec.Command("zellij", "action", "new-pane", "--", "sh", "-c", fmt.Sprintf("%s; exec $SHELL", aiCommand))
	return cmd.Run()
}

func getAITool() string {
	tool := os.Getenv("GSESH_AI_TOOL")
	if tool == "" {
		tool = "opencode"
	}
	return tool
}

func buildAICommand(tool string) string {
	switch strings.ToLower(tool) {
	case "claude":
		return "claude"
	case "opencode":
		return "opencode"
	case "aider":
		return "aider"
	case "cursor":
		return "cursor ."
	default:
		return tool
	}
}

func runDefaultModeWithAI(c *cli.Context, project string) error {
	var branch string

	if c.String("branch") != "" {
		branch = c.String("branch")
		if err := validateBranchName(branch); err != nil {
			return fmt.Errorf("invalid branch name: %w", err)
		}
	} else {
		if !c.Bool("no-fetch") {
			info("Fetching latest branches from remote...")
			if err := fetchBranches(); err != nil {
				warning("Failed to fetch from remote - using local branch data")
			}
		}

		currentBranch, err := getCurrentBranch()
		if err != nil {
			currentBranch = ""
		}

		branches, err := listRemoteBranches()
		if err != nil {
			return fmt.Errorf("failed to list branches: %w", err)
		}

		if len(branches) == 0 {
			return fmt.Errorf("no branches found")
		}

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

	worktreePath, err := getWorktreePath(branch, project, c.String("worktree-base"))
	if err != nil {
		return fmt.Errorf("failed to get worktree path: %w", err)
	}

	sessionName := getSessionName(project, branch)

	if sessionExists(sessionName) {
		info(fmt.Sprintf("Session '%s' already exists. Attaching...", sessionName))
		return attachSessionWithAI(sessionName, worktreePath, c.Bool("ai"), c.String("layout"))
	}

	if !worktreeExists(branch) {
		info(fmt.Sprintf("Creating worktree at '%s'...", worktreePath))
		if err := createWorktree(branch, worktreePath); err != nil {
			return fmt.Errorf("failed to create worktree: %w", err)
		}
		success(fmt.Sprintf("Worktree created at '%s'", worktreePath))
	} else {
		info(fmt.Sprintf("Worktree already exists at '%s'", worktreePath))
	}

	if err := createClaudeSessionHint(project, branch, worktreePath, c.String("claude-prefix")); err != nil {
		warning("Failed to create Claude session hint")
	} else {
		claudeSession := c.String("claude-prefix") + "-" + sanitizeName(project) + "-" + sanitizeName(branch)
		info(fmt.Sprintf("Claude Code session: %s", claudeSession))
	}

	showContextOnAttach(worktreePath)

	layout := c.String("layout")
	if layout == "" {
		layout = "default"
	}

	info(fmt.Sprintf("Creating session '%s'...", sessionName))
	return createSessionWithAI(sessionName, worktreePath, layout, c.Bool("ai"))
}
