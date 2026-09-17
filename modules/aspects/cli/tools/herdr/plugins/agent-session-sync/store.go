package main

import (
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"syscall"
	"time"
)

// Store is the local quarantine mirror. Nothing under here is read by the
// agents: sync writes only into the mirror, and Promote is the only operation
// that copies into the live agent stores. That separation is what makes it safe
// for a background daemon to run while you work locally.
type Store struct {
	Root    string // mirror root
	Home    string // local $HOME
	MapFile string
	Verbose bool
}

func (s *Store) hostDir(host string) string     { return filepath.Join(s.Root, host) }
func (s *Store) agentDir(host, a string) string { return filepath.Join(s.Root, host, a) }
func (s *Store) logPath() string                { return filepath.Join(s.Root, "sync.log") }

func (s *Store) logf(format string, args ...any) {
	if err := os.MkdirAll(s.Root, 0o700); err != nil {
		return
	}
	f, err := os.OpenFile(s.logPath(), os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o600)
	if err != nil {
		return
	}
	defer f.Close()
	fmt.Fprintf(f, "%s %s\n", time.Now().Format(time.RFC3339), fmt.Sprintf(format, args...))
}

// lockHost takes an exclusive lock so two daemons cannot race on the same
// host's mirror and duplicate every transfer.
func (s *Store) lockHost(host string) (func(), error) {
	if err := os.MkdirAll(s.Root, 0o700); err != nil {
		return nil, err
	}
	path := filepath.Join(s.Root, fmt.Sprintf(".daemon.%s.lock", host))
	f, err := os.OpenFile(path, os.O_CREATE|os.O_RDWR, 0o600)
	if err != nil {
		return nil, err
	}
	if err := syscall.Flock(int(f.Fd()), syscall.LOCK_EX|syscall.LOCK_NB); err != nil {
		f.Close()
		return nil, fmt.Errorf("a daemon is already running for %s", host)
	}
	return func() {
		syscall.Flock(int(f.Fd()), syscall.LOCK_UN)
		f.Close()
	}, nil
}

func (s *Store) writeRemoteHome(host, remoteHome string) error {
	dir := s.hostDir(host)
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return err
	}
	return os.WriteFile(filepath.Join(dir, ".remote-home"), []byte(remoteHome), 0o600)
}

func (s *Store) markSynced(host, remoteHome string) error {
	if err := s.writeRemoteHome(host, remoteHome); err != nil {
		return err
	}
	stamp := strconv.FormatInt(time.Now().Unix(), 10)
	return os.WriteFile(filepath.Join(s.hostDir(host), ".last-sync"), []byte(stamp), 0o600)
}

func (s *Store) remoteHome(host string) string {
	b, err := os.ReadFile(filepath.Join(s.hostDir(host), ".remote-home"))
	if err != nil {
		return s.Home
	}
	return strings.TrimSpace(string(b))
}

func (s *Store) lastSync(host string) time.Time {
	b, err := os.ReadFile(filepath.Join(s.hostDir(host), ".last-sync"))
	if err != nil {
		return time.Time{}
	}
	n, err := strconv.ParseInt(strings.TrimSpace(string(b)), 10, 64)
	if err != nil {
		return time.Time{} // corrupt stamp reads as "never", not as a crash
	}
	return time.Unix(n, 0)
}

func (s *Store) mappings(remoteHome string) []PathMapping {
	maps, err := LoadMappings(s.MapFile, remoteHome, s.Home)
	if err != nil {
		fmt.Fprintf(os.Stderr, "warning: %v\n", err)
		return nil
	}
	return maps
}

func (s *Store) countHostTranscripts(host string) int {
	n := 0
	for _, agent := range Agents {
		n += countTranscripts(s.agentDir(host, agent.Name))
	}
	return n
}

// Session is one mirrored transcript, resolved against the local machine.
type Session struct {
	Host       string
	Agent      string
	UUID       string
	MirrorPath string
	Slug       string // top-level session dir, i.e. the encoded project cwd
	SubPath    string // dir holding the file, relative to the agent root
	RemoteCWD  string
	LocalCWD   string
	Mapped     bool
	Modified   time.Time
}

// IsSubagent reports whether this is a nested subagent transcript rather than
// a top-level conversation. Those are not independently resumable.
func (s Session) IsSubagent() bool { return s.SubPath != s.Slug }

// LocalDirExists reports whether the project directory this session ran in is
// present locally — if not, resume will not find the project.
func (s Session) LocalDirExists() bool {
	if s.LocalCWD == "" {
		return false
	}
	st, err := os.Stat(s.LocalCWD)
	return err == nil && st.IsDir()
}

// Sessions lists every mirrored transcript for a host.
func (s *Store) Sessions(host string) ([]Session, error) {
	base := s.hostDir(host)
	if _, err := os.Stat(base); err != nil {
		return nil, fmt.Errorf("nothing mirrored for %s", host)
	}
	rhome := s.remoteHome(host)
	maps := s.mappings(rhome)

	var out []Session
	for _, agent := range Agents {
		adir := s.agentDir(host, agent.Name)
		// Walk the whole tree, not just <agent>/<slug>/*.jsonl. Both agents nest
		// subagent transcripts deeper — claude puts them under
		// <slug>/<uuid>/subagents/ — and those are the majority of files. rsync
		// already pulls them, so anything shallower here silently hides them
		// from list and promote.
		filepath.WalkDir(adir, func(p string, d os.DirEntry, err error) error {
			if err != nil {
				return nil
			}
			// Skip dot-directories: rsync scratch dirs and anything else not part
			// of the agent's own layout must never be listed or promotable.
			if d.IsDir() && strings.HasPrefix(d.Name(), ".") && p != adir {
				return filepath.SkipDir
			}
			if d.IsDir() || !strings.HasSuffix(d.Name(), ".jsonl") {
				return nil
			}
			rel, relErr := filepath.Rel(adir, p)
			if relErr != nil {
				return nil
			}
			slug := strings.Split(rel, string(filepath.Separator))[0]
			cwd := CWD(p)
			local, mapped := "", false
			if cwd != "" {
				local, mapped = RemapPath(cwd, rhome, s.Home, maps)
			}
			var mod time.Time
			if info, statErr := d.Info(); statErr == nil {
				mod = info.ModTime()
			}
			out = append(out, Session{
				Host: host, Agent: agent.Name,
				UUID:       SessionUUID(agent.Name, d.Name()),
				MirrorPath: p,
				Slug:       slug,
				SubPath:    filepath.Dir(rel),
				RemoteCWD:  cwd, LocalCWD: local, Mapped: mapped,
				Modified: mod,
			})
			return nil
		})
	}
	sort.Slice(out, func(i, j int) bool { return out[i].Modified.After(out[j].Modified) })
	return out, nil
}

// Find locates exactly one mirrored session by id substring.
func (s *Store) Find(host, id string) (Session, error) {
	// An empty id substring-matches every session, which would silently promote
	// an arbitrary one whenever the mirror happens to hold exactly one.
	if strings.TrimSpace(id) == "" {
		return Session{}, errors.New("session id must not be empty")
	}
	all, err := s.Sessions(host)
	if err != nil {
		return Session{}, err
	}
	var hits []Session
	for _, sess := range all {
		// Match against the resume id, not the whole filename: a pi filename
		// starts with a timestamp whose digits would match short hex ids.
		if strings.Contains(sess.UUID, id) {
			hits = append(hits, sess)
		}
	}
	switch len(hits) {
	case 0:
		return Session{}, fmt.Errorf("no mirrored session matching %q for %s", id, host)
	case 1:
		return hits[0], nil
	default:
		// Include the project, since two different projects can hold the same
		// uuid — in that case a longer id is impossible advice.
		var b strings.Builder
		fmt.Fprintf(&b, "ambiguous — %d matches:\n", len(hits))
		for _, h := range hits {
			fmt.Fprintf(&b, "  %-7s %-40s %s\n", h.Agent, h.UUID,
				orString(h.LocalCWD, h.Slug))
		}
		b.WriteString("use a longer session id, or a different host")
		return Session{}, errors.New(b.String())
	}
}

// PromoteResult describes what Promote did, so the caller can report it.
type PromoteResult struct {
	Dest        string
	Relation    Relation
	Skipped     bool
	BackedUp    string
	ResumeCmd   string
	LocalCWD    string
	MirrorLines int
}

// Promote copies one mirrored session into the live agent store.
//
// Conflict policy is content-based, never mtime: rsync stamps the mirror with
// the remote machine's clock, so an mtime comparison across two machines is
// only valid if their clocks agree. Whichever transcript strictly extends the
// other is the later one; if neither does, they forked and the local copy is
// preserved before the mirror overwrites it.
func (s *Store) Promote(host, id string) (PromoteResult, error) {
	// Exclude a concurrent pull for this host; the live-file guard below covers
	// the writer this lock cannot reach — the agent itself.
	unlock, err := s.lockHost(host)
	if err != nil {
		return PromoteResult{}, err
	}
	defer unlock()

	sess, err := s.Find(host, id)
	if err != nil {
		return PromoteResult{}, err
	}
	agent, ok := agentByName(sess.Agent)
	if !ok {
		return PromoteResult{}, fmt.Errorf("unknown agent %q", sess.Agent)
	}

	rhome := s.remoteHome(host)
	maps := s.mappings(rhome)
	lslug, mapped := RemapSlug(sess.Agent, sess.Slug, sess.RemoteCWD, rhome, s.Home, maps)

	// An unmapped slug is the remote machine's encoding of a path this machine
	// does not have. Writing it into the live store would put the transcript in
	// a directory the agent never reads, while reporting success — so refuse,
	// and tell the user exactly what to add to the mapping file.
	// Note this does not depend on the homes differing: a project outside the
	// remote home is unmapped even when both machines use the same home path,
	// and writing it under the remote slug would still be wrong.
	if !mapped {
		return PromoteResult{}, fmt.Errorf(
			"no local path known for %s\n  add a line to %s, e.g.:\n    %s  %s",
			orString(sess.RemoteCWD, sess.Slug), s.MapFile,
			orString(sess.RemoteCWD, "<remote-path>"), filepath.Join(s.Home, "path/to/project"))
	}

	// Only the leading slug is remapped; the rest of the relative path (e.g.
	// <uuid>/subagents) is structure the agent created and must be preserved.
	tail := strings.TrimPrefix(sess.SubPath, sess.Slug)
	destDir := filepath.Join(s.Home, agent.Root, lslug, tail)
	dest := filepath.Join(destDir, filepath.Base(sess.MirrorPath))

	res := PromoteResult{
		Dest:        dest,
		LocalCWD:    sess.LocalCWD,
		ResumeCmd:   fmt.Sprintf("%s --resume %s", sess.Agent, sess.UUID),
		MirrorLines: CountLines(sess.MirrorPath),
	}

	var guard fileGuard
	if existing, err := os.Stat(dest); err == nil && !existing.IsDir() {
		rel, err := Compare(dest, sess.MirrorPath)
		if err != nil {
			return res, err
		}
		res.Relation = rel
		switch rel {
		case Same, LocalAhead:
			res.Skipped = true
			return res, nil
		case MirrorAhead, Diverged:
			bak, err := backupPath(dest)
			if err != nil {
				return res, err
			}
			if err := copyFile(dest, bak); err != nil {
				return res, err
			}
			res.BackedUp = bak
			// Snapshot the live file as it was when compared and backed up. The
			// agent may be appending to it right now, and this program cannot
			// lock it — so verify it is unchanged immediately before overwriting
			// rather than silently discarding work written in that window.
			guard, err = guardOf(dest)
			if err != nil {
				return res, err
			}
		}
	}

	if err := os.MkdirAll(destDir, 0o700); err != nil {
		return res, err
	}
	if changed, err := guard.changed(dest); err != nil {
		return res, err
	} else if changed {
		return res, fmt.Errorf(
			"%s changed while promoting (the agent is probably still writing to it)\n"+
				"  nothing was overwritten; local copy also saved at %s\n"+
				"  close that session and retry", filepath.Base(dest), res.BackedUp)
	}
	// Never install fewer bytes than the live file already holds. A forked
	// mirror whose complete portion is shorter than the live copy would
	// otherwise silently drop local records — the backup makes that
	// recoverable, but the user is told "promoted" with no hint of loss.
	if guard.set {
		n, err := CompleteSize(sess.MirrorPath)
		if err != nil {
			return res, err
		}
		if n < guard.size {
			return res, fmt.Errorf(
				"refusing to shrink %s: the mirror holds %d complete bytes, the local copy has %d\n"+
					"  the two have diverged and the mirror is behind; local copy saved at %s\n"+
					"  inspect both before overwriting",
				filepath.Base(dest), n, guard.size, res.BackedUp)
		}
	}
	if _, err := copyWholeRecords(sess.MirrorPath, dest); err != nil {
		return res, err
	}
	s.logf("promote %s %s -> %s", host, sess.UUID, dest)
	return res, nil
}

// fileGuard records a file's identity at a point in time so a later write can
// confirm nothing else touched it in between.
type fileGuard struct {
	set   bool
	size  int64
	mtime time.Time
}

func guardOf(path string) (fileGuard, error) {
	st, err := os.Stat(path)
	if err != nil {
		return fileGuard{}, err
	}
	return fileGuard{set: true, size: st.Size(), mtime: st.ModTime()}, nil
}

func (g fileGuard) changed(path string) (bool, error) {
	if !g.set {
		return false, nil
	}
	st, err := os.Stat(path)
	if err != nil {
		if os.IsNotExist(err) {
			return true, nil
		}
		return false, err
	}
	return st.Size() != g.size || !st.ModTime().Equal(g.mtime), nil
}

func orString(s, fallback string) string {
	if s != "" {
		return s
	}
	return fallback
}

// backupPath picks a name that does not already exist. Two promotes inside the
// same second would otherwise share a timestamp and the second would overwrite
// the first backup — losing the very copy it was taken to protect.
func backupPath(dest string) (string, error) {
	base := fmt.Sprintf("%s.bak.%d", dest, time.Now().Unix())
	// O_EXCL rather than stat-then-create: two promotes in the same second must
	// not pick the same name and have the second clobber the first's backup.
	for i := 0; i < 1000; i++ {
		p := base
		if i > 0 {
			p = fmt.Sprintf("%s-%d", base, i+1)
		}
		f, err := os.OpenFile(p, os.O_CREATE|os.O_EXCL|os.O_WRONLY, 0o600)
		if err == nil {
			f.Close()
			return p, nil
		}
		if !os.IsExist(err) {
			return "", err
		}
	}
	return "", fmt.Errorf("could not find a free backup name for %s", dest)
}

// copyFile streams src to dst and renames into place only once the copy is
// complete. Transcripts reach tens of megabytes, so reading one wholly into
// memory is wasteful; more importantly, a crash partway through a direct write
// would leave a truncated transcript at the live path — the same torn-file
// hazard the transfer stage takes care to avoid.
// copyWholeRecords copies src to dst, stopping at the last newline so a
// transcript captured mid-write never lands as a torn final record.
func copyWholeRecords(src, dst string) (int64, error) {
	n, err := CompleteSize(src)
	if err != nil {
		return 0, err
	}
	if n == 0 {
		return 0, fmt.Errorf("%s contains no complete record", filepath.Base(src))
	}
	return n, copyFileN(src, dst, n)
}

func copyFile(src, dst string) error { return copyFileN(src, dst, -1) }

// copyFileN streams at most limit bytes (all of them when limit < 0) and
// renames into place only once the copy is complete, so a crash partway cannot
// leave a truncated transcript at the live path.
func copyFileN(src, dst string, limit int64) error {
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()
	var r io.Reader = in
	if limit >= 0 {
		r = io.LimitReader(in, limit)
	}
	return writeAtomic(dst, r, src)
}

func writeAtomic(dst string, r io.Reader, srcForTimes string) error {

	tmp, err := os.CreateTemp(filepath.Dir(dst), ".tmp-*")
	if err != nil {
		return err
	}
	tmpName := tmp.Name()
	defer os.Remove(tmpName) // no-op once renamed

	if _, err := io.Copy(tmp, r); err != nil {
		tmp.Close()
		return err
	}
	if err := tmp.Sync(); err != nil {
		tmp.Close()
		return err
	}
	if err := tmp.Close(); err != nil {
		return err
	}
	if err := os.Chmod(tmpName, 0o600); err != nil {
		return err
	}
	if info, err := os.Stat(srcForTimes); err == nil {
		os.Chtimes(tmpName, info.ModTime(), info.ModTime())
	}
	return os.Rename(tmpName, dst)
}

// HostStatus summarises one mirrored host.
type HostStatus struct {
	Host        string
	LastSync    time.Time
	Transcripts int
	Stale       bool
}

func (s *Store) Status(staleAfter time.Duration) ([]HostStatus, error) {
	entries, err := os.ReadDir(s.Root)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, nil
		}
		return nil, err
	}
	var out []HostStatus
	for _, e := range entries {
		if !e.IsDir() || strings.HasPrefix(e.Name(), ".") {
			continue // not a host directory
		}
		host := e.Name()
		last := s.lastSync(host)
		st := HostStatus{
			Host:     host,
			LastSync: last,
			// Count only the known agent roots, matching what Sessions lists.
			// Walking the whole host dir would count strays under an unrecognised
			// agent name and over-report how much is actually recoverable.
			Transcripts: s.countHostTranscripts(host),
		}
		if !last.IsZero() && time.Since(last) > staleAfter {
			st.Stale = true
		}
		out = append(out, st)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].Host < out[j].Host })
	return out, nil
}
