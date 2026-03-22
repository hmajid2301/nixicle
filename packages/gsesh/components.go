package main

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/bubbles/spinner"
	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// ============================================================================
// Text Input Component
// ============================================================================

type textInputModel struct {
	input     textinput.Model
	title     string
	validator func(string) error
	err       error
	quitting  bool
}

func newTextInput(title, placeholder string, validator func(string) error) textInputModel {
	ti := textinput.New()
	ti.Placeholder = placeholder
	ti.Focus()
	ti.CharLimit = 100
	ti.Width = 50

	return textInputModel{
		input:     ti,
		title:     title,
		validator: validator,
	}
}

func (m textInputModel) Init() tea.Cmd {
	return textinput.Blink
}

func (m textInputModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.Type {
		case tea.KeyEnter:
			if m.validator != nil {
				if err := m.validator(m.input.Value()); err != nil {
					m.err = err
					return m, nil
				}
			}
			m.quitting = true
			return m, tea.Quit
		case tea.KeyEsc, tea.KeyCtrlC:
			m.input.SetValue("")
			m.quitting = true
			return m, tea.Quit
		}
	}

	var cmd tea.Cmd
	m.input, cmd = m.input.Update(msg)
	m.err = nil
	return m, cmd
}

func (m textInputModel) View() string {
	if m.quitting {
		return ""
	}

	var errStr string
	if m.err != nil {
		errStr = errorStyle.Render(m.err.Error())
	}

	return fmt.Sprintf("%s\n\n%s\n\n%s\n%s",
		titleStyle.Render(m.title),
		m.input.View(),
		errStr,
		helpStyle.Render("enter: confirm • esc: cancel"),
	)
}

func runTextInput(title, placeholder string, validator func(string) error) (string, error) {
	m := newTextInput(title, placeholder, validator)
	p := tea.NewProgram(m)
	finalModel, err := p.Run()
	if err != nil {
		return "", err
	}

	if m, ok := finalModel.(textInputModel); ok {
		return m.input.Value(), nil
	}
	return "", fmt.Errorf("unexpected model type")
}

// ============================================================================
// Confirmation Dialog
// ============================================================================

type confirmModel struct {
	title     string
	message   string
	confirmed bool
	quitting  bool
}

func newConfirmDialog(title, message string) confirmModel {
	return confirmModel{
		title:   title,
		message: message,
	}
}

func (m confirmModel) Init() tea.Cmd {
	return nil
}

func (m confirmModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "y", "Y":
			m.confirmed = true
			m.quitting = true
			return m, tea.Quit
		case "n", "N", "esc", "ctrl+c":
			m.confirmed = false
			m.quitting = true
			return m, tea.Quit
		}
	}
	return m, nil
}

func (m confirmModel) View() string {
	if m.quitting {
		return ""
	}

	boxStyle := lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(accentColor).
		Padding(1, 2).
		Width(50)

	content := fmt.Sprintf("%s\n\n%s",
		warningStyle.Render(m.title),
		m.message,
	)

	return fmt.Sprintf("%s\n\n%s",
		boxStyle.Render(content),
		helpStyle.Render("y: yes • n: no"),
	)
}

func runConfirmDialog(title, message string) (bool, error) {
	m := newConfirmDialog(title, message)
	p := tea.NewProgram(m)
	finalModel, err := p.Run()
	if err != nil {
		return false, err
	}

	if m, ok := finalModel.(confirmModel); ok {
		return m.confirmed, nil
	}
	return false, fmt.Errorf("unexpected model type")
}

// ============================================================================
// Loading Spinner
// ============================================================================

type spinnerModel struct {
	spinner  spinner.Model
	message  string
	quitting bool
}

func newSpinner(message string) spinnerModel {
	s := spinner.New()
	s.Spinner = spinner.Dot
	s.Style = lipgloss.NewStyle().Foreground(accentColor)
	return spinnerModel{
		spinner: s,
		message: message,
	}
}

func (m spinnerModel) Init() tea.Cmd {
	return m.spinner.Tick
}

func (m spinnerModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		if msg.Type == tea.KeyCtrlC {
			m.quitting = true
			return m, tea.Quit
		}
		return m, nil

	case spinner.TickMsg:
		var cmd tea.Cmd
		m.spinner, cmd = m.spinner.Update(msg)
		return m, cmd
	}
	return m, nil
}

func (m spinnerModel) View() string {
	if m.quitting {
		return ""
	}
	return fmt.Sprintf("%s %s", m.spinner.View(), m.message)
}

func showSpinner(message string) func() {
	s := spinner.New()
	s.Spinner = spinner.Dot
	s.Style = lipgloss.NewStyle().Foreground(accentColor)

	done := make(chan struct{})
	go func() {
		for {
			select {
			case <-done:
				fmt.Printf("\r")
				return
			default:
				fmt.Printf("\r%s %s", s.View(), message)
				s.Tick()
			}
		}
	}()

	return func() {
		close(done)
		fmt.Printf("\r%s\r", strings.Repeat(" ", len(message)+10))
	}
}

// ============================================================================
// Toast Notification
// ============================================================================

type toastType int

const (
	toastSuccess toastType = iota
	toastError
	toastInfo
	toastWarning
)

type toastModel struct {
	message   string
	toastType toastType
	quitting  bool
}

func newToast(message string, t toastType) toastModel {
	return toastModel{
		message:   message,
		toastType: t,
	}
}

func (m toastModel) View() string {
	var style lipgloss.Style
	var prefix string

	switch m.toastType {
	case toastSuccess:
		style = successStyle
		prefix = "✓"
	case toastError:
		style = errorStyle
		prefix = "✗"
	case toastWarning:
		style = warningStyle
		prefix = "⚠"
	default:
		style = infoStyle
		prefix = "ℹ"
	}

	return style.Render(fmt.Sprintf("%s %s", prefix, m.message))
}

func showToast(message string, t toastType) {
	toast := newToast(message, t)
	fmt.Println(toast.View())
}

func showSuccessToast(message string) {
	showToast(message, toastSuccess)
}

func showErrorToast(message string) {
	showToast(message, toastError)
}

func showWarningToast(message string) {
	showToast(message, toastWarning)
}

func showInfoToast(message string) {
	showToast(message, toastInfo)
}

// ============================================================================
// Status Bar
// ============================================================================

type statusBarModel struct {
	project   string
	branch    string
	session   string
	gitStatus string
}

func newStatusBar(project, branch, session, gitStatus string) statusBarModel {
	return statusBarModel{
		project:   project,
		branch:    branch,
		session:   session,
		gitStatus: gitStatus,
	}
}

func (m statusBarModel) View() string {
	width := 80

	leftSection := lipgloss.NewStyle().
		Foreground(secondaryColor).
		Render(fmt.Sprintf("📁 %s", m.project))

	middleSection := lipgloss.NewStyle().
		Foreground(accentColor).
		Render(fmt.Sprintf("🌿 %s", m.branch))

	rightSection := lipgloss.NewStyle().
		Foreground(secondaryColor).
		Render(m.gitStatus)

	leftLen := lipgloss.Width(leftSection)
	middleLen := lipgloss.Width(middleSection)
	rightLen := lipgloss.Width(rightSection)

	padding := width - leftLen - middleLen - rightLen
	if padding < 0 {
		padding = 0
	}

	return lipgloss.NewStyle().
		Background(lipgloss.Color("#1a1a2e")).
		Width(width).
		Padding(0, 1).
		Render(fmt.Sprintf("%s%s%s%s",
			leftSection,
			strings.Repeat(" ", padding/2),
			middleSection,
			strings.Repeat(" ", padding/2+padding%2),
		)) + "\n" + rightSection
}

// ============================================================================
// Keyboard Shortcuts Panel
// ============================================================================

type shortcutsModel struct {
	shortcuts []shortcut
}

type shortcut struct {
	key    string
	action string
}

func newShortcuts(shortcuts []shortcut) shortcutsModel {
	return shortcutsModel{shortcuts: shortcuts}
}

func (m shortcutsModel) View() string {
	var items []string
	for _, s := range m.shortcuts {
		items = append(items, fmt.Sprintf("%s %s",
			keyStyle.Render(s.key),
			mutedStyle.Render(s.action),
		))
	}
	return helpStyle.Render(strings.Join(items, " • "))
}

// ============================================================================
// Split View
// ============================================================================

type splitViewModel struct {
	leftContent  string
	rightContent string
	leftWidth    int
	rightWidth   int
}

func newSplitView(left, right string, leftWidth, rightWidth int) splitViewModel {
	return splitViewModel{
		leftContent:  left,
		rightContent: right,
		leftWidth:    leftWidth,
		rightWidth:   rightWidth,
	}
}

func (m splitViewModel) View() string {
	leftStyle := lipgloss.NewStyle().
		Width(m.leftWidth).
		Height(10).
		Padding(0, 1)

	rightStyle := lipgloss.NewStyle().
		Width(m.rightWidth).
		Height(10).
		Padding(0, 1).
		BorderLeft(true).
		BorderForeground(borderColor)

	return lipgloss.JoinHorizontal(
		lipgloss.Top,
		leftStyle.Render(m.leftContent),
		rightStyle.Render(m.rightContent),
	)
}

// ============================================================================
// Multi-Select List
// ============================================================================

type multiSelectItem struct {
	title       string
	description string
	selected    bool
	value       string
}

type multiSelectModel struct {
	items    []multiSelectItem
	cursor   int
	quitting bool
	title    string
}

func newMultiSelect(title string, items []multiSelectItem) multiSelectModel {
	return multiSelectModel{
		title: title,
		items: items,
	}
}

func (m multiSelectModel) Init() tea.Cmd {
	return nil
}

func (m multiSelectModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "up", "k":
			if m.cursor > 0 {
				m.cursor--
			}
		case "down", "j":
			if m.cursor < len(m.items)-1 {
				m.cursor++
			}
		case " ", "x":
			m.items[m.cursor].selected = !m.items[m.cursor].selected
		case "a":
			allSelected := true
			for _, item := range m.items {
				if !item.selected {
					allSelected = false
					break
				}
			}
			for i := range m.items {
				m.items[i].selected = !allSelected
			}
		case "enter":
			m.quitting = true
			return m, tea.Quit
		case "q", "esc", "ctrl+c":
			m.quitting = true
			return m, tea.Quit
		}
	}
	return m, nil
}

func (m multiSelectModel) View() string {
	if m.quitting {
		return ""
	}

	var b strings.Builder
	b.WriteString(titleStyle.Render(m.title))
	b.WriteString("\n\n")

	for i, item := range m.items {
		cursor := " "
		if m.cursor == i {
			cursor = cursorStyle.Render(">")
		}

		checked := "☐"
		if item.selected {
			checked = selectedStyle.Render("☑")
		}

		line := fmt.Sprintf("%s %s %s", cursor, checked, item.title)
		if m.cursor == i {
			line = selectedStyle.Render(line)
		}
		b.WriteString(line + "\n")

		if item.description != "" {
			b.WriteString(mutedStyle.Render("    "+item.description) + "\n")
		}
	}

	b.WriteString("\n")
	b.WriteString(helpStyle.Render("space/x: toggle • a: select all • enter: confirm • q: quit"))

	return b.String()
}

func (m multiSelectModel) Selected() []string {
	var selected []string
	for _, item := range m.items {
		if item.selected {
			selected = append(selected, item.value)
		}
	}
	return selected
}

func runMultiSelect(title string, items []multiSelectItem) ([]string, error) {
	m := newMultiSelect(title, items)
	p := tea.NewProgram(m)
	finalModel, err := p.Run()
	if err != nil {
		return nil, err
	}

	if m, ok := finalModel.(multiSelectModel); ok {
		return m.Selected(), nil
	}
	return nil, fmt.Errorf("unexpected model type")
}
