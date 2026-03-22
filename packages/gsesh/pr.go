package main

import (
	"fmt"
	"os"
	"os/exec"
	"regexp"
	"strconv"
	"strings"

	"github.com/charmbracelet/bubbles/list"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/urfave/cli/v2"
)

func runPRMode(c *cli.Context) error {
	prNumber := c.Args().First()

	if prNumber == "" {
		return runPRList(c)
	}

	return runPRCheckout(c, prNumber)
}

func runPRList(c *cli.Context) error {
	info("Fetching PRs from GitHub...")

	cmd := exec.Command("gh", "pr", "list", "--state", "open", "--limit", "50")
	out, err := cmd.Output()
	if err != nil {
		return fmt.Errorf("failed to list PRs: %w", err)
	}

	lines := strings.Split(string(out), "\n")
	var prs []PRInfo

	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}

		pr := parsePRLine(line)
		if pr.Number > 0 {
			prs = append(prs, pr)
		}
	}

	if len(prs) == 0 {
		info("No open PRs found")
		return nil
	}

	selected, err := selectPR(prs)
	if err != nil {
		return err
	}

	if selected.Number == 0 {
		return nil
	}

	return checkoutPR(selected)
}

func runPRCheckout(c *cli.Context, prNumber string) error {
	info(fmt.Sprintf("Checking out PR #%s...", prNumber))

	cmd := exec.Command("gh", "pr", "checkout", prNumber)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to checkout PR: %w", err)
	}

	success(fmt.Sprintf("Checked out PR #%s", prNumber))

	project, err := getProjectName()
	if err != nil {
		return nil
	}

	branch, err := getCurrentBranch()
	if err != nil {
		return nil
	}

	confirmed, err := runConfirmDialog(
		"Create Worktree",
		fmt.Sprintf("Create worktree for PR branch '%s'?", branch),
	)
	if err != nil {
		return err
	}

	if !confirmed {
		return nil
	}

	return createNewBranch(branch, project, c)
}

type PRInfo struct {
	Number int
	Title  string
	Author string
	Branch string
	Status string
}

func parsePRLine(line string) PRInfo {
	re := regexp.MustCompile(`^(\d+)\t(.+?)\t(.+?)\t(.+?)(?:\t(.+))?$`)
	matches := re.FindStringSubmatch(line)

	if len(matches) < 5 {
		return PRInfo{}
	}

	number, _ := strconv.Atoi(matches[1])
	return PRInfo{
		Number: number,
		Title:  strings.TrimSpace(matches[2]),
		Author: strings.TrimSpace(matches[3]),
		Branch: strings.TrimSpace(matches[4]),
		Status: strings.TrimSpace(matches[5]),
	}
}

func selectPR(prs []PRInfo) (PRInfo, error) {
	items := make([]list.Item, len(prs))
	for i, pr := range prs {
		items[i] = prItem{pr: pr}
	}

	m := newPRPicker(items)
	p := tea.NewProgram(m, tea.WithAltScreen())
	finalModel, err := p.Run()
	if err != nil {
		return PRInfo{}, err
	}

	if m, ok := finalModel.(prPickerModel); ok {
		return m.choice, nil
	}

	return PRInfo{}, fmt.Errorf("unexpected model type")
}

func checkoutPR(pr PRInfo) error {
	info(fmt.Sprintf("Checking out PR #%d: %s", pr.Number, pr.Title))

	cmd := exec.Command("gh", "pr", "checkout", fmt.Sprintf("%d", pr.Number))
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to checkout PR: %w", err)
	}

	success(fmt.Sprintf("Checked out PR #%d", pr.Number))
	return nil
}

type prItem struct {
	pr PRInfo
}

func (i prItem) FilterValue() string { return fmt.Sprintf("%d %s", i.pr.Number, i.pr.Title) }
func (i prItem) Title() string {
	return fmt.Sprintf("#%d %s", i.pr.Number, i.pr.Title)
}
func (i prItem) Description() string {
	return fmt.Sprintf("%s • %s", i.pr.Author, i.pr.Branch)
}

type prPickerModel struct {
	list     list.Model
	choice   PRInfo
	quitting bool
}

func newPRPicker(items []list.Item) prPickerModel {
	l := list.New(items, list.NewDefaultDelegate(), 0, 0)
	l.Title = "Select a PR to checkout"
	l.SetShowStatusBar(false)
	l.SetFilteringEnabled(true)
	l.Styles.Title = titleStyle

	return prPickerModel{list: l}
}

func (m prPickerModel) Init() tea.Cmd { return nil }

func (m prPickerModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.list.SetWidth(msg.Width)
		m.list.SetHeight(msg.Height - 4)
		return m, nil

	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c", "q", "esc":
			m.quitting = true
			return m, tea.Quit

		case "enter":
			if i, ok := m.list.SelectedItem().(prItem); ok {
				m.choice = i.pr
				m.quitting = true
				return m, tea.Quit
			}
		}
	}

	var cmd tea.Cmd
	m.list, cmd = m.list.Update(msg)
	return m, cmd
}

func (m prPickerModel) View() string {
	if m.quitting {
		return ""
	}
	return fmt.Sprintf("%s\n%s", m.list.View(), helpStyle.Render("Press q to quit, / to search"))
}
