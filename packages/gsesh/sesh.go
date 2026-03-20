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

func runSeshMode(c *cli.Context) error {
	var dir string
	var err error

	if c.Args().Len() > 0 {
		dir = c.Args().First()
	} else {
		dir, err = selectDirectoryWithZoxide()
		if err != nil {
			return fmt.Errorf("failed to select directory: %w", err)
		}
	}

	if dir == "" {
		return nil
	}

	// Sanitize session name
	sessionName := sanitizeName(filepath.Base(dir))

	if sessionExists(sessionName) {
		info(fmt.Sprintf("Attaching to session: %s", sessionName))
		return attachSeshSession(sessionName, dir)
	}

	layout, err := selectLayout()
	if err != nil {
		return fmt.Errorf("failed to select layout: %w", err)
	}

	if layout == "" {
		return fmt.Errorf("no layout selected")
	}

	info(fmt.Sprintf("Creating session '%s' at %s with layout %s", sessionName, dir, layout))
	return createSeshSession(sessionName, dir, layout)
}

func selectDirectoryWithZoxide() (string, error) {
	// Check if zoxide is installed
	if _, err := exec.LookPath("zoxide"); err != nil {
		return "", fmt.Errorf("zoxide not found in PATH - please install zoxide first")
	}

	cmd := exec.Command("zoxide", "query", "--interactive")
	cmd.Stderr = os.Stderr // Show zoxide errors to user
	out, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("zoxide query failed: %w", err)
	}

	return strings.TrimSpace(string(out)), nil
}

// getZellijLayouts returns available zellij layouts
func getZellijLayouts() ([]string, error) {
	configDir := os.Getenv("XDG_CONFIG_HOME")
	if configDir == "" {
		configDir = filepath.Join(os.Getenv("HOME"), ".config")
	}

	layoutDir := filepath.Join(configDir, "zellij", "layouts")

	// Check if layout directory exists
	if _, err := os.Stat(layoutDir); os.IsNotExist(err) {
		// Return default layouts
		return []string{"default", "compact", "strider"}, nil
	}

	// Read layout directory
	entries, err := os.ReadDir(layoutDir)
	if err != nil {
		return nil, fmt.Errorf("failed to read layout directory: %w", err)
	}

	var layouts []string
	// Always include default layouts
	layouts = append(layouts, "default", "compact", "strider")

	// Add custom layouts
	for _, entry := range entries {
		if !entry.IsDir() {
			name := entry.Name()
			// Remove file extension (.kdl, .yaml, etc.)
			if ext := filepath.Ext(name); ext != "" {
				name = strings.TrimSuffix(name, ext)
			}
			// Avoid duplicates
			found := false
			for _, existing := range layouts {
				if existing == name {
					found = true
					break
				}
			}
			if !found {
				layouts = append(layouts, name)
			}
		}
	}

	return layouts, nil
}

type layoutItem struct {
	name string
}

func (i layoutItem) FilterValue() string { return i.name }
func (i layoutItem) Title() string       { return i.name }
func (i layoutItem) Description() string { return "" }

type layoutPickerModel struct {
	list     list.Model
	choice   string
	quitting bool
}

func newLayoutPicker() (layoutPickerModel, error) {
	layouts, err := getZellijLayouts()
	if err != nil {
		// Fallback to default layouts
		layouts = []string{"default", "compact", "strider"}
	}

	items := make([]list.Item, len(layouts))
	for i, layout := range layouts {
		items[i] = layoutItem{name: layout}
	}

	l := list.New(items, list.NewDefaultDelegate(), 0, 0)
	l.Title = "Select a layout"
	l.SetShowStatusBar(false)
	l.SetFilteringEnabled(true)
	l.Styles.Title = titleStyle

	return layoutPickerModel{
		list: l,
	}, nil
}

func (m layoutPickerModel) Init() tea.Cmd {
	return nil
}

func (m layoutPickerModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
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
			i, ok := m.list.SelectedItem().(layoutItem)
			if ok {
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

func (m layoutPickerModel) View() string {
	if m.quitting {
		return ""
	}
	return fmt.Sprintf("%s\n%s", m.list.View(), helpStyle.Render("Press q to quit"))
}

func selectLayout() (string, error) {
	m, err := newLayoutPicker()
	if err != nil {
		return "", err
	}

	p := tea.NewProgram(m, tea.WithAltScreen())
	finalModel, err := p.Run()
	if err != nil {
		return "", err
	}

	if m, ok := finalModel.(layoutPickerModel); ok {
		return m.choice, nil
	}

	return "", fmt.Errorf("unexpected model type")
}

func attachSeshSession(sessionName, dir string) error {
	inZellij := os.Getenv("ZELLIJ") != ""
	currentSession := getCurrentSession()

	debug(fmt.Sprintf("attachSeshSession: target=%q inZellij=%v currentSession=%q dir=%q", sessionName, inZellij, currentSession, dir))

	// If we're already in the target session, do nothing
	if inZellij && currentSession == sessionName {
		info(fmt.Sprintf("Already in session '%s'", sessionName))
		return nil
	}

	// If we're inside zellij, use pipe to switch sessions
	if inZellij {
		info(fmt.Sprintf("Switching from '%s' to '%s'...", currentSession, sessionName))
		return switchViaPipe(sessionName, dir, "")
	}

	// If not in zellij, just attach normally
	debug(fmt.Sprintf("attachSeshSession: running 'zellij attach %s' (not in zellij)", sessionName))
	return attachZellij("attach", sessionName)
}

func createSeshSession(sessionName, dir, layout string) error {
	inZellij := os.Getenv("ZELLIJ") != ""
	currentSession := getCurrentSession()

	debug(fmt.Sprintf("createSeshSession: target=%q inZellij=%v currentSession=%q dir=%q layout=%q", sessionName, inZellij, currentSession, dir, layout))

	// If we're inside zellij, use pipe to switch sessions
	if inZellij {
		info(fmt.Sprintf("Switching from '%s' to new session '%s'...", currentSession, sessionName))
		return switchViaPipe(sessionName, dir, layout)
	}

	// If not in zellij, just create normally
	if err := os.Chdir(dir); err != nil {
		return fmt.Errorf("failed to change directory to %s: %w", dir, err)
	}

	args := []string{"--layout", layout, "attach", "-c", sessionName}
	debug(fmt.Sprintf("createSeshSession: running 'zellij %s' (not in zellij)", strings.Join(args, " ")))
	return attachZellij(args...)
}
