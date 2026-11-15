package main

import (
	"errors"
	"testing"
)

type fakeSession struct {
	id, name, prompt string
	noModel          bool
	requests         int
	warnings         int
	gotPrompt        string
	complete         func(*fakeSession) (string, string, error)
}

func (f *fakeSession) SessionID() (string, error)       { return f.id, nil }
func (f *fakeSession) SessionName() (string, error)     { return f.name, nil }
func (f *fakeSession) SetSessionName(n string) error    { f.name = n; return nil }
func (f *fakeSession) FirstUserPrompt() (string, error) { return f.prompt, nil }
func (f *fakeSession) HasModel() bool                   { return !f.noModel }
func (f *fakeSession) Warn(string)                      { f.warnings++ }

func (f *fakeSession) Complete(_, prompt string) (string, string, error) {
	f.requests++
	f.gotPrompt = prompt
	if f.complete != nil {
		return f.complete(f)
	}
	return `"Fix login bug"`, "stop", nil
}

func TestNamesUnnamedSessionOnce(t *testing.T) {
	n, s := newNamer(), &fakeSession{id: "first", prompt: "Fix the login bug"}
	n.onAgentEnd(s)
	n.onAgentEnd(s)
	if s.name != "Fix login bug" || s.requests != 1 {
		t.Fatalf("name=%q requests=%d", s.name, s.requests)
	}
}

func TestPreservesExistingName(t *testing.T) {
	n, s := newNamer(), &fakeSession{id: "first", prompt: "Fix login", name: "My title"}
	n.onAgentEnd(s)
	if s.name != "My title" || s.requests != 0 {
		t.Fatalf("name=%q requests=%d", s.name, s.requests)
	}
}

func TestSkipsEmptyPromptAndMissingModel(t *testing.T) {
	n, s := newNamer(), &fakeSession{id: "first", prompt: "   "}
	n.onAgentEnd(s)
	s.prompt, s.noModel = "Fix login", true
	n.onAgentEnd(s)
	if s.requests != 0 {
		t.Fatalf("requests=%d", s.requests)
	}
}

func TestNamesNewSessionInSameProcess(t *testing.T) {
	n, s := newNamer(), &fakeSession{id: "first", prompt: "Fix login"}
	n.onAgentEnd(s)
	s.id, s.name = "second", ""
	n.onAgentEnd(s)
	if s.name != "Fix login bug" || s.requests != 2 {
		t.Fatalf("name=%q requests=%d", s.name, s.requests)
	}
}

func TestKeepsManualNameSetDuringGeneration(t *testing.T) {
	n := newNamer()
	s := &fakeSession{id: "first", prompt: "Fix login", complete: func(f *fakeSession) (string, string, error) {
		f.name = "Manual title"
		return "Generated title", "stop", nil
	}}
	n.onAgentEnd(s)
	if s.name != "Manual title" {
		t.Fatalf("name=%q", s.name)
	}
}

func TestDoesNotNameDifferentSession(t *testing.T) {
	n := newNamer()
	s := &fakeSession{id: "first", prompt: "Fix login", complete: func(f *fakeSession) (string, string, error) {
		f.id, f.name = "second", ""
		return "Wrong title", "stop", nil
	}}
	n.onAgentEnd(s)
	if s.name != "" {
		t.Fatalf("name=%q", s.name)
	}
}

func TestModelFailureWarnsOnceWithoutRetry(t *testing.T) {
	n := newNamer()
	s := &fakeSession{id: "first", prompt: "Fix login", complete: func(*fakeSession) (string, string, error) {
		return "", "", errors.New("No credentials")
	}}
	n.onAgentEnd(s)
	n.onAgentEnd(s)
	if s.name != "" || s.requests != 1 || s.warnings != 1 {
		t.Fatalf("name=%q requests=%d warnings=%d", s.name, s.requests, s.warnings)
	}
}

func TestRejectsFailedModelOutput(t *testing.T) {
	for _, stop := range []string{"error", "aborted"} {
		n := newNamer()
		s := &fakeSession{id: "first", prompt: "Fix login", complete: func(*fakeSession) (string, string, error) {
			return "Partial title", stop, nil
		}}
		n.onAgentEnd(s)
		if s.name != "" {
			t.Fatalf("%s: name=%q", stop, s.name)
		}
	}
}

func TestTruncatesPromptTo4000UTF16Units(t *testing.T) {
	long := ""
	for range 4100 {
		long += "a"
	}
	n, s := newNamer(), &fakeSession{id: "first", prompt: long}
	n.onAgentEnd(s)
	if len(s.gotPrompt) != 4000 {
		t.Fatalf("prompt length=%d", len(s.gotPrompt))
	}
}

func TestCleanTitle(t *testing.T) {
	for in, want := range map[string]string{
		`"Fix login bug"`:             "Fix login bug",
		"  Fix\n  the   login bug.  ": "Fix the login bug",
		"`Refactor auth`!?":           "Refactor auth",
		"'''":                         "",
		"Emoji 😀 title":               "Emoji 😀 title",
	} {
		if got := cleanTitle(in); got != want {
			t.Errorf("cleanTitle(%q)=%q want %q", in, got, want)
		}
	}
	if got := truncateUTF16("😀😀", 3); got != "😀" {
		t.Errorf("truncateUTF16 surrogate split: %q", got)
	}
}
