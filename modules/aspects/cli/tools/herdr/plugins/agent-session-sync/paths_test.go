package main

import (
	"os"
	"path/filepath"
	"testing"
)

func TestSlugify(t *testing.T) {
	// Expectations checked against real directory names on disk.
	cases := []struct{ agent, path, want string }{
		{"claude", "/home/haseebmajid/projects/nala-workspace", "-home-haseebmajid-projects-nala-workspace"},
		{"pi", "/home/haseebmajid/projects/nala-backend", "--home-haseebmajid-projects-nala-backend--"},
		{"pi", "/home/haseebmajid", "--home-haseebmajid--"},
	}
	for _, c := range cases {
		if got := Slugify(c.agent, c.path); got != c.want {
			t.Errorf("Slugify(%q, %q) = %q, want %q", c.agent, c.path, got, c.want)
		}
	}
}

func TestRemapPathHomePrefix(t *testing.T) {
	const rh, lh = "/Users/you", "/home/me"
	got, ok := RemapPath("/Users/you/work/repo", rh, lh, nil)
	if !ok || got != "/home/me/work/repo" {
		t.Errorf("got %q (mapped=%v), want /home/me/work/repo", got, ok)
	}
}

// The bug the review demonstrated: remote home /home/u must not swallow the
// start of /home/username, which produced the garbage slug -home-mesername-x.
func TestRemapPathPrefixCollision(t *testing.T) {
	got, ok := RemapPath("/home/username/x", "/home/u", "/home/me", nil)
	if ok {
		t.Errorf("/home/username/x must not map under remote home /home/u, got %q", got)
	}
	if got != "/home/username/x" {
		t.Errorf("unmapped path must be returned unchanged, got %q", got)
	}
}

func TestRemapPathExplicitMappings(t *testing.T) {
	maps := []PathMapping{
		{Remote: "/home/other/work", Local: "/home/me/projects"},
		{Remote: "/home/other/work/special", Local: "/srv/special"},
	}
	cases := []struct {
		path, want string
		mapped     bool
	}{
		// Longest remote prefix wins over the broader parent mapping.
		{"/home/other/work/special/repo", "/srv/special/repo", true},
		{"/home/other/work/repo", "/home/me/projects/repo", true},
		// Falls back to the home prefix when no mapping matches.
		{"/home/other/elsewhere", "/home/me/elsewhere", true},
		// Outside the remote home entirely, and unmapped.
		{"/opt/thing", "/opt/thing", false},
	}
	for _, c := range cases {
		got, ok := RemapPath(c.path, "/home/other", "/home/me", maps)
		if got != c.want || ok != c.mapped {
			t.Errorf("RemapPath(%q) = %q,%v; want %q,%v", c.path, got, ok, c.want, c.mapped)
		}
	}
}

func TestRemapSlugPrefersCWD(t *testing.T) {
	maps := []PathMapping{{Remote: "/home/other/work", Local: "/home/me/projects"}}
	// The slug alone is ambiguous; the recorded cwd resolves it exactly.
	got, ok := RemapSlug("claude", "-home-other-work-repo", "/home/other/work/repo",
		"/home/other", "/home/me", maps)
	if !ok || got != "-home-me-projects-repo" {
		t.Errorf("got %q (mapped=%v), want -home-me-projects-repo", got, ok)
	}
}

func TestRemapSlugFallbackBoundary(t *testing.T) {
	cases := []struct {
		name, agent, slug, remoteHome, want string
		mapped                              bool
	}{
		{"claude maps", "claude", "-Users-you-projects-repo", "/Users/you", "-home-me-projects-repo", true},
		{"claude exact home", "claude", "-Users-you", "/Users/you", "-home-me", true},
		{"pi maps", "pi", "--Users-you-projects-repo--", "/Users/you", "--home-me-projects-repo--", true},
		// Boundary: must not match a partial segment.
		{"claude collision", "claude", "-home-username-x", "/home/u", "-home-username-x", false},
		{"pi collision", "pi", "--home-username-x--", "/home/u", "--home-username-x--", false},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			got, ok := RemapSlug(c.agent, c.slug, "", c.remoteHome, "/home/me", nil)
			if got != c.want || ok != c.mapped {
				t.Errorf("got %q,%v; want %q,%v", got, ok, c.want, c.mapped)
			}
		})
	}
}

func TestSessionUUID(t *testing.T) {
	cases := []struct{ agent, file, want string }{
		{"claude", "aaaaaaaa-1111-2222-3333-444444444444.jsonl", "aaaaaaaa-1111-2222-3333-444444444444"},
		{"pi", "2026-09-11T09-00-00-000Z_bbbb-5555.jsonl", "bbbb-5555"},
		// A claude filename is the uuid verbatim, even with an underscore.
		{"claude", "weird_name.jsonl", "weird_name"},
	}
	for _, c := range cases {
		if got := SessionUUID(c.agent, c.file); got != c.want {
			t.Errorf("SessionUUID(%q, %q) = %q, want %q", c.agent, c.file, got, c.want)
		}
	}
}

func TestLoadMappings(t *testing.T) {
	dir := t.TempDir()
	file := filepath.Join(dir, "paths")
	content := "# comment\n\n/home/other/work ~/projects\n~/srv /home/me/srv\n"
	if err := os.WriteFile(file, []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
	maps, err := LoadMappings(file, "/home/other", "/home/me")
	if err != nil {
		t.Fatal(err)
	}
	want := []PathMapping{
		{Remote: "/home/other/work", Local: "/home/me/projects"},
		{Remote: "/home/other/srv", Local: "/home/me/srv"},
	}
	if len(maps) != len(want) {
		t.Fatalf("got %d mappings, want %d: %+v", len(maps), len(want), maps)
	}
	for i := range want {
		if maps[i] != want[i] {
			t.Errorf("mapping %d = %+v, want %+v", i, maps[i], want[i])
		}
	}
}

func TestLoadMappingsMissingFileIsNotAnError(t *testing.T) {
	maps, err := LoadMappings(filepath.Join(t.TempDir(), "nope"), "/r", "/l")
	if err != nil || maps != nil {
		t.Errorf("missing mapping file should be silently empty, got %+v, %v", maps, err)
	}
}

func TestLoadMappingsMalformedLine(t *testing.T) {
	dir := t.TempDir()
	file := filepath.Join(dir, "paths")
	if err := os.WriteFile(file, []byte("only-one-field\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	if _, err := LoadMappings(file, "/r", "/l"); err == nil {
		t.Error("expected an error for a malformed mapping line")
	}
}
