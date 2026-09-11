package main

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

// Both agents nest subagent transcripts below <slug>/. On a real store those
// nested files outnumber the top-level ones several times over, so a listing
// that only walks <agent>/<slug>/*.jsonl silently hides most of the data.
func TestSessionsFindsNestedTranscripts(t *testing.T) {
	root := t.TempDir()
	home := t.TempDir()
	slug := "-home-me-projects-repo"
	agentRoot := filepath.Join(root, "wb", "claude", slug)

	files := []string{
		"top.jsonl",
		filepath.Join("top", "subagents", "agent-a.jsonl"),
		filepath.Join("top", "subagents", "workflows", "wf_1", "agent-b.jsonl"),
	}
	for _, f := range files {
		p := filepath.Join(agentRoot, f)
		if err := os.MkdirAll(filepath.Dir(p), 0o755); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(p, []byte(`{"cwd":"/home/me/projects/repo"}`+"\n"), 0o644); err != nil {
			t.Fatal(err)
		}
	}
	if err := os.WriteFile(filepath.Join(root, "wb", ".remote-home"), []byte("/home/me"), 0o644); err != nil {
		t.Fatal(err)
	}

	s := &Store{Root: root, Home: home, MapFile: filepath.Join(root, "no-such-map")}
	sessions, err := s.Sessions("wb")
	if err != nil {
		t.Fatal(err)
	}
	if len(sessions) != len(files) {
		var got []string
		for _, x := range sessions {
			got = append(got, x.UUID)
		}
		t.Fatalf("found %d transcripts, want %d: %v", len(sessions), len(files), got)
	}

	byUUID := map[string]Session{}
	for _, x := range sessions {
		byUUID[x.UUID] = x
	}
	if s := byUUID["top"]; s.IsSubagent() {
		t.Error("top-level transcript must not be flagged as a subagent")
	}
	for _, id := range []string{"agent-a", "agent-b"} {
		if !byUUID[id].IsSubagent() {
			t.Errorf("%s should be flagged as a subagent", id)
		}
	}
	// The nested path below the slug is structure the agent created; promote
	// has to rebuild it verbatim under the remapped slug.
	if got := byUUID["agent-b"].SubPath; got != filepath.Join(slug, "top", "subagents", "workflows", "wf_1") {
		t.Errorf("SubPath = %q", got)
	}
	if got := byUUID["agent-b"].Slug; got != slug {
		t.Errorf("Slug = %q, want %q", got, slug)
	}
}

func TestPromotePreservesNestedPath(t *testing.T) {
	root := t.TempDir()
	home := t.TempDir()
	slug := "-home-me-projects-repo"
	nested := filepath.Join(root, "wb", "claude", slug, "top", "subagents")
	if err := os.MkdirAll(nested, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(nested, "agent-a.jsonl"),
		[]byte(`{"cwd":"/home/me/projects/repo"}`+"\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, "wb", ".remote-home"), []byte("/home/me"), 0o644); err != nil {
		t.Fatal(err)
	}

	s := &Store{Root: root, Home: home, MapFile: filepath.Join(root, "no-such-map")}
	res, err := s.Promote("wb", "agent-a")
	if err != nil {
		t.Fatal(err)
	}
	wantSuffix := filepath.Join(Slugify("claude", filepath.Join(home, "projects/repo")),
		"top", "subagents", "agent-a.jsonl")
	if !strings.HasSuffix(res.Dest, wantSuffix) {
		t.Errorf("promoted to %q, want it to end with %q", res.Dest, wantSuffix)
	}
	if _, err := os.Stat(res.Dest); err != nil {
		t.Errorf("promoted file not present: %v", err)
	}
}

// A crash partway through must not leave a truncated transcript at the live
// path, so the copy lands via a temp file and a rename.
func TestCopyFileIsAtomicAndStreams(t *testing.T) {
	dir := t.TempDir()
	src := filepath.Join(dir, "src.jsonl")
	dst := filepath.Join(dir, "dst.jsonl")
	body := strings.Repeat(`{"n":1}`+"\n", 50000)
	if err := os.WriteFile(src, []byte(body), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := copyFile(src, dst); err != nil {
		t.Fatal(err)
	}
	got, err := os.ReadFile(dst)
	if err != nil {
		t.Fatal(err)
	}
	if string(got) != body {
		t.Errorf("copied %d bytes, want %d", len(got), len(body))
	}
	// No temp files left behind.
	entries, _ := os.ReadDir(dir)
	for _, e := range entries {
		if strings.HasPrefix(e.Name(), ".tmp-") {
			t.Errorf("leftover temp file: %s", e.Name())
		}
	}
}

// mkMirror builds a fake mirror holding one transcript with the given cwd.
func mkMirror(t *testing.T, cwd, remoteHome, slug string) (root, home string) {
	t.Helper()
	root, home = t.TempDir(), t.TempDir()
	dir := filepath.Join(root, "wb", "claude", slug)
	if err := os.MkdirAll(dir, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, "sess-1.jsonl"),
		[]byte(`{"cwd":"`+cwd+`"}`+"\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, "wb", ".remote-home"),
		[]byte(remoteHome), 0o644); err != nil {
		t.Fatal(err)
	}
	return root, home
}

// A transcript whose project path cannot be mapped locally must not be written
// into the live store under the remote machine's slug, where the agent would
// never find it.
func TestPromoteRefusesUnmappedPath(t *testing.T) {
	root, home := mkMirror(t, "/opt/work/repo", "/home/other", "-opt-work-repo")
	s := &Store{Root: root, Home: home, MapFile: filepath.Join(root, "none")}
	if _, err := s.Promote("wb", "sess-1"); err == nil {
		t.Fatal("expected promote to refuse an unmapped path")
	}
	if _, err := os.Stat(filepath.Join(home, ".claude/projects/-opt-work-repo")); err == nil {
		t.Error("promote created a directory under the remote-derived slug")
	}
}

// Truncated files parked by rsync must be invisible to both list and promote.
func TestSessionsSkipsPartialTransfers(t *testing.T) {
	root, home := mkMirror(t, "/home/other/repo", "/home/other", "-home-other-repo")
	part := filepath.Join(root, "wb", "claude", ".rsync-partial")
	if err := os.MkdirAll(part, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(part, "torn.jsonl"), []byte(`{"cwd":"/x"`), 0o644); err != nil {
		t.Fatal(err)
	}
	s := &Store{Root: root, Home: home, MapFile: filepath.Join(root, "none")}
	sessions, err := s.Sessions("wb")
	if err != nil {
		t.Fatal(err)
	}
	for _, x := range sessions {
		if strings.Contains(x.MirrorPath, ".rsync-partial") {
			t.Errorf("listed an incomplete transfer: %s", x.MirrorPath)
		}
	}
	if len(sessions) != 1 {
		t.Errorf("got %d sessions, want 1", len(sessions))
	}
	if n := countTranscripts(filepath.Join(root, "wb")); n != 1 {
		t.Errorf("countTranscripts = %d, want 1 (status must agree with list)", n)
	}
}

// A local transcript that has continued past the mirror must survive untouched.
func TestPromoteLocalAheadLeavesLiveFileIntact(t *testing.T) {
	root, home := mkMirror(t, "/home/other/repo", "/home/other", "-home-other-repo")
	s := &Store{Root: root, Home: home, MapFile: filepath.Join(root, "none")}

	live := filepath.Join(home, ".claude/projects",
		Slugify("claude", filepath.Join(home, "repo")), "sess-1.jsonl")
	if err := os.MkdirAll(filepath.Dir(live), 0o755); err != nil {
		t.Fatal(err)
	}
	body := `{"cwd":"/home/other/repo"}` + "\n" + `{"local":"newer"}` + "\n"
	if err := os.WriteFile(live, []byte(body), 0o644); err != nil {
		t.Fatal(err)
	}

	res, err := s.Promote("wb", "sess-1")
	if err != nil {
		t.Fatal(err)
	}
	if !res.Skipped || res.Relation != LocalAhead {
		t.Errorf("got skipped=%v relation=%v, want skipped LocalAhead", res.Skipped, res.Relation)
	}
	got, _ := os.ReadFile(live)
	if string(got) != body {
		t.Error("live transcript was modified despite being ahead of the mirror")
	}
}

// When both sides advanced independently, the local bytes must be preserved.
func TestPromoteDivergedBacksUpLocalBytes(t *testing.T) {
	root, home := mkMirror(t, "/home/other/repo", "/home/other", "-home-other-repo")
	mirror := filepath.Join(root, "wb", "claude", "-home-other-repo", "sess-1.jsonl")
	if err := os.WriteFile(mirror,
		[]byte(`{"cwd":"/home/other/repo"}`+"\n"+`{"remote":"x"}`+"\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	s := &Store{Root: root, Home: home, MapFile: filepath.Join(root, "none")}

	live := filepath.Join(home, ".claude/projects",
		Slugify("claude", filepath.Join(home, "repo")), "sess-1.jsonl")
	if err := os.MkdirAll(filepath.Dir(live), 0o755); err != nil {
		t.Fatal(err)
	}
	localBody := `{"cwd":"/home/other/repo"}` + "\n" + `{"local":"DIFFERENT"}` + "\n"
	if err := os.WriteFile(live, []byte(localBody), 0o644); err != nil {
		t.Fatal(err)
	}

	res, err := s.Promote("wb", "sess-1")
	if err != nil {
		t.Fatal(err)
	}
	if res.Relation != Diverged {
		t.Fatalf("relation = %v, want Diverged", res.Relation)
	}
	if res.BackedUp == "" {
		t.Fatal("diverged promote must back up the local copy")
	}
	got, err := os.ReadFile(res.BackedUp)
	if err != nil {
		t.Fatal(err)
	}
	if string(got) != localBody {
		t.Error("backup does not contain the original local bytes")
	}
}

func TestFindRejectsEmptyID(t *testing.T) {
	root, home := mkMirror(t, "/home/other/repo", "/home/other", "-home-other-repo")
	s := &Store{Root: root, Home: home, MapFile: filepath.Join(root, "none")}
	if _, err := s.Find("wb", ""); err == nil {
		t.Error("an empty id must not match an arbitrary session")
	}
}

// The exclude rules must precede --include '*/', or rsync's first-match-wins
// filtering makes every directory exclusion unreachable.
func TestRsyncArgsExcludesPrecedeIncludes(t *testing.T) {
	args := rsyncArgs("host:/src/", "/dst/")

	firstInclude, dirExclude := -1, -1
	for i, a := range args {
		if a == "--include" && firstInclude < 0 {
			firstInclude = i
		}
		if a == "--exclude" && i+1 < len(args) && args[i+1] == "tmp/" {
			dirExclude = i
		}
	}
	if firstInclude < 0 || dirExclude < 0 {
		t.Fatalf("expected both --exclude tmp/ and --include in args: %v", args)
	}
	if dirExclude > firstInclude {
		t.Errorf("directory excludes must precede the first --include, else rsync's "+
			"first-match-wins filtering makes them unreachable; args: %v", args)
	}

	// The terminal --exclude '*' must be the last filter rule, so only .jsonl
	// files can ever transfer.
	lastFilter := -1
	for i, a := range args {
		if a == "--exclude" || a == "--include" {
			lastFilter = i
		}
	}
	if args[lastFilter] != "--exclude" || args[lastFilter+1] != "*" {
		t.Errorf("last filter rule must be --exclude '*', got %s %s",
			args[lastFilter], args[lastFilter+1])
	}

	joined := strings.Join(args, " ")
	for _, want := range []string{"--exclude tmp/", "--exclude auth.json", "--include *.jsonl"} {
		if !strings.Contains(joined, want) {
			t.Errorf("missing %q in %v", want, args)
		}
	}
}

// A transcript captured while the agent was mid-write ends partway through a
// JSON object. Promoting it verbatim would install a corrupt final record.
func TestPromoteTruncatesTornFinalLine(t *testing.T) {
	root, home := mkMirror(t, "/home/other/repo", "/home/other", "-home-other-repo")
	mirror := filepath.Join(root, "wb", "claude", "-home-other-repo", "sess-1.jsonl")
	whole := `{"cwd":"/home/other/repo"}` + "\n" + `{"n":2}` + "\n"
	if err := os.WriteFile(mirror, []byte(whole+`{"n":3,"tor`), 0o644); err != nil {
		t.Fatal(err)
	}
	s := &Store{Root: root, Home: home, MapFile: filepath.Join(root, "none")}
	res, err := s.Promote("wb", "sess-1")
	if err != nil {
		t.Fatal(err)
	}
	got, err := os.ReadFile(res.Dest)
	if err != nil {
		t.Fatal(err)
	}
	if string(got) != whole {
		t.Errorf("promoted %q, want the torn final line dropped (%q)", got, whole)
	}
	for _, line := range strings.Split(strings.TrimRight(string(got), "\n"), "\n") {
		if !json.Valid([]byte(line)) {
			t.Errorf("installed an invalid JSON line: %q", line)
		}
	}
}

// A mirror holding no complete record at all must not be installed.
func TestPromoteRefusesFileWithNoCompleteRecord(t *testing.T) {
	root, home := mkMirror(t, "/home/other/repo", "/home/other", "-home-other-repo")
	mirror := filepath.Join(root, "wb", "claude", "-home-other-repo", "sess-1.jsonl")
	if err := os.WriteFile(mirror, []byte(`{"cwd":"/home/other/repo","tor`), 0o644); err != nil {
		t.Fatal(err)
	}
	s := &Store{Root: root, Home: home, MapFile: filepath.Join(root, "none")}
	if _, err := s.Promote("wb", "sess-1"); err == nil {
		t.Error("expected promote to refuse a file with no complete record")
	}
}

func TestCompleteSize(t *testing.T) {
	dir := t.TempDir()
	cases := []struct {
		name, body string
		want       int64
	}{
		{"whole records", "a\nb\n", 4},
		{"torn tail", "a\nb\nccc", 4},
		{"no newline at all", "abc", 0},
		{"empty", "", 0},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			p := filepath.Join(dir, "f")
			if err := os.WriteFile(p, []byte(c.body), 0o644); err != nil {
				t.Fatal(err)
			}
			got, err := CompleteSize(p)
			if err != nil {
				t.Fatal(err)
			}
			if got != c.want {
				t.Errorf("CompleteSize(%q) = %d, want %d", c.body, got, c.want)
			}
		})
	}
}

// The agent may append to the live transcript between the backup and the
// overwrite. That work must not be silently discarded.
func TestPromoteAbortsIfLiveFileChangesMidway(t *testing.T) {
	dir := t.TempDir()
	live := filepath.Join(dir, "s.jsonl")
	if err := os.WriteFile(live, []byte("a\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	g, err := guardOf(live)
	if err != nil {
		t.Fatal(err)
	}
	if changed, err := g.changed(live); err != nil || changed {
		t.Fatalf("untouched file reported changed=%v err=%v", changed, err)
	}
	// Simulate the agent appending.
	f, err := os.OpenFile(live, os.O_APPEND|os.O_WRONLY, 0o644)
	if err != nil {
		t.Fatal(err)
	}
	f.WriteString("USER-WORK\n")
	f.Close()
	os.Chtimes(live, time.Now().Add(time.Second), time.Now().Add(time.Second))

	changed, err := g.changed(live)
	if err != nil {
		t.Fatal(err)
	}
	if !changed {
		t.Error("a concurrent append must be detected before overwriting")
	}
}
