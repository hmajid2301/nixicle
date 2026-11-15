package main

import (
	"errors"
	"fmt"
	"os"
	"strings"
	"time"

	sdk "github.com/MichaelKinsy/PiG/extensions/sdk"
)

type piSession struct{ ctx sdk.Context }

func (p piSession) SessionID() (string, error) { return p.ctx.GetSessionID() }

func (p piSession) SessionName() (string, error) {
	name, err := p.ctx.GetSessionName()
	if err != nil || name == nil {
		return "", err
	}
	return *name, nil
}

func (p piSession) SetSessionName(name string) error { return p.ctx.SetSessionName(name) }

func (p piSession) HasModel() bool { return p.ctx.Model() != "" }

func (p piSession) FirstUserPrompt() (string, error) {
	branch, err := p.ctx.GetBranch()
	if err != nil {
		return "", err
	}
	for _, entry := range branch {
		if entry.Type == "message" && entry.Role == "user" {
			return entry.Content, nil
		}
	}
	return "", nil
}

func (p piSession) Complete(system, prompt string) (string, string, error) {
	model, err := p.ctx.ModelRegistry().Find(p.ctx.ModelProvider(), p.ctx.Model())
	if err != nil {
		return "", "", err
	}
	if model == nil {
		return "", "", errors.New("active model not found")
	}
	request := map[string]any{
		"systemPrompt": system,
		"messages":     []any{map[string]any{"role": "user", "content": prompt, "timestamp": time.Now().UnixMilli()}},
	}
	result := p.ctx.ModelRegistry().StreamSimple(model, request, map[string]any{"maxTokens": 60}).Result()
	stop, _ := result["stopReason"].(string)
	if stop == "error" {
		if msg, _ := result["errorMessage"].(string); msg != "" {
			return "", "", errors.New(msg)
		}
	}
	var parts []string
	blocks, _ := result["content"].([]any)
	for _, block := range blocks {
		b, _ := block.(map[string]any)
		if b["type"] == "text" {
			if t, ok := b["text"].(string); ok {
				parts = append(parts, t)
			}
		}
	}
	return strings.Join(parts, " "), stop, nil
}

func (p piSession) Warn(message string) {
	if p.ctx.HasUI() {
		p.ctx.Notify(message, "warning")
	}
}

func main() {
	ext := sdk.New("session-name")
	n := newNamer()
	ext.OnEvent(sdk.EventAgentEnd, func(ctx sdk.Context, _ map[string]any) (any, error) {
		n.onAgentEnd(piSession{ctx: ctx})
		return nil, nil
	})
	if err := ext.Run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
