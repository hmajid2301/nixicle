package main

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
)

// isGitRepo checks if the current directory is a git repository
func isGitRepo() (bool, error) {
	cmd := exec.Command("git", "rev-parse", "--git-dir")
	err := cmd.Run()
	if err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok && exitErr.ExitCode() == 128 {
			return false, nil // Not a git repo
		}
		return false, fmt.Errorf("failed to check git repository: %w", err)
	}
	return true, nil
}

// getProjectName returns the name of the git repository
func getProjectName() (string, error) {
	topLevel, err := getMainWorktree()
	if err != nil {
		return "", err
	}
	return filepath.Base(topLevel), nil
}

// getMainWorktree returns the path to the main worktree
func getMainWorktree() (string, error) {
	cmd := exec.Command("git", "rev-parse", "--show-toplevel")
	out, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("failed to get git toplevel: %w", err)
	}
	return strings.TrimSpace(string(out)), nil
}

// sanitizeName sanitizes a string for use in session/file names
func sanitizeName(name string) string {
	// Replace slashes with dashes
	name = strings.ReplaceAll(name, "/", "-")
	// Remove or replace other problematic characters
	reg := regexp.MustCompile("[^a-zA-Z0-9-_.]")
	return reg.ReplaceAllString(name, "_")
}

// getCurrentBranch returns the current branch name
func getCurrentBranch() (string, error) {
	cmd := exec.Command("git", "rev-parse", "--abbrev-ref", "HEAD")
	out, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("failed to get current branch: %w", err)
	}
	branch := strings.TrimSpace(string(out))
	if branch == "HEAD" {
		return "", fmt.Errorf("HEAD is detached")
	}
	return branch, nil
}

// fetchBranches fetches latest branches from remote
func fetchBranches() error {
	cmd := exec.Command("git", "fetch", "--all", "--prune", "--quiet")
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to fetch branches: %w\n%s", err, stderr.String())
	}
	return nil
}

// listRemoteBranches returns a list of remote branches
func listRemoteBranches() ([]string, error) {
	cmd := exec.Command("git", "branch", "-r", "--format=%(refname:short)")
	out, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to list remote branches: %w", err)
	}

	var branches []string
	for _, line := range strings.Split(string(out), "\n") {
		line = strings.TrimSpace(line)
		if line == "" || strings.Contains(line, "HEAD") {
			continue
		}

		// Remove origin/ prefix
		branch := strings.TrimPrefix(line, "origin/")
		branches = append(branches, branch)
	}

	if len(branches) == 0 {
		return nil, fmt.Errorf("no remote branches found - try running 'git fetch' first")
	}

	return branches, nil
}

// Worktree represents a git worktree
type Worktree struct {
	Path   string
	Branch string
}

// listWorktrees returns all worktrees except the main one
func listWorktrees() ([]Worktree, error) {
	cmd := exec.Command("git", "worktree", "list", "--porcelain")
	out, err := cmd.Output()
	if err != nil {
		return nil, err
	}

	mainWorktree, err := getMainWorktree()
	if err != nil {
		return nil, err
	}

	var worktrees []Worktree
	var currentPath, currentBranch string

	for _, line := range strings.Split(string(out), "\n") {
		line = strings.TrimSpace(line)

		if strings.HasPrefix(line, "worktree ") {
			currentPath = strings.TrimPrefix(line, "worktree ")
		} else if strings.HasPrefix(line, "branch ") {
			currentBranch = strings.TrimPrefix(line, "branch ")
			currentBranch = strings.TrimPrefix(currentBranch, "refs/heads/")

			// Skip main worktree
			if currentPath != mainWorktree && currentBranch != "" {
				worktrees = append(worktrees, Worktree{
					Path:   currentPath,
					Branch: currentBranch,
				})
			}

			currentPath = ""
			currentBranch = ""
		}
	}

	return worktrees, nil
}

// worktreeExists checks if a worktree exists for a branch
func worktreeExists(branch string) bool {
	cmd := exec.Command("git", "worktree", "list")
	out, err := cmd.Output()
	if err != nil {
		return false
	}

	return strings.Contains(string(out), "["+branch+"]")
}

// getWorktreePath returns the path for a worktree
func getWorktreePath(branch, project, worktreeBase string) (string, error) {
	// Check if worktree already exists
	cmd := exec.Command("git", "worktree", "list", "--porcelain")
	out, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("failed to list worktrees: %w", err)
	}

	var currentPath string
	for _, line := range strings.Split(string(out), "\n") {
		line = strings.TrimSpace(line)

		if strings.HasPrefix(line, "worktree ") {
			currentPath = strings.TrimPrefix(line, "worktree ")
		} else if strings.HasPrefix(line, "branch ") {
			currentBranch := strings.TrimPrefix(line, "branch ")
			currentBranch = strings.TrimPrefix(currentBranch, "refs/heads/")

			if currentBranch == branch {
				return currentPath, nil
			}
		}
	}

	// Get repository root to make worktree base relative to it
	repoRoot, err := getMainWorktree()
	if err != nil {
		return "", fmt.Errorf("failed to get repository root: %w", err)
	}

	// Make worktree base absolute if it's relative
	if !filepath.IsAbs(worktreeBase) {
		worktreeBase = filepath.Join(repoRoot, worktreeBase)
	}

	// Validate worktree base exists and is a directory
	info, err := os.Stat(worktreeBase)
	if err != nil {
		if os.IsNotExist(err) {
			if err := os.MkdirAll(worktreeBase, 0755); err != nil {
				return "", fmt.Errorf("failed to create worktree base directory: %w", err)
			}
		} else {
			return "", fmt.Errorf("failed to access worktree base: %w", err)
		}
	} else if !info.IsDir() {
		return "", fmt.Errorf("worktree base %s exists but is not a directory", worktreeBase)
	}

	// Doesn't exist, return new path with sanitized branch name
	sanitizedBranch := sanitizeName(branch)
	newPath := filepath.Join(worktreeBase, sanitizedBranch)

	return newPath, nil
}

// createWorktree creates a new git worktree
func createWorktree(branch, path string) error {
	// Check if path already exists as a file
	if info, err := os.Stat(path); err == nil {
		if !info.IsDir() {
			return fmt.Errorf("path %s exists but is not a directory", path)
		}
		return fmt.Errorf("directory %s already exists", path)
	}

	// Ensure parent directory exists
	if err := os.MkdirAll(filepath.Dir(path), 0755); err != nil {
		return fmt.Errorf("failed to create parent directory: %w", err)
	}

	// Check if branch exists locally
	localCmd := exec.Command("git", "show-ref", "--verify", "--quiet", "refs/heads/"+branch)
	localExists := localCmd.Run() == nil

	// Check if branch exists remotely
	remoteCmd := exec.Command("git", "show-ref", "--verify", "--quiet", "refs/remotes/origin/"+branch)
	remoteExists := remoteCmd.Run() == nil

	var cmd *exec.Cmd
	if localExists {
		// Local branch exists
		cmd = exec.Command("git", "worktree", "add", path, branch)
	} else if remoteExists {
		// Remote branch exists, create local tracking branch
		cmd = exec.Command("git", "worktree", "add", path, "-b", branch, "origin/"+branch)
	} else {
		// New branch - create it
		cmd = exec.Command("git", "worktree", "add", path, "-b", branch)
	}

	var stderr bytes.Buffer
	cmd.Stderr = &stderr

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to create worktree: %w\nStderr: %s", err, stderr.String())
	}

	return nil
}

// removeWorktree removes a git worktree
func removeWorktree(path string) error {
	cmd := exec.Command("git", "worktree", "remove", path, "--force")
	var stderr bytes.Buffer
	cmd.Stderr = &stderr

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to remove worktree: %w\n%s", err, stderr.String())
	}

	return nil
}

// getMergedBranches returns branches that have been merged into the default branch
func getMergedBranches() ([]string, error) {
	// Get default branch
	cmd := exec.Command("git", "symbolic-ref", "refs/remotes/origin/HEAD")
	out, err := cmd.Output()
	if err != nil {
		// Fallback to main/master
		cmd = exec.Command("git", "rev-parse", "--verify", "refs/heads/main")
		if cmd.Run() == nil {
			out = []byte("refs/remotes/origin/main")
		} else {
			out = []byte("refs/remotes/origin/master")
		}
	}

	defaultBranch := strings.TrimSpace(string(out))
	defaultBranch = strings.TrimPrefix(defaultBranch, "refs/remotes/origin/")

	// Get merged branches
	cmd = exec.Command("git", "branch", "--merged", defaultBranch, "--format=%(refname:short)")
	out, err = cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to list merged branches: %w", err)
	}

	var branches []string
	for _, line := range strings.Split(string(out), "\n") {
		line = strings.TrimSpace(line)
		if line == "" || line == defaultBranch {
			continue
		}
		branches = append(branches, line)
	}

	return branches, nil
}

// validateBranchName checks if a branch name is valid
func validateBranchName(name string) error {
	if name == "" {
		return fmt.Errorf("branch name cannot be empty")
	}
	if strings.HasPrefix(name, "-") {
		return fmt.Errorf("branch name cannot start with '-'")
	}
	if strings.Contains(name, "..") {
		return fmt.Errorf("branch name cannot contain '..'")
	}
	if strings.Contains(name, "//") {
		return fmt.Errorf("branch name cannot contain '//'")
	}
	if strings.HasSuffix(name, "/") {
		return fmt.Errorf("branch name cannot end with '/'")
	}
	if strings.HasSuffix(name, ".lock") {
		return fmt.Errorf("branch name cannot end with '.lock'")
	}
	// Check for control characters
	for _, r := range name {
		if r < 32 || r == 127 {
			return fmt.Errorf("branch name cannot contain control characters")
		}
	}
	return nil
}
