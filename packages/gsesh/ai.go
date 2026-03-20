package main

import (
	"fmt"
	"os"
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

	debug(fmt.Sprintf("attachOrCreateWithAI: target=%q inZellij=%v currentSession=%q worktreePath=%q layout=%q startAI=%v", sessionName, inZellij, currentSession, worktreePath, layout, startAI))

	if inZellij && currentSession == sessionName {
		info(fmt.Sprintf("Already in session '%s'", sessionName))
		if startAI {
			return startAIPane()
		}
		return nil
	}

	exists := sessionExists(sessionName)
	if exists {
		info(fmt.Sprintf("Attaching to session '%s'...", sessionName))
	} else {
		info(fmt.Sprintf("Creating session '%s'...", sessionName))
	}

	if inZellij {
		info(fmt.Sprintf("Detaching from '%s' to switch...", currentSession))
		return fallbackAttachWithAI(sessionName, worktreePath, startAI, layout)
	}

	if err := os.Chdir(worktreePath); err != nil {
		return fmt.Errorf("failed to change directory: %w", err)
	}

	sessionArgs := []string{"attach", "-c", sessionName}
	if layout != "" {
		sessionArgs = []string{"--layout", layout, "attach", "-c", sessionName}
	}

	if startAI {
		return startZellijWithAI(sessionArgs)
	}

	return attachZellij(sessionArgs...)
}

func createZellijSession(sessionName, worktreePath, layout string) error {
	inZellij := os.Getenv("ZELLIJ") != ""
	currentSession := getCurrentSession()

	debug(fmt.Sprintf("createZellijSession: target=%q inZellij=%v currentSession=%q worktreePath=%q layout=%q", sessionName, inZellij, currentSession, worktreePath, layout))

	if inZellij && currentSession == sessionName {
		info(fmt.Sprintf("Already in session '%s'", sessionName))
		return nil
	}

	if inZellij {
		info(fmt.Sprintf("Switching from '%s' to new session '%s'...", currentSession, sessionName))
		return switchViaPipe(sessionName, worktreePath, layout)
	}

	if err := os.Chdir(worktreePath); err != nil {
		return fmt.Errorf("failed to change directory: %w", err)
	}

	args := []string{"attach", "-c", sessionName}
	if layout != "" {
		args = []string{"--layout", layout, "attach", "-c", sessionName}
	}

	debug(fmt.Sprintf("createZellijSession: running 'zellij %s'", strings.Join(args, " ")))
	return attachZellij(args...)
}

func fallbackAttachWithAI(sessionName, worktreePath string, startAI bool, layout string) error {
	debug(fmt.Sprintf("fallbackAttachWithAI: target=%q worktreePath=%q startAI=%v layout=%q", sessionName, worktreePath, startAI, layout))

	if err := switchViaPipe(sessionName, worktreePath, layout); err != nil {
		return err
	}

	if startAI {
		debug("fallbackAttachWithAI: starting AI pane after switch")
		return startAIPane()
	}

	return nil
}

func fallbackCreateSession(sessionName, worktreePath, layout string) error {
	debug(fmt.Sprintf("fallbackCreateSession: target=%q worktreePath=%q layout=%q", sessionName, worktreePath, layout))
	return switchViaPipe(sessionName, worktreePath, layout)
}

func startZellijWithAI(sessionArgs []string) error {
	aiTool := getAITool()
	aiCommand := buildAICommand(aiTool)

	zellijArgs := append(sessionArgs, "--", "sh", "-c", fmt.Sprintf("%s; exec $SHELL", aiCommand))

	debug(fmt.Sprintf("startZellijWithAI: running 'zellij %s'", strings.Join(zellijArgs, " ")))
	return attachZellij(zellijArgs...)
}

func startAIPane() error {
	aiTool := getAITool()
	aiCommand := buildAICommand(aiTool)

	debug(fmt.Sprintf("startAIPane: running 'zellij action new-pane -- sh -c \"%s; exec $SHELL\"'", aiCommand))
	_, err := runZellij("action", "new-pane", "--", "sh", "-c", fmt.Sprintf("%s; exec $SHELL", aiCommand))
	return err
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
