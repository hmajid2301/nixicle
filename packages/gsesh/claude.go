package main

import (
	"fmt"
	"os"
	"path/filepath"
)

// createClaudeSessionHint creates a .claude-session-name file for Claude Code
func createClaudeSessionHint(project, branch, worktreePath, claudePrefix string) error {
	hintFile := filepath.Join(worktreePath, ".claude-session-name")

	// Check if file already exists
	if existingContent, err := os.ReadFile(hintFile); err == nil {
		existing := string(existingContent)
		if existing != "" {
			// File exists with content, don't overwrite
			return nil
		}
	}

	// Create session name with sanitization
	sanitizedProject := sanitizeName(project)
	sanitizedBranch := sanitizeName(branch)
	sessionName := claudePrefix + "-" + sanitizedProject + "-" + sanitizedBranch

	if err := os.WriteFile(hintFile, []byte(sessionName+"\n"), 0644); err != nil {
		return fmt.Errorf("failed to write Claude session hint: %w", err)
	}

	return nil
}

// readClaudeSessionHint reads the .claude-session-name file if it exists
func readClaudeSessionHint(worktreePath string) (string, error) {
	hintFile := filepath.Join(worktreePath, ".claude-session-name")
	content, err := os.ReadFile(hintFile)
	if err != nil {
		if os.IsNotExist(err) {
			return "", nil
		}
		return "", fmt.Errorf("failed to read Claude session hint: %w", err)
	}
	return string(content), nil
}
