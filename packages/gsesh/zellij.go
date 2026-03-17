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
	cmd := exec.Command("zellij", "list-sessions", "-s")
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

	// If we're inside zellij, detach and print instructions
	if inZellij {
		info(fmt.Sprintf("Switching from '%s' to '%s'...", currentSession, sessionName))
		info("Detaching - run 'zellij attach " + sessionName + "' to connect")

		// Detach from current session
		if err := exec.Command("zellij", "action", "detach").Run(); err != nil {
			return fmt.Errorf("failed to detach from current session: %w", err)
		}

		// After detach, we're outside zellij - attach to target
		if err := os.Chdir(worktreePath); err != nil {
			return fmt.Errorf("failed to change directory to %s: %w", worktreePath, err)
		}

		cmd := exec.Command("zellij", "attach", "-c", sessionName)
		cmd.Stdin = os.Stdin
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		return cmd.Run()
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

// switchToSession switches to an existing zellij session
func switchToSession(sessionName, workDir string) error {
	inZellij := os.Getenv("ZELLIJ") != ""
	currentSession := getCurrentSession()

	// If we're already in the target session, do nothing
	if inZellij && currentSession == sessionName {
		info(fmt.Sprintf("Already in session '%s'", sessionName))
		return nil
	}

	// If we're inside zellij, detach then attach
	if inZellij {
		info(fmt.Sprintf("Switching from '%s' to '%s'...", currentSession, sessionName))

		// Detach from current session
		if err := exec.Command("zellij", "action", "detach").Run(); err != nil {
			return fmt.Errorf("failed to detach from current session: %w", err)
		}

		// After detach, attach to target
		if workDir != "" {
			if err := os.Chdir(workDir); err != nil {
				return fmt.Errorf("failed to change directory: %w", err)
			}
		}

		cmd := exec.Command("zellij", "attach", sessionName)
		cmd.Stdin = os.Stdin
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		return cmd.Run()
	}

	// If not in zellij, just attach
	cmd := exec.Command("zellij", "attach", sessionName)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	return cmd.Run()
}
