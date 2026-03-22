package main

import (
	"fmt"
	"sort"
	"strings"

	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/sahilm/fuzzy"
)

// ============================================================================
// Branch Autocomplete Input
// ============================================================================

type branchAutocompleteModel struct {
	textinput       textinput.Model
	suggestions     []string
	filtered        []string
	selected        int
	title           string
	validator       func(string) error
	err             error
	quitting        bool
	showSuggestions bool
}

func newBranchAutocomplete(title string, branches []string, validator func(string) error) branchAutocompleteModel {
	ti := textinput.New()
	ti.Placeholder = "Type to search branches..."
	ti.Focus()
	ti.CharLimit = 100
	ti.Width = 50

	// Sort branches alphabetically
	sort.Strings(branches)

	return branchAutocompleteModel{
		textinput:       ti,
		suggestions:     branches,
		filtered:        branches[:min(10, len(branches))],
		selected:        0,
		title:           title,
		validator:       validator,
		showSuggestions: true,
	}
}

func (m branchAutocompleteModel) Init() tea.Cmd {
	return textinput.Blink
}

func (m branchAutocompleteModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.Type {
		case tea.KeyEnter:
			// If there's a selected suggestion, use it
			if len(m.filtered) > 0 && m.selected >= 0 && m.selected < len(m.filtered) {
				m.textinput.SetValue(m.filtered[m.selected])
			}

			if m.validator != nil {
				if err := m.validator(m.textinput.Value()); err != nil {
					m.err = err
					return m, nil
				}
			}
			m.quitting = true
			return m, tea.Quit

		case tea.KeyCtrlC, tea.KeyEsc:
			m.textinput.SetValue("")
			m.quitting = true
			return m, tea.Quit

		case tea.KeyUp:
			if m.selected > 0 {
				m.selected--
			}
			return m, nil

		case tea.KeyDown:
			if m.selected < len(m.filtered)-1 {
				m.selected++
			}
			return m, nil

		case tea.KeyTab:
			// Autocomplete with selected suggestion
			if len(m.filtered) > 0 && m.selected >= 0 && m.selected < len(m.filtered) {
				m.textinput.SetValue(m.filtered[m.selected])
				m.textinput.CursorEnd()
			}
			return m, nil
		}
	}

	var cmd tea.Cmd
	m.textinput, cmd = m.textinput.Update(msg)
	m.err = nil

	// Filter suggestions based on input
	m.filterSuggestions()

	return m, cmd
}

func (m *branchAutocompleteModel) filterSuggestions() {
	input := m.textinput.Value()

	if input == "" {
		m.filtered = m.suggestions[:min(10, len(m.suggestions))]
		m.selected = 0
		return
	}

	// Use fuzzy matching
	matches := fuzzy.Find(input, m.suggestions)

	m.filtered = make([]string, 0, 10)
	for i, match := range matches {
		if i >= 10 {
			break
		}
		m.filtered = append(m.filtered, match.Str)
	}

	// Reset selection
	if m.selected >= len(m.filtered) {
		m.selected = max(0, len(m.filtered)-1)
	}
}

func (m branchAutocompleteModel) View() string {
	if m.quitting {
		return ""
	}

	var b strings.Builder

	b.WriteString(titleStyle.Render(m.title))
	b.WriteString("\n\n")
	b.WriteString(m.textinput.View())
	b.WriteString("\n")

	// Show suggestions
	if m.showSuggestions && len(m.filtered) > 0 {
		b.WriteString("\n")
		b.WriteString(mutedStyle.Render("Suggestions:"))
		b.WriteString("\n")

		for i, suggestion := range m.filtered {
			cursor := "  "
			style := mutedStyle

			if i == m.selected {
				cursor = cursorStyle.Render("→ ")
				style = selectedStyle
			}

			// Highlight matching parts
			input := m.textinput.Value()
			if input != "" {
				suggestion = highlightMatch(suggestion, input, style)
			} else {
				suggestion = style.Render(suggestion)
			}

			b.WriteString(fmt.Sprintf("%s%s\n", cursor, suggestion))
		}
	}

	b.WriteString("\n")

	var errStr string
	if m.err != nil {
		errStr = errorStyle.Render(m.err.Error()) + "\n"
	}

	b.WriteString(errStr)
	b.WriteString(helpStyle.Render("type to search • tab: autocomplete • ↑↓: navigate • enter: confirm • esc: cancel"))

	return b.String()
}

// highlightMatch highlights the matching part of a string
func highlightMatch(str, pattern string, style lipgloss.Style) string {
	if pattern == "" {
		return style.Render(str)
	}

	lowerStr := strings.ToLower(str)
	lowerPattern := strings.ToLower(pattern)

	idx := strings.Index(lowerStr, lowerPattern)
	if idx == -1 {
		return style.Render(str)
	}

	// Split into parts: before, match, after
	before := str[:idx]
	match := str[idx : idx+len(pattern)]
	after := str[idx+len(pattern):]

	// Highlight the match
	return mutedStyle.Render(before) + lipgloss.NewStyle().
		Foreground(primaryColor).
		Bold(true).
		Render(match) + mutedStyle.Render(after)
}

func runBranchAutocomplete(title string, branches []string, validator func(string) error) (string, error) {
	m := newBranchAutocomplete(title, branches, validator)
	p := tea.NewProgram(m)
	finalModel, err := p.Run()
	if err != nil {
		return "", err
	}

	if m, ok := finalModel.(branchAutocompleteModel); ok {
		return m.textinput.Value(), nil
	}
	return "", fmt.Errorf("unexpected model type")
}

// ============================================================================
// Quick Branch Selector with Autocomplete
// ============================================================================

type quickBranchSelectModel struct {
	textinput  textinput.Model
	branches   []string
	filtered   []string
	selected   int
	title      string
	showCreate bool
	quitting   bool
}

func newQuickBranchSelect(title string, branches []string) quickBranchSelectModel {
	ti := textinput.New()
	ti.Placeholder = "Search or type new branch name..."
	ti.Focus()
	ti.CharLimit = 100
	ti.Width = 60

	sort.Strings(branches)

	return quickBranchSelectModel{
		textinput:  ti,
		branches:   branches,
		filtered:   branches[:min(8, len(branches))],
		selected:   0,
		title:      title,
		showCreate: true,
	}
}

func (m quickBranchSelectModel) Init() tea.Cmd {
	return textinput.Blink
}

func (m quickBranchSelectModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.Type {
		case tea.KeyEnter:
			m.quitting = true
			return m, tea.Quit

		case tea.KeyCtrlC, tea.KeyEsc:
			m.textinput.SetValue("")
			m.quitting = true
			return m, tea.Quit

		case tea.KeyUp:
			if m.selected > 0 {
				m.selected--
			}
			return m, nil

		case tea.KeyDown:
			maxSel := len(m.filtered)
			if m.showCreate && m.textinput.Value() != "" {
				maxSel++ // +1 for "Create new" option
			}
			if m.selected < maxSel-1 {
				m.selected++
			}
			return m, nil

		case tea.KeyTab:
			// Autocomplete
			if len(m.filtered) > 0 && m.selected >= 0 && m.selected < len(m.filtered) {
				m.textinput.SetValue(m.filtered[m.selected])
				m.textinput.CursorEnd()
			}
			return m, nil
		}
	}

	var cmd tea.Cmd
	m.textinput, cmd = m.textinput.Update(msg)
	m.filterBranches()

	return m, cmd
}

func (m *quickBranchSelectModel) filterBranches() {
	input := m.textinput.Value()

	if input == "" {
		m.filtered = m.branches[:min(8, len(m.branches))]
		m.selected = 0
		return
	}

	// Fuzzy match
	matches := fuzzy.Find(input, m.branches)

	m.filtered = make([]string, 0, 8)
	for i, match := range matches {
		if i >= 8 {
			break
		}
		m.filtered = append(m.filtered, match.Str)
	}

	if m.selected >= len(m.filtered) {
		m.selected = max(0, len(m.filtered)-1)
	}
}

func (m quickBranchSelectModel) View() string {
	if m.quitting {
		return ""
	}

	var b strings.Builder

	b.WriteString(titleStyle.Render(m.title))
	b.WriteString("\n\n")
	b.WriteString(m.textinput.View())
	b.WriteString("\n\n")

	input := m.textinput.Value()

	// Show "Create new" option if typing a new branch
	if m.showCreate && input != "" {
		isExisting := false
		for _, branch := range m.branches {
			if branch == input {
				isExisting = true
				break
			}
		}

		if !isExisting {
			cursor := "  "
			style := mutedStyle
			if m.selected == len(m.filtered) {
				cursor = cursorStyle.Render("→ ")
				style = successStyle
			}
			b.WriteString(fmt.Sprintf("%s%s\n", cursor, style.Render("✨ Create new: "+input)))
		}
	}

	// Show filtered branches
	if len(m.filtered) > 0 {
		b.WriteString(mutedStyle.Render("Existing branches:"))
		b.WriteString("\n")

		for i, branch := range m.filtered {
			cursor := "  "
			style := mutedStyle

			// Adjust selection index if "Create new" is shown
			selIdx := i
			if m.showCreate && input != "" {
				selIdx = i + 1 // +1 for "Create new" option
			}

			if m.selected == selIdx || (m.selected == i && (!m.showCreate || input == "")) {
				cursor = cursorStyle.Render("→ ")
				style = selectedStyle
			}

			// Highlight match
			if input != "" {
				branch = highlightMatch(branch, input, style)
			} else {
				branch = style.Render(branch)
			}

			b.WriteString(fmt.Sprintf("%s%s\n", cursor, branch))
		}
	}

	b.WriteString("\n")
	b.WriteString(helpStyle.Render("type to search/create • tab: autocomplete • ↑↓: navigate • enter: confirm • esc: cancel"))

	return b.String()
}

func (m quickBranchSelectModel) Value() string {
	input := m.textinput.Value()

	// Check if "Create new" is selected
	if m.showCreate && input != "" {
		isExisting := false
		for _, branch := range m.branches {
			if branch == input {
				isExisting = true
				break
			}
		}

		// If selected index is at "Create new" position
		if !isExisting && m.selected == len(m.filtered) {
			return input // Return the new branch name
		}
	}

	// If a suggestion is selected
	if len(m.filtered) > 0 && m.selected >= 0 && m.selected < len(m.filtered) {
		// Check if we're on an existing branch
		if m.selected < len(m.filtered) {
			return m.filtered[m.selected]
		}
	}

	return input
}

func runQuickBranchSelect(title string, branches []string) (string, error) {
	m := newQuickBranchSelect(title, branches)
	p := tea.NewProgram(m)
	finalModel, err := p.Run()
	if err != nil {
		return "", err
	}

	if m, ok := finalModel.(quickBranchSelectModel); ok {
		return m.Value(), nil
	}
	return "", fmt.Errorf("unexpected model type")
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}
