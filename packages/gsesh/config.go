package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/urfave/cli/v2"
	"gopkg.in/yaml.v3"
)

type Config struct {
	WorktreeBase  string                   `yaml:"worktree_base"`
	AITool        string                   `yaml:"ai_tool"`
	DefaultLayout string                   `yaml:"default_layout"`
	ClaudePrefix  string                   `yaml:"claude_prefix"`
	AutoFetch     bool                     `yaml:"auto_fetch"`
	Projects      map[string]ProjectConfig `yaml:"projects"`
}

type ProjectConfig struct {
	WorktreeBase  string `yaml:"worktree_base"`
	AITool        string `yaml:"ai_tool"`
	DefaultLayout string `yaml:"default_layout"`
}

var cachedConfig *Config

func getConfigPath() string {
	configDir := os.Getenv("XDG_CONFIG_HOME")
	if configDir == "" {
		home, _ := os.UserHomeDir()
		configDir = filepath.Join(home, ".config")
	}
	return filepath.Join(configDir, "gsesh", "config.yaml")
}

func loadConfig() (*Config, error) {
	if cachedConfig != nil {
		return cachedConfig, nil
	}

	configPath := getConfigPath()

	cachedConfig = &Config{
		WorktreeBase:  ".worktrees",
		AITool:        "opencode",
		DefaultLayout: "default",
		ClaudePrefix:  "claude",
		AutoFetch:     true,
		Projects:      make(map[string]ProjectConfig),
	}

	data, err := os.ReadFile(configPath)
	if err != nil {
		if os.IsNotExist(err) {
			return cachedConfig, nil
		}
		return nil, fmt.Errorf("failed to read config: %w", err)
	}

	if err := yaml.Unmarshal(data, cachedConfig); err != nil {
		return nil, fmt.Errorf("failed to parse config: %w", err)
	}

	return cachedConfig, nil
}

func saveConfig(cfg *Config) error {
	configPath := getConfigPath()

	if err := os.MkdirAll(filepath.Dir(configPath), 0755); err != nil {
		return fmt.Errorf("failed to create config dir: %w", err)
	}

	data, err := yaml.Marshal(cfg)
	if err != nil {
		return fmt.Errorf("failed to marshal config: %w", err)
	}

	if err := os.WriteFile(configPath, data, 0644); err != nil {
		return fmt.Errorf("failed to write config: %w", err)
	}

	cachedConfig = cfg
	return nil
}

func getProjectConfig(project string) (worktreeBase, aiTool, layout string) {
	cfg, err := loadConfig()
	if err != nil {
		return ".worktrees", "opencode", "default"
	}

	worktreeBase = cfg.WorktreeBase
	aiTool = cfg.AITool
	layout = cfg.DefaultLayout

	if pc, ok := cfg.Projects[project]; ok {
		if pc.WorktreeBase != "" {
			worktreeBase = pc.WorktreeBase
		}
		if pc.AITool != "" {
			aiTool = pc.AITool
		}
		if pc.DefaultLayout != "" {
			layout = pc.DefaultLayout
		}
	}

	return
}

func runConfigShow() error {
	cfg, err := loadConfig()
	if err != nil {
		return err
	}

	data, err := yaml.Marshal(cfg)
	if err != nil {
		return err
	}

	fmt.Printf("Config file: %s\n\n", getConfigPath())
	fmt.Println(string(data))
	return nil
}

func runConfigEdit() error {
	configPath := getConfigPath()

	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		if err := saveConfig(&Config{
			WorktreeBase:  ".worktrees",
			AITool:        "opencode",
			DefaultLayout: "default",
			ClaudePrefix:  "claude",
			AutoFetch:     true,
			Projects:      make(map[string]ProjectConfig),
		}); err != nil {
			return err
		}
	}

	editor := os.Getenv("EDITOR")
	if editor == "" {
		editor = "vim"
	}

	return runCommand(editor, configPath)
}

func runConfigShowCmd(c *cli.Context) error {
	return runConfigShow()
}

func runConfigEditCmd(c *cli.Context) error {
	return runConfigEdit()
}

func runCommand(name string, args ...string) error {
	cmd := exec.Command(name, args...)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}
