package main

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
)

// getSessionName returns the zellij session name for a project and branch
func getSessionName(project, branch string) string {
	// Use the sanitizeName function for consistent sanitization
	sanitizedBranch := sanitizeName(branch)
	sanitizedProject := sanitizeName(project)
	return sanitizedProject + "-" + sanitizedBranch
}

// sessionExists checks if a zellij session exists
func sessionExists(sessionName string) bool {
	cmd := exec.Command("zellij", "list-sessions")
	out, err := cmd.Output()
	if err != nil {
		return false
	}

	for _, line := range strings.Split(string(out), "\n") {
		if strings.TrimSpace(line) == sessionName {
			return true
		}
	}

	return false
}

// listAllSessions returns all zellij sessions
func listAllSessions() ([]string, error) {
	cmd := exec.Command("zellij", "list-sessions")
	out, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to list sessions: %w", err)
	}

	var sessions []string
	for _, line := range strings.Split(string(out), "\n") {
		line = strings.TrimSpace(line)
		if line != "" {
			sessions = append(sessions, line)
		}
	}

	return sessions, nil
}

// killSession kills a zellij session
func killSession(sessionName string) error {
	cmd := exec.Command("zellij", "delete-session", sessionName)
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to kill session: %w", err)
	}
	return nil
}

// getCurrentSession returns the name of the current zellij session
func getCurrentSession() string {
	return strings.TrimSpace(os.Getenv("ZELLIJ_SESSION_NAME"))
}

// attachSession attaches to or creates a zellij session
func attachSession(sessionName, worktreePath string) error {
	inZellij := os.Getenv("ZELLIJ") != ""
	currentSession := getCurrentSession()

	// If we're already in the target session, do nothing
	if inZellij && currentSession == sessionName {
		info(fmt.Sprintf("Already in session '%s'", sessionName))
		return nil
	}

	// If we're inside zellij, use pipe to switch sessions without nesting
	if inZellij {
		info(fmt.Sprintf("Switching from '%s' to '%s'...", currentSession, sessionName))

		// Use zellij pipe to communicate with session-manager plugin
		// This avoids nesting by delegating session switching to zellij itself
		args := fmt.Sprintf("cwd=%s,name=%s", worktreePath, sessionName)
		cmd := exec.Command("zellij", "pipe", "-p", "session-manager", "-n", "switch-session", "--args", args)

		if err := cmd.Run(); err != nil {
			// Fallback to detach + attach if pipe fails
			warning("Failed to use pipe, falling back to detach + attach")
			if err := exec.Command("zellij", "action", "detach").Run(); err != nil {
				return fmt.Errorf("failed to detach from current session: %w", err)
			}

			// Change directory before attaching
			if err := os.Chdir(worktreePath); err != nil {
				return fmt.Errorf("failed to change directory to %s: %w", worktreePath, err)
			}

			cmd := exec.Command("zellij", "attach", "-c", sessionName)
			cmd.Stdin = os.Stdin
			cmd.Stdout = os.Stdout
			cmd.Stderr = os.Stderr
			return cmd.Run()
		}
		return nil
	}

	// If not in zellij, just attach normally
	if err := os.Chdir(worktreePath); err != nil {
		return fmt.Errorf("failed to change directory to %s: %w", worktreePath, err)
	}

	cmd := exec.Command("zellij", "attach", "-c", sessionName)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	return cmd.Run()
}

// switchToSession switches to an existing zellij session using pipe
func switchToSession(sessionName, workDir string) error {
	inZellij := os.Getenv("ZELLIJ") != ""
	currentSession := getCurrentSession()

	// If we're already in the target session, do nothing
	if inZellij && currentSession == sessionName {
		info(fmt.Sprintf("Already in session '%s'", sessionName))
		return nil
	}

	// If we're inside zellij, use pipe to switch
	if inZellij {
		info(fmt.Sprintf("Switching from '%s' to '%s'...", currentSession, sessionName))

		// Use zellij pipe to communicate with session-manager plugin
		args := fmt.Sprintf("cwd=%s,name=%s", workDir, sessionName)
		cmd := exec.Command("zellij", "pipe", "-p", "session-manager", "-n", "switch-session", "--args", args)

		if err := cmd.Run(); err != nil {
			// Fallback to detach + attach if pipe fails
			warning("Failed to use pipe, falling back to detach + attach")
			if err := exec.Command("zellij", "action", "detach").Run(); err != nil {
				return fmt.Errorf("failed to detach from current session: %w", err)
			}

			cmd := exec.Command("zellij", "attach", sessionName)
			cmd.Stdin = os.Stdin
			cmd.Stdout = os.Stdout
			cmd.Stderr = os.Stderr
			return cmd.Run()
		}
		return nil
	}

	// If not in zellij, just attach
	cmd := exec.Command("zellij", "attach", sessionName)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	return cmd.Run()
}
