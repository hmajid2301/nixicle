package main

import (
	"fmt"

	"github.com/charmbracelet/bubbles/list"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/urfave/cli/v2"
)

func runKillMode(c *cli.Context) error {
	info("Loading sessions...")

	sessions, err := listAllSessions()
	if err != nil {
		return fmt.Errorf("failed to list sessions: %w", err)
	}

	if len(sessions) == 0 {
		info("No active sessions found")
		return nil
	}

	items := make([]multiSelectItem, len(sessions))
	for i, s := range sessions {
		items[i] = multiSelectItem{
			title:       s,
			description: "",
			selected:    false,
			value:       s,
		}
	}

	selected, err := runMultiSelect("Select sessions to kill", items)
	if err != nil {
		return err
	}

	if len(selected) == 0 {
		info("No sessions selected")
		return nil
	}

	confirmed, err := runConfirmDialog(
		"Kill Sessions",
		fmt.Sprintf("Kill %d session(s)? This cannot be undone.", len(selected)),
	)
	if err != nil {
		return err
	}

	if !confirmed {
		info("Operation cancelled")
		return nil
	}

	var killedCount int
	for _, session := range selected {
		info(fmt.Sprintf("Killing session: %s", session))
		if err := killSession(session); err != nil {
			warning(fmt.Sprintf("Failed to kill session %s: %v", session, err))
			continue
		}
		success(fmt.Sprintf("Killed session: %s", session))
		killedCount++
	}

	if killedCount == 0 {
		warning("No sessions were killed")
	} else {
		success(fmt.Sprintf("Killed %d session(s)", killedCount))
	}

	return nil
}

func runRenameSession(c *cli.Context) error {
	oldName := c.Args().Get(0)
	newName := c.Args().Get(1)

	if oldName == "" {
		return runRenameSessionInteractive()
	}

	if newName == "" {
		return fmt.Errorf("new session name required")
	}

	if !sessionExists(oldName) {
		return fmt.Errorf("session '%s' not found", oldName)
	}

	if sessionExists(newName) {
		return fmt.Errorf("session '%s' already exists", newName)
	}

	info(fmt.Sprintf("Renaming session '%s' to '%s'...", oldName, newName))

	_, err := runZellij("action", "rename-session", newName)
	if err != nil {
		return fmt.Errorf("failed to rename session: %w", err)
	}

	success(fmt.Sprintf("Renamed session to '%s'", newName))
	return nil
}

func runRenameSessionInteractive() error {
	sessions, err := listAllSessions()
	if err != nil {
		return err
	}

	if len(sessions) == 0 {
		info("No active sessions found")
		return nil
	}

	selected, err := selectSessionFromList(sessions)
	if err != nil {
		return err
	}

	if selected == "" {
		return nil
	}

	newName, err := runTextInput(
		"Enter new session name",
		selected,
		func(s string) error {
			if s == "" {
				return fmt.Errorf("name cannot be empty")
			}
			if sessionExists(s) && s != selected {
				return fmt.Errorf("session '%s' already exists", s)
			}
			return nil
		},
	)
	if err != nil {
		return err
	}

	if newName == "" || newName == selected {
		info("Operation cancelled")
		return nil
	}

	info(fmt.Sprintf("Renaming session '%s' to '%s'...", selected, newName))

	_, err = runZellij("action", "rename-session", newName)
	if err != nil {
		return fmt.Errorf("failed to rename session: %w", err)
	}

	success(fmt.Sprintf("Renamed session to '%s'", newName))
	return nil
}

type sessionSelectItem struct {
	name string
}

func (i sessionSelectItem) FilterValue() string { return i.name }
func (i sessionSelectItem) Title() string       { return i.name }
func (i sessionSelectItem) Description() string { return "" }

func selectSessionFromList(sessions []string) (string, error) {
	items := make([]list.Item, len(sessions))
	for i, s := range sessions {
		items[i] = sessionSelectItem{name: s}
	}

	l := list.New(items, list.NewDefaultDelegate(), 0, 0)
	l.Title = "Select a session"
	l.SetShowStatusBar(false)
	l.SetFilteringEnabled(true)
	l.Styles.Title = titleStyle

	m := sessionSelectModel{list: l}
	p := tea.NewProgram(m, tea.WithAltScreen())
	finalModel, err := p.Run()
	if err != nil {
		return "", err
	}

	if m, ok := finalModel.(sessionSelectModel); ok {
		return m.choice, nil
	}

	return "", fmt.Errorf("unexpected model type")
}

type sessionSelectModel struct {
	list     list.Model
	choice   string
	quitting bool
}

func (m sessionSelectModel) Init() tea.Cmd { return nil }

func (m sessionSelectModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
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
			if i, ok := m.list.SelectedItem().(sessionSelectItem); ok {
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

func (m sessionSelectModel) View() string {
	if m.quitting {
		return ""
	}
	return fmt.Sprintf("%s\n%s", m.list.View(), helpStyle.Render("Press q to quit, / to search"))
}
