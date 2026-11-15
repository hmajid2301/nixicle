package main

import "testing"

func TestEchoText(t *testing.T) {
	got, err := echoText(map[string]any{"text": "world"})
	if err != nil {
		t.Fatal(err)
	}
	if got != "hello: world" {
		t.Fatalf("echoText() = %q, want %q", got, "hello: world")
	}

	if _, err := echoText(map[string]any{}); err == nil {
		t.Fatal("echoText() with an empty text should return an error")
	}
}
