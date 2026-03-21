package main

import (
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/charmbracelet/lipgloss"
	"github.com/urfave/cli/v2"
)

var (
	statusCleanStyle = lipgloss.NewStyle().
				Foreground(lipgloss.Color("42"))

	statusDirtyStyle = lipgloss.NewStyle().
				Foreground(lipgloss.Color("214"))

	statusAheadStyle = lipgloss.NewStyle().
				Foreground(lipgloss.Color("39"))

	statusBehindStyle = lipgloss.NewStyle().
				Foreground(lipgloss.Color("208"))

	branchStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("147")).
			Bold(true)

	pathStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("241"))

	headerStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("39")).
			Bold(true).
			Padding(0, 1)
)

type WorktreeStatus struct {
	Branch     string
	Path       string
	IsClean    bool
	Modified   int
	Staged     int
	Ahead      int
	Behind     int
	Untracked  int
	HasSession bool
}

func runStatusMode(c *cli.Context) error {
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

	info("Checking worktree status...")

	mainPath, err := getMainWorktree()
	if err != nil {
		return fmt.Errorf("failed to get main worktree: %w", err)
	}

	mainStatus, err := getWorktreeStatus(mainPath, project)
	if err == nil {
		mainStatus.Branch, _ = getCurrentBranch()
	}

	worktrees, err := listWorktrees()
	if err != nil {
		return fmt.Errorf("failed to list worktrees: %w", err)
	}

	var statuses []WorktreeStatus
	if mainStatus != nil {
		statuses = append(statuses, *mainStatus)
	}

	for _, wt := range worktrees {
		status, err := getWorktreeStatus(wt.Path, project)
		if err != nil {
			continue
		}
		status.Branch = wt.Branch
		statuses = append(statuses, *status)
	}

	if len(statuses) == 0 {
		info("No worktrees found")
		return nil
	}

	fmt.Println()
	fmt.Println(headerStyle.Render(fmt.Sprintf(" Project: %s ", project)))
	fmt.Println()

	maxBranchLen := 0
	for _, s := range statuses {
		if len(s.Branch) > maxBranchLen {
			maxBranchLen = len(s.Branch)
		}
	}

	for _, s := range statuses {
		printWorktreeStatus(s, maxBranchLen)
	}

	fmt.Println()
	fmt.Printf(" Total: %d worktree(s)\n", len(statuses))

	return nil
}

func getWorktreeStatus(path, project string) (*WorktreeStatus, error) {
	status := &WorktreeStatus{
		Path: path,
	}

	currentDir, err := os.Getwd()
	if err != nil {
		return nil, err
	}
	defer os.Chdir(currentDir)

	if err := os.Chdir(path); err != nil {
		return nil, err
	}

	status.Branch, _ = getCurrentBranch()
	sessionName := getSessionName(project, status.Branch)
	status.HasSession = sessionExists(sessionName)

	cmd := exec.Command("git", "status", "--porcelain=v1")
	out, err := cmd.Output()
	if err != nil {
		return nil, err
	}

	output := strings.TrimSpace(string(out))
	if output != "" {
		lines := strings.Split(output, "\n")
		for _, line := range lines {
			if line == "" {
				continue
			}
			if len(line) < 2 {
				continue
			}

			x := line[0]
			y := line[1]

			if x == '?' && y == '?' {
				status.Untracked++
			} else if x == ' ' && y != ' ' {
				status.Modified++
			} else if x != ' ' && x != '?' {
				status.Staged++
			} else if y != ' ' && y != '?' {
				status.Modified++
			}
		}
	}

	cmd = exec.Command("git", "rev-list", "--left-right", "--count", "@{upstream}...HEAD")
	out, err = cmd.Output()
	if err == nil {
		parts := strings.Fields(strings.TrimSpace(string(out)))
		if len(parts) == 2 {
			fmt.Sscanf(parts[0], "%d", &status.Behind)
			fmt.Sscanf(parts[1], "%d", &status.Ahead)
		}
	}

	status.IsClean = status.Modified == 0 && status.Staged == 0 && status.Untracked == 0

	return status, nil
}

func printWorktreeStatus(s WorktreeStatus, maxBranchLen int) {
	branch := s.Branch
	padding := maxBranchLen - len(branch)

	var indicators []string

	if s.HasSession {
		indicators = append(indicators, statusCleanStyle.Render("●"))
	} else {
		indicators = append(indicators, statusDirtyStyle.Render("○"))
	}

	if s.IsClean {
		indicators = append(indicators, statusCleanStyle.Render("✓ clean"))
	} else {
		if s.Staged > 0 {
			indicators = append(indicators, statusCleanStyle.Render(fmt.Sprintf("+%d", s.Staged)))
		}
		if s.Modified > 0 {
			indicators = append(indicators, statusDirtyStyle.Render(fmt.Sprintf("~%d", s.Modified)))
		}
		if s.Untracked > 0 {
			indicators = append(indicators, statusDirtyStyle.Render(fmt.Sprintf("?%d", s.Untracked)))
		}
	}

	if s.Ahead > 0 {
		indicators = append(indicators, statusAheadStyle.Render(fmt.Sprintf("↑%d", s.Ahead)))
	}
	if s.Behind > 0 {
		indicators = append(indicators, statusBehindStyle.Render(fmt.Sprintf("↓%d", s.Behind)))
	}

	indicatorStr := strings.Join(indicators, " ")

	fmt.Printf("  %s%s  %s\n",
		branchStyle.Render(branch),
		strings.Repeat(" ", padding),
		indicatorStr,
	)

	relPath := s.Path
	if home, err := os.UserHomeDir(); err == nil {
		relPath = strings.Replace(s.Path, home, "~", 1)
	}
	fmt.Printf("  %s\n", pathStyle.Render(relPath))
	fmt.Println()
}
