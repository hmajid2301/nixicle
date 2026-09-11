// Command agent-session-sync mirrors AI coding-agent transcripts from a remote
// machine to the local one, so losing the remote box does not lose the
// conversations running on it.
//
// Sync is pull-only and writes into a quarantine mirror that the agents never
// read. Promote is the only command that touches the live agent stores, and it
// compares content — not timestamps — before overwriting anything.
package main

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"strings"
	"syscall"
	"time"
)

const usage = `agent-session-sync — mirror remote agent transcripts locally

  pull <host>               one sync pass
  status                    what is mirrored, and how stale
  list <host>               mirrored sessions
  promote <host> <id>       copy one session into the live store
  daemon <host>             loop pull on an interval

env:
  AGENT_SYNC_MIRROR         default ~/.local/state/agent-session-sync
  AGENT_SYNC_MAP            default ~/.config/agent-session-sync/paths
  AGENT_SYNC_INTERVAL       default 15m
  AGENT_SYNC_STALE_AFTER    default 1h
`

func main() {
	if err := run(os.Args[1:]); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}

func run(args []string) error {
	verbose := false
	for i, a := range args {
		if a == "-v" || a == "--verbose" {
			verbose = true
			args = append(args[:i:i], args[i+1:]...)
			break
		}
	}
	if len(args) == 0 {
		fmt.Print(usage)
		os.Exit(1)
	}

	for _, bin := range []string{"ssh", "rsync"} {
		if _, err := exec.LookPath(bin); err != nil {
			return fmt.Errorf("%s not found in PATH", bin)
		}
	}

	home, err := os.UserHomeDir()
	if err != nil {
		return err
	}
	store := &Store{
		Root:    envOr("AGENT_SYNC_MIRROR", filepath.Join(home, ".local/state/agent-session-sync")),
		Home:    home,
		MapFile: envOr("AGENT_SYNC_MAP", filepath.Join(configDir(home), "agent-session-sync", "paths")),
		Verbose: verbose,
	}

	interval, err := durationEnv("AGENT_SYNC_INTERVAL", 15*time.Minute)
	if err != nil {
		return err
	}
	staleAfter, err := durationEnv("AGENT_SYNC_STALE_AFTER", time.Hour)
	if err != nil {
		return err
	}

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	switch args[0] {
	case "pull":
		host, err := hostArg(args, "pull <host>")
		if err != nil {
			return err
		}
		results, err := store.Pull(ctx, host)
		for _, r := range results {
			fmt.Printf("synced %-7s %s  (%d transcripts)\n", r.Agent, host, r.Transcripts)
		}
		return err

	case "status":
		return cmdStatus(store, staleAfter)

	case "list":
		host, err := hostArg(args, "list <host>")
		if err != nil {
			return err
		}
		return cmdList(store, host)

	case "promote":
		if len(args) < 3 {
			return fmt.Errorf("usage: agent-session-sync promote <host> <session-id>")
		}
		if err := validHost(args[1]); err != nil {
			return err
		}
		return cmdPromote(store, args[1], args[2])

	case "daemon":
		host, err := hostArg(args, "daemon <host>")
		if err != nil {
			return err
		}
		fmt.Printf("syncing %s every %s (mirror: %s)\n", host, interval, store.Root)
		return store.Daemon(ctx, host, interval)

	default:
		fmt.Print(usage)
		os.Exit(1)
		return nil
	}
}

func cmdStatus(store *Store, staleAfter time.Duration) error {
	hosts, err := store.Status(staleAfter)
	if err != nil {
		return err
	}
	if len(hosts) == 0 {
		fmt.Println("no mirror yet — run: agent-session-sync pull <host>")
		return nil
	}
	for _, h := range hosts {
		if h.LastSync.IsZero() {
			fmt.Printf("%-14s never synced\n", h.Host)
			continue
		}
		line := fmt.Sprintf("%-14s %4d transcripts   last sync %s ago",
			h.Host, h.Transcripts, humanAge(time.Since(h.LastSync)))
		if h.Stale {
			line += "   [STALE]"
		}
		fmt.Println(line)
	}
	return nil
}

func cmdList(store *Store, host string) error {
	sessions, err := store.Sessions(host)
	if err != nil {
		return err
	}
	if len(sessions) == 0 {
		fmt.Printf("no transcripts mirrored for %s\n", host)
		return nil
	}
	for _, s := range sessions {
		where := s.LocalCWD
		if where == "" {
			where = "(cwd unknown)"
		}
		kind := " "
		if s.IsSubagent() {
			kind = "+" // nested subagent transcript, not independently resumable
		}
		line := fmt.Sprintf("%s %-7s %-40s %7s  %s",
			kind, s.Agent, s.UUID, humanAge(time.Since(s.Modified)), where)
		switch {
		case s.RemoteCWD != "" && !s.Mapped:
			line += "  [unmapped]"
		case s.RemoteCWD != "" && !s.LocalDirExists():
			line += "  [no local dir]"
		}
		fmt.Println(line)
	}
	return nil
}

func cmdPromote(store *Store, host, id string) error {
	res, err := store.Promote(host, id)
	if err != nil {
		return err
	}

	switch {
	case res.Skipped && res.Relation == Same:
		fmt.Printf("skipped: identical (already promoted)\nlocal file: %s\n", res.Dest)
		return nil
	case res.Skipped && res.Relation == LocalAhead:
		fmt.Printf("skipped: local copy has continued beyond the mirror (%d vs %d lines)\n",
			CountLines(res.Dest), res.MirrorLines)
		fmt.Printf("nothing promoted. Local file: %s\n", res.Dest)
		return nil
	}

	if res.Relation == Diverged {
		fmt.Fprintf(os.Stderr, "WARNING: forked — both copies were appended to independently.\n")
		fmt.Fprintf(os.Stderr, "  local copy preserved at: %s\n", res.BackedUp)
		fmt.Fprintf(os.Stderr, "  promoting the mirror copy over it.\n")
	} else if res.BackedUp != "" {
		fmt.Printf("local copy was behind; backed it up to %s\n", filepath.Base(res.BackedUp))
	}

	if res.LocalCWD != "" {
		if st, err := os.Stat(res.LocalCWD); err != nil || !st.IsDir() {
			fmt.Fprintf(os.Stderr, "warning: %s does not exist locally — resume will not find the project\n", res.LocalCWD)
		}
	}

	fmt.Printf("promoted -> %s\n\n", res.Dest)
	fmt.Println("resume with:")
	if res.LocalCWD != "" {
		fmt.Printf("  cd %s\n", res.LocalCWD)
	}
	fmt.Printf("  %s\n", res.ResumeCmd)
	return nil
}

func hostArg(args []string, form string) (string, error) {
	if len(args) < 2 {
		return "", fmt.Errorf("usage: agent-session-sync %s", form)
	}
	if err := validHost(args[1]); err != nil {
		return "", err
	}
	return args[1], nil
}

// validHost keeps the host usable as a single path component in the mirror,
// so a stray "../" cannot steer writes outside it.
func validHost(h string) error {
	// Must be usable as a single mirror path component, and must not be
	// mistaken by ssh for an option.
	if h == "" || strings.ContainsAny(h, "/\\ \t") ||
		strings.HasPrefix(h, ".") || strings.HasPrefix(h, "-") {
		return fmt.Errorf("invalid host: %q", h)
	}
	return nil
}

func envOr(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

func configDir(home string) string {
	if v := os.Getenv("XDG_CONFIG_HOME"); v != "" {
		return v
	}
	return filepath.Join(home, ".config")
}

func durationEnv(key string, def time.Duration) (time.Duration, error) {
	v := os.Getenv(key)
	if v == "" {
		return def, nil
	}
	d, err := parseDuration(v)
	if err != nil {
		return 0, fmt.Errorf("%s: %v", key, err)
	}
	if d <= 0 {
		return 0, fmt.Errorf("%s must be positive, got %s", key, v)
	}
	return d, nil
}

func humanAge(d time.Duration) string {
	switch {
	case d < 90*time.Second:
		return fmt.Sprintf("%ds", int(d.Seconds()))
	case d < 90*time.Minute:
		return fmt.Sprintf("%dm", int(d.Minutes()))
	case d < 48*time.Hour:
		return fmt.Sprintf("%dh", int(d.Hours()))
	default:
		return fmt.Sprintf("%dd", int(d.Hours()/24))
	}
}
