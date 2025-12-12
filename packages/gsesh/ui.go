package main

import (
	"fmt"

	"github.com/charmbracelet/bubbles/list"
	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

var (
	titleStyle = lipgloss.NewStyle().
			Bold(true).
			Foreground(lipgloss.Color("205")).
			MarginLeft(2)

	selectedStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("170")).
			Bold(true)

	inactiveStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("241"))

	helpStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("241")).
			MarginLeft(2).
			MarginTop(1)
)

// branchItem represents a branch in the list
type branchItem struct {
	name      string
	isCurrent bool
}

func (i branchItem) FilterValue() string { return i.name }
func (i branchItem) Title() string {
	if i.isCurrent {
		return selectedStyle.Render("* " + i.name + " (current)")
	}
	return "  " + i.name
}
func (i branchItem) Description() string { return "" }

// worktreeItem represents a worktree in the list
type worktreeItem struct {
	branch      string
	path        string
	sessionName string
	hasSession  bool
}

func (i worktreeItem) FilterValue() string { return i.branch }
func (i worktreeItem) Title() string {
	if i.hasSession {
		return selectedStyle.Render("✓ " + i.branch)
	}
	return "  " + i.branch
}
func (i worktreeItem) Description() string {
	if i.hasSession {
		return fmt.Sprintf("session: %s", i.sessionName)
	}
	return "no session"
}

// branchPickerModel is the bubbletea model for branch selection
type branchPickerModel struct {
	list          list.Model
	choice        string
	quitting      bool
	createNewMode bool
	textInput     textinput.Model
}

func newBranchPicker(branches []string, currentBranch string) branchPickerModel {
	items := make([]list.Item, 0, len(branches)+1)

	// Add "Create new branch" option
	items = append(items, branchItem{name: "+ Create new branch", isCurrent: false})

	// Add branches
	for _, branch := range branches {
		items = append(items, branchItem{
			name:      branch,
			isCurrent: branch == currentBranch,
		})
	}

	l := list.New(items, list.NewDefaultDelegate(), 0, 0)
	l.Title = "Select a branch"
	l.SetShowStatusBar(false)
	l.SetFilteringEnabled(true)
	l.Styles.Title = titleStyle

	ti := textinput.New()
	ti.Placeholder = "Enter new branch name..."
	ti.Focus()
	ti.CharLimit = 100
	ti.Width = 50

	return branchPickerModel{
		list:      l,
		textInput: ti,
	}
}

func (m branchPickerModel) Init() tea.Cmd {
	return nil
}

func (m branchPickerModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	if m.createNewMode {
		return m.updateCreateMode(msg)
	}
	return m.updateListMode(msg)
}

func (m branchPickerModel) updateListMode(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.list.SetWidth(msg.Width)
		m.list.SetHeight(msg.Height - 4)
		return m, nil

	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c", "q":
			m.quitting = true
			return m, tea.Quit

		case "enter":
			i, ok := m.list.SelectedItem().(branchItem)
			if ok {
				if i.name == "+ Create new branch" {
					m.createNewMode = true
					return m, textinput.Blink
				}
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

func (m branchPickerModel) updateCreateMode(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.Type {
		case tea.KeyCtrlC, tea.KeyEsc:
			m.quitting = true
			return m, tea.Quit

		case tea.KeyEnter:
			branchName := m.textInput.Value()
			if branchName != "" {
				// Validate branch name
				if err := validateBranchName(branchName); err != nil {
					// Show error in textinput placeholder
					m.textInput.Placeholder = fmt.Sprintf("Invalid: %s", err.Error())
					m.textInput.SetValue("")
					return m, nil
				}
				m.choice = branchName
				m.quitting = true
				return m, tea.Quit
			}
		}
	}

	var cmd tea.Cmd
	m.textInput, cmd = m.textInput.Update(msg)
	return m, cmd
}

func (m branchPickerModel) View() string {
	if m.quitting {
		return ""
	}

	if m.createNewMode {
		return fmt.Sprintf(
			"\n%s\n\n%s\n\n%s",
			titleStyle.Render("Create new branch"),
			m.textInput.View(),
			helpStyle.Render("Press Enter to confirm, Esc to cancel"),
		)
	}

	return fmt.Sprintf("%s\n%s", m.list.View(), helpStyle.Render("Press q to quit, / to search"))
}

// worktreePickerModel is the bubbletea model for worktree selection
type worktreePickerModel struct {
	list     list.Model
	choice   *worktreeItem
	quitting bool
}

func newWorktreePicker(worktrees []Worktree, project string) worktreePickerModel {
	items := make([]list.Item, 0, len(worktrees))

	for _, wt := range worktrees {
		sessionName := getSessionName(project, wt.Branch)
		hasSession := sessionExists(sessionName)

		items = append(items, worktreeItem{
			branch:      wt.Branch,
			path:        wt.Path,
			sessionName: sessionName,
			hasSession:  hasSession,
		})
	}

	l := list.New(items, list.NewDefaultDelegate(), 0, 0)
	l.Title = "Select a worktree"
	l.SetShowStatusBar(false)
	l.SetFilteringEnabled(true)
	l.Styles.Title = titleStyle

	return worktreePickerModel{
		list: l,
	}
}

func (m worktreePickerModel) Init() tea.Cmd {
	return nil
}

func (m worktreePickerModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.list.SetWidth(msg.Width)
		m.list.SetHeight(msg.Height - 4)
		return m, nil

	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c", "q":
			m.quitting = true
			return m, tea.Quit

		case "enter":
			i, ok := m.list.SelectedItem().(worktreeItem)
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

func (m worktreePickerModel) View() string {
	if m.quitting {
		return ""
	}
	return fmt.Sprintf("%s\n%s", m.list.View(), helpStyle.Render("Press q to quit, / to search"))
}

// selectBranch shows a TUI for selecting a branch
func selectBranch(branches []string, currentBranch string) (string, error) {
	m := newBranchPicker(branches, currentBranch)

	p := tea.NewProgram(m, tea.WithAltScreen())
	finalModel, err := p.Run()
	if err != nil {
		return "", err
	}

	if m, ok := finalModel.(branchPickerModel); ok {
		return m.choice, nil
	}

	return "", fmt.Errorf("unexpected model type")
}

// selectWorktree shows a TUI for selecting a worktree
func selectWorktree(worktrees []Worktree, project string) (*worktreeItem, error) {
	if len(worktrees) == 0 {
		return nil, fmt.Errorf("no existing worktrees found")
	}

	m := newWorktreePicker(worktrees, project)

	p := tea.NewProgram(m, tea.WithAltScreen())
	finalModel, err := p.Run()
	if err != nil {
		return nil, err
	}

	if m, ok := finalModel.(worktreePickerModel); ok {
		return m.choice, nil
	}

	return nil, fmt.Errorf("unexpected model type")
}

// Session picker for switching between sessions

type sessionItem struct {
	info SessionInfo
}

func (i sessionItem) FilterValue() string { return i.info.Name }
func (i sessionItem) Title() string       { return i.info.Name }
func (i sessionItem) Description() string {
	if i.info.Path != "" {
		return fmt.Sprintf("📁 %s", i.info.Path)
	}
	return "No associated worktree"
}

type sessionPickerModel struct {
	list     list.Model
	choice   SessionInfo
	quitting bool
}

func newSessionPicker(sessions []SessionInfo) sessionPickerModel {
	items := make([]list.Item, len(sessions))
	for i, s := range sessions {
		items[i] = sessionItem{info: s}
	}

	l := list.New(items, list.NewDefaultDelegate(), 0, 0)
	l.Title = "Select a session to switch to"
	l.SetShowStatusBar(false)
	l.SetFilteringEnabled(true)
	l.Styles.Title = titleStyle

	return sessionPickerModel{
		list: l,
	}
}

func (m sessionPickerModel) Init() tea.Cmd {
	return nil
}

func (m sessionPickerModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
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
			i, ok := m.list.SelectedItem().(sessionItem)
			if ok {
				m.choice = i.info
				m.quitting = true
				return m, tea.Quit
			}
		}
	}

	var cmd tea.Cmd
	m.list, cmd = m.list.Update(msg)
	return m, cmd
}

func (m sessionPickerModel) View() string {
	if m.quitting {
		return ""
	}
	return fmt.Sprintf("%s\n%s", m.list.View(), helpStyle.Render("Press q to quit"))
}

func selectSession(sessions []SessionInfo) (SessionInfo, error) {
	m := newSessionPicker(sessions)

	p := tea.NewProgram(m, tea.WithAltScreen())
	finalModel, err := p.Run()
	if err != nil {
		return SessionInfo{}, err
	}

	if m, ok := finalModel.(sessionPickerModel); ok {
		return m.choice, nil
	}

	return SessionInfo{}, fmt.Errorf("unexpected model type")
}
