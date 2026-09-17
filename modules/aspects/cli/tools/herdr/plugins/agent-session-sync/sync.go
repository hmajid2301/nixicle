package main

import (
	"context"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

// sshExitConnFailure is ssh's own exit code for "could not connect", as
// distinct from the remote command returning non-zero. The difference matters:
// a missing directory is normal, a dead connection is not.
const sshExitConnFailure = 255

var errUnreachable = errors.New("host unreachable")

// baseSSHArgs keeps connection behaviour identical between the probe and the
// rsync transport. Shelling out to the system ssh (rather than using a Go SSH
// library) means ~/.ssh/config, ControlMaster, agent forwarding and every
// configured auth method keep working untouched.
func baseSSHArgs() []string {
	return []string{
		"-o", "BatchMode=yes",
		"-o", "ConnectTimeout=10",
		// ConnectTimeout only covers the handshake. Keepalives are what catch a
		// host that accepts the connection and then stalls — the wedged-box case.
		"-o", "ServerAliveInterval=15",
		"-o", "ServerAliveCountMax=3",
	}
}

// sshCommandTimeout bounds a single probe. cmdTimeout bounds one rsync run, so
// a stalled transfer cannot hang the daemon past its next tick.
const (
	sshCommandTimeout = 30 * time.Second
	rsyncTimeout      = 30 * time.Minute
)

// shellQuote wraps s in single quotes for a POSIX shell, escaping any embedded
// single quote. Needed because ssh concatenates its command arguments into one
// string for the remote shell rather than passing them as separate argv items.
func shellQuote(s string) string {
	return "'" + strings.ReplaceAll(s, "'", `'\''`) + "'"
}

// RemoteHome asks the remote what its home directory is. Only the last line is
// taken, so a login shell that prints a banner does not corrupt the answer.
func RemoteHome(ctx context.Context, host string) (string, error) {
	ctx, cancel := context.WithTimeout(ctx, sshCommandTimeout)
	defer cancel()
	args := append(baseSSHArgs(), "--", host, "printf '%s\\n' \"$HOME\"")
	out, err := exec.CommandContext(ctx, "ssh", args...).Output()
	if err != nil {
		return "", fmt.Errorf("%w: %v", errUnreachable, err)
	}
	lines := strings.Split(strings.TrimSpace(string(out)), "\n")
	home := strings.TrimSpace(lines[len(lines)-1])
	if home == "" || !strings.HasPrefix(home, "/") {
		return "", fmt.Errorf("%w: implausible home %q", errUnreachable, home)
	}
	return home, nil
}

// remoteDirExists probes for a directory.
//
// ssh does not bind extra argv entries as positional parameters — it joins them
// onto the command string with spaces. So `test -d "$1" _ <path>` reaches the
// remote shell as literally that, and test fails with "too many arguments",
// making every probe report "absent". The path must instead be quoted into the
// command by us; shellQuote makes that safe for paths containing quotes.
func remoteDirExists(ctx context.Context, host, dir string) (bool, error) {
	ctx, cancel := context.WithTimeout(ctx, sshCommandTimeout)
	defer cancel()
	args := append(baseSSHArgs(), "--", host, "test -d "+shellQuote(dir))
	err := exec.CommandContext(ctx, "ssh", args...).Run()
	if err == nil {
		return true, nil
	}
	var ee *exec.ExitError
	if errors.As(err, &ee) {
		if ee.ExitCode() == sshExitConnFailure {
			return false, fmt.Errorf("%w: ssh probe failed", errUnreachable)
		}
		return false, nil // directory simply absent
	}
	return false, err
}

// rsyncArgs builds the transfer.
//
// Filter order is load-bearing: rsync applies rules first-match-wins, so the
// excludes must precede the `--include */` that lets it walk into directories.
// With the includes first, every directory exclusion below is unreachable.
//
// --partial-dir rather than --partial: an interrupted transfer must never leave
// a truncated file at the real destination path, because rsync cuts mid-line
// and a torn transcript could then be promoted into the live store.
func rsyncArgs(src, dst string) []string {
	// --append-verify treats the mirror as append-only: it extends a file whose
	// existing bytes still checksum-match, and never shrinks one. Without it a
	// remote-side truncation (disk corruption, an errant sed -i, an agent bug)
	// propagates into the mirror and destroys the last surviving copy.
	//
	// It cannot be combined with --partial-dir — rsync rejects the pair outright
	// ("--append cannot be used with --partial-dir"). Append-only wins: an
	// interrupted transfer leaves a torn tail at the real path, which is benign
	// here because Compare treats a torn file as a valid prefix and promote
	// strips the partial record via CompleteSize. Losing the last copy is not
	// benign, so the shrink protection is the one worth keeping.
	args := []string{"-az", "--append-verify", "--prune-empty-dirs"}
	for _, ex := range []string{
		"tmp/", "npm/", "node_modules/", "paste-cache/", "shell-snapshots/",
		"file-history/", ".credentials.json", "auth.json", "*.db", "*.db-*", "*.log",
	} {
		args = append(args, "--exclude", ex)
	}
	args = append(args, "--include", "*/", "--include", "*.jsonl", "--exclude", "*")
	args = append(args, "-e", "ssh "+strings.Join(baseSSHArgs(), " "), src, dst)
	return args
}

// PullResult reports what one sync pass achieved.
type PullResult struct {
	Agent       string
	Transcripts int
}

// Pull mirrors every agent's transcripts from host into the local mirror.
// It never writes into the live agent stores — that is promote's job alone.
func (s *Store) Pull(ctx context.Context, host string) ([]PullResult, error) {
	// The lock belongs here, not only in Daemon: a manual pull run alongside a
	// running daemon would otherwise put two rsyncs on the same tree and race
	// the .last-sync write.
	unlock, err := s.lockHost(host)
	if err != nil {
		return nil, err
	}
	defer unlock()
	return s.pullLocked(ctx, host)
}

func (s *Store) pullLocked(ctx context.Context, host string) ([]PullResult, error) {
	home, err := RemoteHome(ctx, host)
	if err != nil {
		return nil, err
	}

	var results []PullResult
	var probed, syncFailed bool

	for _, agent := range Agents {
		remoteDir := filepath.Join(home, agent.Root)
		ok, err := remoteDirExists(ctx, host, remoteDir)
		if err != nil {
			if errors.Is(err, errUnreachable) {
				syncFailed = true
				continue
			}
			return results, err
		}
		probed = true
		if !ok {
			continue // agent not used on that box
		}

		dst := s.agentDir(host, agent.Name)
		if err := os.MkdirAll(dst, 0o700); err != nil {
			return results, err
		}
		src := fmt.Sprintf("%s:%s/", host, remoteDir)
		args := rsyncArgs(src, dst)
		if s.Verbose {
			fmt.Fprintf(os.Stderr, "+ rsync %s\n", strings.Join(args, " "))
		}
		rctx, cancel := context.WithTimeout(ctx, rsyncTimeout)
		cmd := exec.CommandContext(rctx, "rsync", args...)
		out, err := cmd.CombinedOutput()
		cancel()
		if err != nil {
			syncFailed = true
			s.logf("pull %s/%s: rsync failed: %v: %s", host, agent.Name, err, strings.TrimSpace(string(out)))
			continue
		}
		results = append(results, PullResult{Agent: agent.Name, Transcripts: countTranscripts(dst)})
	}

	// A pass that transferred nothing is not a success. A wedged host whose
	// sshd answers but whose filesystem is hung would otherwise report healthy
	// forever and keep resetting the daemon's backoff.
	if !probed {
		return results, fmt.Errorf("%w: no agent directories reachable", errUnreachable)
	}
	if len(results) == 0 {
		if syncFailed {
			return results, errors.New("all transfers failed")
		}
		return results, errors.New("no agent session directories present on host")
	}

	// Only stamp .last-sync when every agent succeeded. Otherwise one healthy
	// agent keeps the timestamp fresh while another silently fails every pass,
	// and status never shows [STALE] for the data that is not being backed up.
	if !syncFailed {
		if err := s.markSynced(host, home); err != nil {
			return results, err
		}
	} else if err := s.writeRemoteHome(host, home); err != nil {
		return results, err
	}
	for _, r := range results {
		s.logf("pull %s/%s: ok, %d transcripts", host, r.Agent, r.Transcripts)
	}
	return results, syncErrIfPartial(syncFailed)
}

func syncErrIfPartial(failed bool) error {
	if failed {
		return errors.New("some agents failed to sync")
	}
	return nil
}

// countTranscripts counts only what Sessions would list, so status cannot
// over-report how much is actually recoverable.
func countTranscripts(dir string) int {
	n := 0
	filepath.WalkDir(dir, func(p string, d os.DirEntry, err error) error {
		if err != nil {
			return nil
		}
		if d.IsDir() && strings.HasPrefix(d.Name(), ".") && p != dir {
			return filepath.SkipDir
		}
		if !d.IsDir() && strings.HasSuffix(d.Name(), ".jsonl") {
			n++
		}
		return nil
	})
	return n
}

// Daemon pulls on an interval until the context is cancelled. Consecutive
// failures back off linearly up to 4x the interval, so a dead host does not
// spin ssh, but it never gives up — the box may come back.
// The lock is taken per pass, not for the daemon's lifetime: holding it
// between ticks would make promote — the one command that recovers your data —
// permanently unavailable while the daemon runs.
func (s *Store) Daemon(ctx context.Context, host string, interval time.Duration) error {
	s.logf("daemon start: %s every %s", host, interval)
	defer s.logf("daemon stop: %s", host)

	fails := 0
	for {
		results, err := s.Pull(ctx, host) // takes and releases the lock per pass
		if ctx.Err() != nil {
			return nil
		}
		wait := interval
		if err != nil {
			fails++
			if fails > 4 {
				fails = 4
			}
			wait = interval * time.Duration(fails)
			fmt.Fprintf(os.Stderr, "pull %s failed: %v (retry in %s)\n", host, err, wait)
			s.logf("daemon: %d consecutive failures, waiting %s", fails, wait)
		} else {
			fails = 0
			for _, r := range results {
				fmt.Printf("synced %-7s %s  (%d transcripts)\n", r.Agent, host, r.Transcripts)
			}
		}
		select {
		case <-ctx.Done():
			return nil
		case <-time.After(wait):
		}
	}
}

func parseDuration(s string) (time.Duration, error) {
	if n, err := strconv.Atoi(s); err == nil {
		return time.Duration(n) * time.Second, nil
	}
	return time.ParseDuration(s)
}
