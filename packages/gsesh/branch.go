package main

import (
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/charmbracelet/bubbles/list"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/urfave/cli/v2"
)

func runBranchCreate(c *cli.Context) error {
	branchName := c.Args().First()

	if branchName == "" {
		var err error
		branchName, err = runTextInput(
			"Enter new branch name",
			"feature/",
			validateBranchName,
		)
		if err != nil {
			return err
		}
		if branchName == "" {
			return nil
		}
	}

	if err := validateBranchName(branchName); err != nil {
		return err
	}

	project, err := getProjectName()
	if err != nil {
		return err
	}

	return createNewBranch(branchName, project, c)
}

func runBranchDelete(c *cli.Context) error {
	branchName := c.Args().First()
	force := c.Bool("force")

	if branchName == "" {
		branches, err := listLocalBranches()
		if err != nil {
			return err
		}

		currentBranch, _ := getCurrentBranch()
		var items []multiSelectItem
		for _, b := range branches {
			if b == currentBranch {
				continue
			}
			items = append(items, multiSelectItem{
				title:       b,
				description: "",
				selected:    false,
				value:       b,
			})
		}

		if len(items) == 0 {
			info("No branches to delete")
			return nil
		}

		selected, err := runMultiSelect("Select branches to delete", items)
		if err != nil {
			return err
		}

		if len(selected) == 0 {
			info("No branches selected")
			return nil
		}

		for _, branch := range selected {
			if err := deleteBranch(branch, force); err != nil {
				warning(fmt.Sprintf("Failed to delete %s: %v", branch, err))
			} else {
				success(fmt.Sprintf("Deleted branch: %s", branch))
			}
		}

		return nil
	}

	return deleteBranch(branchName, force)
}

func deleteBranch(branchName string, force bool) error {
	currentBranch, _ := getCurrentBranch()
	if branchName == currentBranch {
		return fmt.Errorf("cannot delete current branch '%s'", branchName)
	}

	args := []string{"branch"}
	if force {
		args = append(args, "-D")
	} else {
		args = append(args, "-d")
	}
	args = append(args, branchName)

	cmd := exec.Command("git", args...)
	if out, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("%s", strings.TrimSpace(string(out)))
	}

	return nil
}

func runBranchMerge(c *cli.Context) error {
	branchName := c.Args().First()

	if branchName == "" {
		branches, err := listLocalBranches()
		if err != nil {
			return err
		}

		currentBranch, _ := getCurrentBranch()
		var items []list.Item
		for _, b := range branches {
			if b == currentBranch {
				continue
			}
			items = append(items, branchSelectItem{name: b})
		}

		selected, err := selectBranchFromList(items)
		if err != nil {
			return err
		}

		if selected == "" {
			return nil
		}

		branchName = selected
	}

	info(fmt.Sprintf("Merging branch '%s' into current branch...", branchName))

	cmd := exec.Command("git", "merge", branchName)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("merge failed: %w", err)
	}

	success(fmt.Sprintf("Merged branch '%s'", branchName))
	return nil
}

func runBranchList(c *cli.Context) error {
	remote := c.Bool("remote")

	var branches []string
	var err error

	if remote {
		branches, err = listRemoteBranches()
	} else {
		branches, err = listLocalBranches()
	}

	if err != nil {
		return err
	}

	currentBranch, _ := getCurrentBranch()

	for _, b := range branches {
		if b == currentBranch {
			fmt.Println(selectedStyle.Render("* " + b))
		} else {
			fmt.Println("  " + b)
		}
	}

	return nil
}

func listLocalBranches() ([]string, error) {
	cmd := exec.Command("git", "branch", "--format", "%(refname:short)")
	out, err := cmd.Output()
	if err != nil {
		return nil, err
	}

	var branches []string
	for _, line := range strings.Split(string(out), "\n") {
		line = strings.TrimSpace(line)
		if line != "" {
			branches = append(branches, line)
		}
	}

	return branches, nil
}

type branchSelectItem struct {
	name string
}

func (i branchSelectItem) FilterValue() string { return i.name }
func (i branchSelectItem) Title() string       { return i.name }
func (i branchSelectItem) Description() string { return "" }

func selectBranchFromList(items []list.Item) (string, error) {
	l := list.New(items, list.NewDefaultDelegate(), 0, 0)
	l.Title = "Select a branch"
	l.SetShowStatusBar(false)
	l.SetFilteringEnabled(true)
	l.Styles.Title = titleStyle

	m := branchSelectModel{list: l}
	p := tea.NewProgram(m, tea.WithAltScreen())
	finalModel, err := p.Run()
	if err != nil {
		return "", err
	}

	if m, ok := finalModel.(branchSelectModel); ok {
		return m.choice, nil
	}

	return "", fmt.Errorf("unexpected model type")
}

type branchSelectModel struct {
	list     list.Model
	choice   string
	quitting bool
}

func (m branchSelectModel) Init() tea.Cmd { return nil }

func (m branchSelectModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c", "q", "esc":
			m.quitting = true
			return m, tea.Quit

		case "enter":
			if i, ok := m.list.SelectedItem().(branchSelectItem); ok {
				m.choice = i.name
				m.quitting = true
				return m, tea.Quit
			}
		}
	}

	var cmd tea.Cmd
	m.list, cmd = m.list.Update(msg)
	return m, cmd
}

func (m branchSelectModel) View() string {
	if m.quitting {
		return ""
	}
	return fmt.Sprintf("%s\n%s", m.list.View(), helpStyle.Render("Press q to quit, / to search"))
}
