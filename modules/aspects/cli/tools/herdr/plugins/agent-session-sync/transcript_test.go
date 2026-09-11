package main

import (
	"os"
	"path/filepath"
	"testing"
)

func write(t *testing.T, dir, name, content string) string {
	t.Helper()
	p := filepath.Join(dir, name)
	if err := os.WriteFile(p, []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
	return p
}

func TestCompare(t *testing.T) {
	dir := t.TempDir()
	base := write(t, dir, "base.jsonl", "{\"n\":1}\n{\"n\":2}\n")
	same := write(t, dir, "same.jsonl", "{\"n\":1}\n{\"n\":2}\n")
	ahead := write(t, dir, "ahead.jsonl", "{\"n\":1}\n{\"n\":2}\n{\"n\":3}\n")
	fork := write(t, dir, "fork.jsonl", "{\"n\":1}\n{\"n\":9}\n")
	forkLong := write(t, dir, "forklong.jsonl", "{\"n\":1}\n{\"n\":2}\n{\"n\":8}\n{\"n\":9}\n")

	cases := []struct {
		name          string
		local, mirror string
		want          Relation
	}{
		{"identical", base, same, Same},
		{"local extends mirror", ahead, base, LocalAhead},
		{"mirror extends local", base, ahead, MirrorAhead},
		// Same length, different content: a fork, not a match.
		{"same size diverged", fork, base, Diverged},
		// Mirror is longer but does not extend local: still a fork.
		{"longer but diverged", fork, forkLong, Diverged},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			got, err := Compare(c.local, c.mirror)
			if err != nil {
				t.Fatal(err)
			}
			if got != c.want {
				t.Errorf("Compare = %v, want %v", got, c.want)
			}
		})
	}
}

// A transcript truncated mid-line must not be mistaken for a clean prefix of
// itself-plus-more; it should still compare as an extension, since the bytes
// really are a prefix. This documents the intended behaviour.
func TestCompareTruncatedIsPrefix(t *testing.T) {
	dir := t.TempDir()
	full := write(t, dir, "full.jsonl", "{\"n\":1}\n{\"n\":2}\n")
	torn := write(t, dir, "torn.jsonl", "{\"n\":1}\n{\"n\"")
	got, err := Compare(torn, full)
	if err != nil {
		t.Fatal(err)
	}
	if got != MirrorAhead {
		t.Errorf("Compare = %v, want MirrorAhead", got)
	}
}

func TestCWD(t *testing.T) {
	dir := t.TempDir()
	p := write(t, dir, "s.jsonl",
		"{\"type\":\"user\",\"cwd\":\"/home/other/projects/repo\"}\n")
	if got := CWD(p); got != "/home/other/projects/repo" {
		t.Errorf("CWD = %q", got)
	}
}

// An interrupted transfer can leave a torn line. One bad line must not stop
// the scan from finding a cwd on a later line.
func TestCWDSkipsUnparseableLines(t *testing.T) {
	dir := t.TempDir()
	p := write(t, dir, "s.jsonl",
		"not json at all\n{\"trunc\":\n{\"type\":\"user\",\"cwd\":\"/home/other/x\"}\n")
	if got := CWD(p); got != "/home/other/x" {
		t.Errorf("CWD = %q, want /home/other/x", got)
	}
}

func TestCWDAbsentIsEmpty(t *testing.T) {
	dir := t.TempDir()
	p := write(t, dir, "s.jsonl", "{\"type\":\"user\"}\n")
	if got := CWD(p); got != "" {
		t.Errorf("CWD = %q, want empty", got)
	}
}

func TestCountLines(t *testing.T) {
	dir := t.TempDir()
	p := write(t, dir, "s.jsonl", "a\nb\nc\n")
	if got := CountLines(p); got != 3 {
		t.Errorf("CountLines = %d, want 3", got)
	}
}
