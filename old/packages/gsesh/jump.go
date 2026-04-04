package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/charmbracelet/bubbles/list"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/urfave/cli/v2"
)

type projectItem struct {
	name   string
	path   string
	isRepo bool
}

func (i projectItem) FilterValue() string { return i.name }
func (i projectItem) Title() string {
	if i.isRepo {
		return "📁 " + i.name
	}
	return "📂 " + i.name
}
func (i projectItem) Description() string { return i.path }

type projectPickerModel struct {
	list     list.Model
	choice   *projectItem
	quitting bool
}

func newProjectPicker(projects []projectItem) projectPickerModel {
	items := make([]list.Item, len(projects))
	for i, p := range projects {
		items[i] = p
	}

	l := list.New(items, list.NewDefaultDelegate(), 0, 0)
	l.Title = "Select a project"
	l.SetShowStatusBar(false)
	l.SetFilteringEnabled(true)
	l.Styles.Title = titleStyle

	return projectPickerModel{list: l}
}

func (m projectPickerModel) Init() tea.Cmd {
	return nil
}

func (m projectPickerModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
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
			i, ok := m.list.SelectedItem().(projectItem)
			if ok {
				m.choice = &i
				m.quitting = true
				return m, tea.Quit
			}
		}
	}

	var cmd tea.Cmd
	m.list, cmd = m.list.Update(msg)
	return m, cmd
}

func (m projectPickerModel) View() string {
	if m.quitting {
		return ""
	}
	return fmt.Sprintf("%s\n%s", m.list.View(), helpStyle.Render("Press q to quit, / to search"))
}

func getZoxideProjects() ([]projectItem, error) {
	cmd := exec.Command("zoxide", "query", "--list")
	out, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to query zoxide: %w", err)
	}

	var projects []projectItem
	for _, line := range strings.Split(string(out), "\n") {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}

		isRepo := isGitRepoAtPath(line)
		projects = append(projects, projectItem{
			name:   filepath.Base(line),
			path:   line,
			isRepo: isRepo,
		})
	}

	return projects, nil
}

func isGitRepoAtPath(path string) bool {
	cmd := exec.Command("git", "-C", path, "rev-parse", "--git-dir")
	return cmd.Run() == nil
}

func runJumpMode(c *cli.Context) error {
	info("Loading projects from zoxide...")

	projects, err := getZoxideProjects()
	if err != nil {
		return fmt.Errorf("failed to get projects: %w", err)
	}

	if len(projects) == 0 {
		warning("No projects found in zoxide. Use 'zoxide add <dir>' to add projects.")
		return nil
	}

	selected, err := selectProject(projects)
	if err != nil {
		return err
	}

	if selected == nil {
		return nil
	}

	info(fmt.Sprintf("Selected: %s", selected.name))

	if !selected.isRepo {
		return handleNonGitProject(selected, c.Bool("ai"))
	}

	return handleGitProject(selected, c)
}

func selectProject(projects []projectItem) (*projectItem, error) {
	m := newProjectPicker(projects)

	p := tea.NewProgram(m, tea.WithAltScreen())
	finalModel, err := p.Run()
	if err != nil {
		return nil, err
	}

	if m, ok := finalModel.(projectPickerModel); ok {
		return m.choice, nil
	}

	return nil, fmt.Errorf("unexpected model type")
}

func handleNonGitProject(project *projectItem, startAI bool) error {
	sessionName := sanitizeName(project.name)

	if sessionExists(sessionName) {
		info(fmt.Sprintf("Attaching to session: %s", sessionName))
		return attachSessionWithAI(sessionName, project.path, startAI, "default")
	}

	layout, err := selectLayout()
	if err != nil {
		return err
	}

	info(fmt.Sprintf("Creating session '%s' at %s", sessionName, project.path))
	return createSessionWithAI(sessionName, project.path, layout, startAI)
}

func handleGitProject(project *projectItem, c *cli.Context) error {
	originalDir, err := os.Getwd()
	if err != nil {
		return fmt.Errorf("failed to get current directory: %w", err)
	}
	defer os.Chdir(originalDir)

	if err := os.Chdir(project.path); err != nil {
		return fmt.Errorf("failed to change to project directory: %w", err)
	}

	worktrees, err := listWorktrees()
	if err != nil {
		worktrees = nil
	}

	if len(worktrees) == 0 {
		return handleSingleWorktree(project, c)
	}

	return selectAndSwitchWorktree(project, worktrees, c)
}

func handleSingleWorktree(project *projectItem, c *cli.Context) error {
	currentBranch, err := getCurrentBranch()
	if err != nil {
		currentBranch = "main"
	}

	sessionName := getSessionName(project.name, currentBranch)

	if sessionExists(sessionName) {
		info(fmt.Sprintf("Attaching to session: %s", sessionName))
		return attachSessionWithAI(sessionName, project.path, c.Bool("ai"), c.String("layout"))
	}

	layout := c.String("layout")
	if layout == "" {
		var err error
		layout, err = selectLayout()
		if err != nil {
			return err
		}
	}

	info(fmt.Sprintf("Creating session '%s'", sessionName))
	return createSessionWithAI(sessionName, project.path, layout, c.Bool("ai"))
}

type jumpWorktreeItem struct {
	branch      string
	path        string
	sessionName string
	hasSession  bool
	project     string
}

func (i jumpWorktreeItem) FilterValue() string { return i.branch }
func (i jumpWorktreeItem) Title() string {
	if i.hasSession {
		return selectedStyle.Render("✓ " + i.branch)
	}
	return "  " + i.branch
}
func (i jumpWorktreeItem) Description() string {
	if i.hasSession {
		return fmt.Sprintf("session: %s", i.sessionName)
	}
	return "no session"
}

type jumpWorktreePickerModel struct {
	list     list.Model
	choice   *jumpWorktreeItem
	quitting bool
}

func newJumpWorktreePicker(worktrees []Worktree, project string) jumpWorktreePickerModel {
	items := make([]list.Item, len(worktrees))

	for i, wt := range worktrees {
		sessionName := getSessionName(project, wt.Branch)
		items[i] = jumpWorktreeItem{
			branch:      wt.Branch,
			path:        wt.Path,
			sessionName: sessionName,
			hasSession:  sessionExists(sessionName),
			project:     project,
		}
	}

	l := list.New(items, list.NewDefaultDelegate(), 0, 0)
	l.Title = "Select a worktree in " + project
	l.SetShowStatusBar(false)
	l.SetFilteringEnabled(true)
	l.Styles.Title = titleStyle

	return jumpWorktreePickerModel{list: l}
}

func (m jumpWorktreePickerModel) Init() tea.Cmd {
	return nil
}

func (m jumpWorktreePickerModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
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
			i, ok := m.list.SelectedItem().(jumpWorktreeItem)
			if ok {
				m.choice = &i
				m.quitting = true
				return m, tea.Quit
			}
		}
	}

	var cmd tea.Cmd
	m.list, cmd = m.list.Update(msg)
	return m, cmd
}

func (m jumpWorktreePickerModel) View() string {
	if m.quitting {
		return ""
	}
	return fmt.Sprintf("%s\n%s", m.list.View(), helpStyle.Render("Press q to quit, / to search"))
}

func selectAndSwitchWorktree(project *projectItem, worktrees []Worktree, c *cli.Context) error {
	m := newJumpWorktreePicker(worktrees, project.name)

	p := tea.NewProgram(m, tea.WithAltScreen())
	finalModel, err := p.Run()
	if err != nil {
		return err
	}

	if jm, ok := finalModel.(jumpWorktreePickerModel); ok {
		if jm.choice == nil {
			return nil
		}

		info(fmt.Sprintf("Selected: %s", jm.choice.branch))

		layout := c.String("layout")
		if layout == "" {
			layout = "default"
		}

		if jm.choice.hasSession {
			return attachSessionWithAI(jm.choice.sessionName, jm.choice.path, c.Bool("ai"), layout)
		}

		return createSessionWithAI(jm.choice.sessionName, jm.choice.path, layout, c.Bool("ai"))
	}

	return fmt.Errorf("unexpected model type")
}
