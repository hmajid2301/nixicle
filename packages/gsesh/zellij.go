package main

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"strings"
	"time"
)

// runZellij runs a zellij command, captures output, and logs it for debugging.
// Use for read-only commands (list-sessions, delete-session, action detach, etc.)
func runZellij(args ...string) (string, error) {
	debug(fmt.Sprintf("running: zellij %s", strings.Join(args, " ")))
	debug(fmt.Sprintf("  env: ZELLIJ=%q ZELLIJ_SESSION_NAME=%q", os.Getenv("ZELLIJ"), os.Getenv("ZELLIJ_SESSION_NAME")))

	cmd := exec.Command("zellij", args...)

	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	err := cmd.Run()

	outStr := stdout.String() + stderr.String()
	if outStr != "" {
		debug(fmt.Sprintf("  stdout: %q", strings.TrimSpace(stdout.String())))
		if stderr.String() != "" {
			debug(fmt.Sprintf("  stderr: %q", strings.TrimSpace(stderr.String())))
		}
	}

	if err != nil {
		debug(fmt.Sprintf("  exit: %v", err))
	} else {
		debug("  exit: success")
	}

	return outStr, err
}

// attachZellij runs a zellij attach command with terminal passthrough (stdin/stdout/stderr).
// This is required for interactive commands like attach that take over the terminal.
// Clears ZELLIJ env vars so zellij doesn't think it's already inside a session.
func attachZellij(args ...string) error {
	debug(fmt.Sprintf("attaching: zellij %s", strings.Join(args, " ")))
	debug(fmt.Sprintf("  env (before): ZELLIJ=%q ZELLIJ_SESSION_NAME=%q", os.Getenv("ZELLIJ"), os.Getenv("ZELLIJ_SESSION_NAME")))

	cmd := exec.Command("zellij", args...)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	env := os.Environ()
	var newEnv []string
	for _, e := range env {
		if !strings.HasPrefix(e, "ZELLIJ") {
			newEnv = append(newEnv, e)
		}
	}
	cmd.Env = newEnv

	hasZellijEnv := false
	for _, e := range newEnv {
		if strings.HasPrefix(e, "ZELLIJ") {
			hasZellijEnv = true
			break
		}
	}
	debug(fmt.Sprintf("  env (child): ZELLIJ env vars present: %v", hasZellijEnv))

	err := cmd.Run()
	if err != nil {
		debug(fmt.Sprintf("  attach exit: %v", err))
	} else {
		debug("  attach exit: success")
	}

	return err
}

// getSessionName returns the zellij session name for a project and branch
func getSessionName(project, branch string) string {
	// Use the sanitizeName function for consistent sanitization
	sanitizedBranch := sanitizeName(branch)
	sanitizedProject := sanitizeName(project)
	return sanitizedProject + "-" + sanitizedBranch
}

// sessionExists checks if a zellij session exists
func sessionExists(sessionName string) bool {
	out, err := runZellij("list-sessions")
	if err != nil {
		debug(fmt.Sprintf("sessionExists(%q): zellij list-sessions failed: %v", sessionName, err))
		return false
	}

	for _, line := range strings.Split(out, "\n") {
		line = strings.TrimSpace(line)
		if line == sessionName {
			debug(fmt.Sprintf("sessionExists(%q): found in sessions: %q", sessionName, strings.TrimSpace(out)))
			return true
		}
	}

	debug(fmt.Sprintf("sessionExists(%q): not found in sessions: %q", sessionName, strings.TrimSpace(out)))
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

// attachSession attaches to or creates a zellij session.
// From within zellij, uses the session-manager plugin pipe to switch.
// From outside zellij, uses direct attach.
func attachSession(sessionName, worktreePath string) error {
	inZellij := os.Getenv("ZELLIJ") != ""
	currentSession := getCurrentSession()

	debug(fmt.Sprintf("attachSession: target=%q inZellij=%v currentSession=%q worktreePath=%q", sessionName, inZellij, currentSession, worktreePath))

	// If we're already in the target session, do nothing
	if inZellij && currentSession == sessionName {
		info(fmt.Sprintf("Already in session '%s'", sessionName))
		return nil
	}

	// If we're inside zellij, use pipe to switch sessions
	if inZellij {
		info(fmt.Sprintf("Switching from '%s' to '%s'...", currentSession, sessionName))
		return switchViaPipe(sessionName, worktreePath, "")
	}

	// If not in zellij, just attach normally
	if err := os.Chdir(worktreePath); err != nil {
		return fmt.Errorf("failed to change directory to %s: %w", worktreePath, err)
	}

	debug(fmt.Sprintf("attachSession: running 'zellij attach -c %s' (not in zellij)", sessionName))
	return attachZellij("attach", "-c", sessionName)
}

// switchToSession switches to an existing zellij session.
// From within zellij, uses the session-manager plugin pipe.
// From outside zellij, uses direct attach.
func switchToSession(sessionName, workDir string) error {
	inZellij := os.Getenv("ZELLIJ") != ""
	currentSession := getCurrentSession()

	debug(fmt.Sprintf("switchToSession: target=%q inZellij=%v currentSession=%q workDir=%q", sessionName, inZellij, currentSession, workDir))

	// If we're already in the target session, do nothing
	if inZellij && currentSession == sessionName {
		info(fmt.Sprintf("Already in session '%s'", sessionName))
		return nil
	}

	// If we're inside zellij, use pipe to switch sessions
	if inZellij {
		info(fmt.Sprintf("Switching from '%s' to '%s'...", currentSession, sessionName))
		return switchViaPipe(sessionName, workDir, "")
	}

	// If not in zellij, just attach
	debug(fmt.Sprintf("switchToSession: running 'zellij attach %s' (not in zellij)", sessionName))
	return attachZellij("attach", sessionName)
}

// switchViaPipe uses zellij pipe to the session-manager plugin to create sessions,
// then uses the detach plugin to detach, and finally attaches to the new session.
func switchViaPipe(sessionName, cwd, layout string) error {
	// Step 1: Create the session via session-manager pipe
	args := fmt.Sprintf("cwd=%s,name=%s", cwd, sessionName)
	if layout != "" {
		args += fmt.Sprintf(",layout=%s", layout)
	}

	debug(fmt.Sprintf("switchViaPipe: creating session: zellij pipe -p session-manager -n switch-session --args %q", args))
	out, err := runZellij("pipe", "-p", "session-manager", "-n", "switch-session", "--args", args)

	if err != nil {
		debug(fmt.Sprintf("switchViaPipe: pipe failed: output=%q err=%v", strings.TrimSpace(out), err))
		return fmt.Errorf("pipe to session-manager failed: %w", err)
	}

	debug("switchViaPipe: session created, detaching via pipe")

	// Step 2: Detach from current session using the detach plugin
	if _, err := runZellij("pipe", "detach"); err != nil {
		debug(fmt.Sprintf("switchViaPipe: detach via pipe failed: %v, trying direct detach", err))
		// Fallback: try direct command in case plugin isn't loaded
		if _, err := runZellij("action", "detach"); err != nil {
			debug(fmt.Sprintf("switchViaPipe: all detach methods failed"))
			info(fmt.Sprintf("Session '%s' created. Switch manually with Alt+s then w", sessionName))
			return nil // not a hard error, session was created
		}
	}

	debug("switchViaPipe: detached successfully")

	if err := os.Chdir(cwd); err != nil {
		debug(fmt.Sprintf("switchViaPipe: chdir failed: %v", err))
	}

	attachArgs := []string{"attach", "-c", sessionName}
	if layout != "" {
		attachArgs = []string{"--layout", layout, "attach", "-c", sessionName}
	}

	// Retry attach — detach is async and the client may not have fully
	// disconnected before we attempt to attach to the new session.
	debug(fmt.Sprintf("switchViaPipe: attaching to new session: zellij %s", strings.Join(attachArgs, " ")))
	for i := 0; i < 5; i++ {
		time.Sleep(200 * time.Millisecond)
		err := attachZellij(attachArgs...)
		if err == nil {
			return nil
		}
		debug(fmt.Sprintf("switchViaPipe: attach attempt %d failed: %v, retrying...", i+1, err))
	}
	return attachZellij(attachArgs...)
}
