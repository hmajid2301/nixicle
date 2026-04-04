package main

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/bubbles/list"
	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/urfave/cli/v2"
)

type dashboardTab int

const (
	tabWorktrees dashboardTab = iota
	tabSessions
	tabProjects
)

type dashboardModel struct {
	tabs       []dashboardTab
	currentTab dashboardTab
	worktrees  list.Model
	sessions   list.Model
	projects   list.Model
	spinner    spinner.Model
	loading    bool
	width      int
	height     int
	quitting   bool
}

type loadedMsg struct {
	worktrees []Worktree
	sessions  []string
	projects  []projectItem
}

func newDashboard() dashboardModel {
	s := spinner.New()
	s.Spinner = spinner.Dot
	s.Style = lipgloss.NewStyle().Foreground(accentColor)

	return dashboardModel{
		tabs:    []dashboardTab{tabWorktrees, tabSessions, tabProjects},
		spinner: s,
		loading: true,
	}
}

func (m dashboardModel) Init() tea.Cmd {
	return tea.Batch(
		m.spinner.Tick,
		loadDashboardData,
	)
}

func loadDashboardData() tea.Msg {
	var worktrees []Worktree
	var sessions []string
	var projects []projectItem

	if isRepo, _ := isGitRepo(); isRepo {
		worktrees, _ = listWorktrees()
	}

	sessions, _ = listAllSessions()
	projects, _ = getZoxideProjects()

	return loadedMsg{
		worktrees: worktrees,
		sessions:  sessions,
		projects:  projects,
	}
}

func (m dashboardModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case loadedMsg:
		m.loading = false
		m.worktrees = newDashboardWorktreeList(msg.worktrees)
		m.sessions = newDashboardSessionList(msg.sessions)
		m.projects = newDashboardProjectList(msg.projects)
		return m, nil

	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		m.worktrees.SetWidth(msg.Width - 4)
		m.worktrees.SetHeight(msg.Height - 8)
		m.sessions.SetWidth(msg.Width - 4)
		m.sessions.SetHeight(msg.Height - 8)
		m.projects.SetWidth(msg.Width - 4)
		m.projects.SetHeight(msg.Height - 8)
		return m, nil

	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c", "q":
			m.quitting = true
			return m, tea.Quit

		case "tab":
			m.currentTab = (m.currentTab + 1) % 3
			return m, nil

		case "shift+tab":
			m.currentTab = (m.currentTab - 1 + 3) % 3
			return m, nil

		case "1":
			m.currentTab = tabWorktrees
			return m, nil

		case "2":
			m.currentTab = tabSessions
			return m, nil

		case "3":
			m.currentTab = tabProjects
			return m, nil

		case "enter":
			return m.handleSelection()
		}

	case spinner.TickMsg:
		var cmd tea.Cmd
		m.spinner, cmd = m.spinner.Update(msg)
		return m, cmd
	}

	if m.loading {
		return m, nil
	}

	var cmd tea.Cmd
	switch m.currentTab {
	case tabWorktrees:
		m.worktrees, cmd = m.worktrees.Update(msg)
	case tabSessions:
		m.sessions, cmd = m.sessions.Update(msg)
	case tabProjects:
		m.projects, cmd = m.projects.Update(msg)
	}
	return m, cmd
}

func (m dashboardModel) handleSelection() (tea.Model, tea.Cmd) {
	switch m.currentTab {
	case tabWorktrees:
		if _, ok := m.worktrees.SelectedItem().(dashboardWorktreeItem); ok {
			m.quitting = true
			return m, tea.Quit
		}
	case tabSessions:
		if _, ok := m.sessions.SelectedItem().(dashboardSessionItem); ok {
			m.quitting = true
			return m, tea.Quit
		}
	case tabProjects:
		if _, ok := m.projects.SelectedItem().(dashboardProjectItem); ok {
			m.quitting = true
			return m, tea.Quit
		}
	}
	return m, nil
}

func (m dashboardModel) View() string {
	if m.quitting {
		return ""
	}

	if m.loading {
		return fmt.Sprintf("\n%s Loading dashboard...", m.spinner.View())
	}

	tabStyle := lipgloss.NewStyle().
		Padding(0, 2).
		Foreground(secondaryColor)

	activeTabStyle := lipgloss.NewStyle().
		Padding(0, 2).
		Foreground(primaryColor).
		Bold(true)

	var tabs []string
	tabNames := []string{"Worktrees", "Sessions", "Projects"}
	for i, name := range tabNames {
		if dashboardTab(i) == m.currentTab {
			tabs = append(tabs, activeTabStyle.Render(name))
		} else {
			tabs = append(tabs, tabStyle.Render(name))
		}
	}

	tabBar := lipgloss.NewStyle().
		Background(lipgloss.Color("#1a1a2e")).
		Width(m.width).
		Render(strings.Join(tabs, ""))

	var content string
	switch m.currentTab {
	case tabWorktrees:
		content = m.worktrees.View()
	case tabSessions:
		content = m.sessions.View()
	case tabProjects:
		content = m.projects.View()
	}

	shortcuts := newShortcuts([]shortcut{
		{key: "tab", action: "next tab"},
		{key: "1-3", action: "switch tab"},
		{key: "enter", action: "select"},
		{key: "q", action: "quit"},
	})

	return fmt.Sprintf("%s\n\n%s\n\n%s", tabBar, content, shortcuts.View())
}

type dashboardWorktreeItem struct {
	branch string
	path   string
}

func (i dashboardWorktreeItem) FilterValue() string { return i.branch }
func (i dashboardWorktreeItem) Title() string       { return i.branch }
func (i dashboardWorktreeItem) Description() string { return i.path }

func newDashboardWorktreeList(worktrees []Worktree) list.Model {
	items := make([]list.Item, len(worktrees))
	for i, wt := range worktrees {
		items[i] = dashboardWorktreeItem{branch: wt.Branch, path: wt.Path}
	}

	l := list.New(items, list.NewDefaultDelegate(), 0, 0)
	l.Title = "Worktrees"
	l.SetShowStatusBar(false)
	l.SetFilteringEnabled(true)
	l.Styles.Title = titleStyle
	return l
}

type dashboardSessionItem struct {
	name string
}

func (i dashboardSessionItem) FilterValue() string { return i.name }
func (i dashboardSessionItem) Title() string       { return i.name }
func (i dashboardSessionItem) Description() string { return "" }

func newDashboardSessionList(sessions []string) list.Model {
	items := make([]list.Item, len(sessions))
	for i, s := range sessions {
		items[i] = dashboardSessionItem{name: s}
	}

	l := list.New(items, list.NewDefaultDelegate(), 0, 0)
	l.Title = "Sessions"
	l.SetShowStatusBar(false)
	l.SetFilteringEnabled(true)
	l.Styles.Title = titleStyle
	return l
}

type dashboardProjectItem struct {
	name string
	path string
}

func (i dashboardProjectItem) FilterValue() string { return i.name }
func (i dashboardProjectItem) Title() string       { return i.name }
func (i dashboardProjectItem) Description() string { return i.path }

func newDashboardProjectList(projects []projectItem) list.Model {
	items := make([]list.Item, len(projects))
	for i, p := range projects {
		items[i] = dashboardProjectItem{name: p.name, path: p.path}
	}

	l := list.New(items, list.NewDefaultDelegate(), 0, 0)
	l.Title = "Projects"
	l.SetShowStatusBar(false)
	l.SetFilteringEnabled(true)
	l.Styles.Title = titleStyle
	return l
}

func runDashboard(c *cli.Context) error {
	m := newDashboard()
	p := tea.NewProgram(m, tea.WithAltScreen())
	_, err := p.Run()
	return err
}
