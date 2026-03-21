package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/urfave/cli/v2"
)

var contextFiles = []string{
	"CLAUDE.md",
	".claude/CLAUDE.md",
	"claude.md",
	"OPCODE.md",
	".opencode/OPCODE.md",
	"opencode.md",
	"AGENTS.md",
	"README.md",
	".context/",
	".claude/",
	".opencode/",
}

type ContextInfo struct {
	Name     string
	Path     string
	Exists   bool
	IsDir    bool
	Size     int64
	Modified string
}

func runContextMode(c *cli.Context) error {
	isRepo, err := isGitRepo()
	if err != nil {
		return err
	}

	var basePath string
	if isRepo {
		basePath, err = getMainWorktree()
		if err != nil {
			return fmt.Errorf("failed to get repo root: %w", err)
		}
	} else {
		basePath, err = os.Getwd()
		if err != nil {
			return fmt.Errorf("failed to get current directory: %w", err)
		}
	}

	var contexts []ContextInfo
	for _, cf := range contextFiles {
		fullPath := filepath.Join(basePath, cf)

		info, err := os.Stat(fullPath)
		if err != nil {
			contexts = append(contexts, ContextInfo{
				Name:   cf,
				Path:   fullPath,
				Exists: false,
			})
			continue
		}

		modified := ""
		if !info.IsDir() {
			modified = info.ModTime().Format("2006-01-02 15:04")
		}

		contexts = append(contexts, ContextInfo{
			Name:     cf,
			Path:     fullPath,
			Exists:   true,
			IsDir:    info.IsDir(),
			Size:     info.Size(),
			Modified: modified,
		})
	}

	fmt.Println()
	fmt.Println(headerStyle.Render(" Context Files "))
	fmt.Println()

	for _, ctx := range contexts {
		printContextInfo(ctx)
	}

	fmt.Println()
	printContextSummary(contexts)

	return nil
}

func printContextInfo(ctx ContextInfo) {
	if !ctx.Exists {
		fmt.Printf("  %s\n", inactiveStyle.Render("○ "+ctx.Name+" (not found)"))
		return
	}

	if ctx.IsDir {
		contents := listDirContents(ctx.Path)
		fmt.Printf("  %s\n", successStyle.Render("● "+ctx.Name+"/"))
		for _, f := range contents {
			fmt.Printf("    %s\n", inactiveStyle.Render("├─ "+f))
		}
	} else {
		fmt.Printf("  %s\n", successStyle.Render("● "+ctx.Name+" ("+formatSize(ctx.Size)+", "+ctx.Modified+")"))
	}
}

func listDirContents(path string) []string {
	entries, err := os.ReadDir(path)
	if err != nil {
		return nil
	}

	var files []string
	for _, entry := range entries {
		name := entry.Name()
		if !strings.HasPrefix(name, ".") {
			if entry.IsDir() {
				name += "/"
			}
			files = append(files, name)
		}
		if len(files) >= 5 {
			files = append(files, "...")
			break
		}
	}
	return files
}

func formatSize(bytes int64) string {
	const (
		KB = 1024
		MB = KB * 1024
	)
	switch {
	case bytes >= MB:
		return fmt.Sprintf("%.1fMB", float64(bytes)/float64(MB))
	case bytes >= KB:
		return fmt.Sprintf("%.1fKB", float64(bytes)/float64(KB))
	default:
		return fmt.Sprintf("%dB", bytes)
	}
}

func printContextSummary(contexts []ContextInfo) {
	existing := 0
	for _, ctx := range contexts {
		if ctx.Exists {
			existing++
		}
	}

	if existing == 0 {
		warning("No context files found")
		fmt.Println()
		fmt.Println("  Create context files to help AI assistants:")
		fmt.Println("  • CLAUDE.md - Instructions for Claude")
		fmt.Println("  • AGENTS.md - General agent instructions")
		fmt.Println("  • .context/ - Project-specific context")
	} else {
		success(fmt.Sprintf("Found %d context file(s)", existing))
	}
}

func loadContextContent(basePath string) (string, error) {
	var content strings.Builder

	priorityFiles := []string{
		"CLAUDE.md",
		".claude/CLAUDE.md",
		"AGENTS.md",
		"README.md",
	}

	for _, cf := range priorityFiles {
		fullPath := filepath.Join(basePath, cf)
		data, err := os.ReadFile(fullPath)
		if err != nil {
			continue
		}

		content.WriteString(fmt.Sprintf("\n=== %s ===\n", cf))
		content.WriteString(string(data))
		content.WriteString("\n")
	}

	return content.String(), nil
}

func showContextOnAttach(worktreePath string) {
	contexts := findContextFiles(worktreePath)
	if len(contexts) == 0 {
		return
	}

	fmt.Println()
	fmt.Println(infoStyle.Render("Context files available:"))
	for _, ctx := range contexts {
		if ctx.Exists {
			fmt.Printf("  %s\n", successStyle.Render("● "+ctx.Name))
		}
	}
	fmt.Println()
}

func findContextFiles(basePath string) []ContextInfo {
	var contexts []ContextInfo

	for _, cf := range contextFiles {
		fullPath := filepath.Join(basePath, cf)

		info, err := os.Stat(fullPath)
		if err != nil {
			continue
		}

		contexts = append(contexts, ContextInfo{
			Name:   cf,
			Path:   fullPath,
			Exists: true,
			IsDir:  info.IsDir(),
		})
	}

	return contexts
}
