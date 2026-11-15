package main

import (
	"encoding/json"
	"fmt"
	"strings"
)

const (
	providerID = "claude-code"
	apiID      = "claude-code-stream-json"
)

var efforts = map[string]string{
	"":        "low",
	"minimal": "low",
	"low":     "low",
	"medium":  "medium",
	"high":    "high",
	"xhigh":   "xhigh",
	"max":     "max",
}

func fullEffortMap(allowOff bool) map[string]any {
	m := map[string]any{"minimal": nil, "low": "low", "medium": "medium", "high": "high", "xhigh": "xhigh", "max": "max"}
	if !allowOff {
		m["off"] = nil
	}
	return m
}

func model(id, name string, levels map[string]any) map[string]any {
	return map[string]any{
		"id":               id,
		"name":             name,
		"api":              apiID,
		"provider":         providerID,
		"baseUrl":          "process://claude-code",
		"reasoning":        true,
		"thinkingLevelMap": levels,
		"input":            []string{"text"},
		"cost":             map[string]any{"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0},
		"contextWindow":    1000000,
		"maxTokens":        128000,
	}
}

func models() []map[string]any {
	fable := map[string]any{"off": nil, "xhigh": "xhigh", "max": "max"}
	return []map[string]any{
		model("default", "Default (Claude Code)", fullEffortMap(false)),
		model("claude-opus-5-5", "Claude Opus 5.5", fullEffortMap(false)),
		model("claude-sonnet-5-5", "Claude Sonnet 5.5", fullEffortMap(false)),
		model("claude-haiku-5-5", "Claude Haiku 5.5", fullEffortMap(true)),
		model("claude-fable-5-2", "Claude Fable 5.2", fable),
	}
}

func textOf(content any) string {
	switch c := content.(type) {
	case string:
		return c
	case []any:
		var b strings.Builder
		for _, part := range c {
			p, _ := part.(map[string]any)
			if p["type"] == "text" {
				t, _ := p["text"].(string)
				b.WriteString(t)
			}
		}
		return b.String()
	}
	return ""
}

func flatten(transcript map[string]any) (system, prompt string) {
	system, _ = transcript["systemPrompt"].(string)
	msgs, _ := transcript["messages"].([]any)
	type turn struct{ role, text string }
	var turns []turn
	for _, m := range msgs {
		mm, _ := m.(map[string]any)
		role, _ := mm["role"].(string)
		if text := textOf(mm["content"]); text != "" {
			turns = append(turns, turn{role, text})
		}
	}
	if len(turns) == 1 {
		return system, turns[0].text
	}
	var b strings.Builder
	for _, t := range turns {
		fmt.Fprintf(&b, "<%s>\n%s\n</%s>\n", t.role, t.text, t.role)
	}
	return system, b.String()
}

const summarizedThinking = `{"env":{"CLAUDE_CODE_EXTRA_BODY":"{\"thinking\":{\"type\":\"adaptive\",\"display\":\"summarized\"}}"}}`

func cliArgs(modelID, system string, options map[string]any) []string {
	args := []string{
		"-p",
		"--output-format", "stream-json",
		"--verbose",
		"--include-partial-messages",
		"--model", modelID,
		"--tools", "",
		"--strict-mcp-config",
		"--setting-sources", "",
		"--no-session-persistence",
		"--disable-slash-commands",
	}
	level, _ := options["reasoning"].(string)
	if effort := efforts[level]; effort != "" {
		args = append(args, "--effort", effort)
	}
	if level != "" && level != "minimal" && efforts[level] != "" {
		args = append(args, "--settings", summarizedThinking)
	}
	if system != "" {
		args = append(args, "--system-prompt", system)
	}
	return args
}

func cliEnv(environ []string) []string {
	env := make([]string, 0, len(environ))
	for _, kv := range environ {
		if !strings.HasPrefix(kv, "ANTHROPIC_API_KEY=") {
			env = append(env, kv)
		}
	}
	return env
}

type relay struct {
	msg       map[string]any
	content   []any
	blocks    map[int]int
	stop      string
	resultErr string
	emit      func(map[string]any)
}

func newRelay(m map[string]any, timestamp int64, emit func(map[string]any)) *relay {
	return &relay{
		emit:   emit,
		blocks: map[int]int{},
		stop:   "stop",
		msg: map[string]any{
			"role": "assistant", "api": m["api"], "provider": m["provider"], "model": m["id"], "timestamp": timestamp,
			"usage": map[string]any{
				"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0, "totalTokens": 0,
				"cost": map[string]any{"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0, "total": 0},
			},
		},
		content: []any{},
	}
}

func (r *relay) partial() map[string]any {
	r.msg["content"] = r.content
	return r.msg
}

func (r *relay) push(ev map[string]any) {
	ev["partial"] = r.partial()
	r.emit(ev)
}

func (r *relay) start() { r.push(map[string]any{"type": "start"}) }

func (r *relay) block(ev map[string]any) (int, map[string]any, bool) {
	native, _ := ev["index"].(float64)
	idx, ok := r.blocks[int(native)]
	if !ok {
		return 0, nil, false
	}
	return idx, r.content[idx].(map[string]any), true
}

func (r *relay) handle(line []byte) {
	var msg map[string]any
	if json.Unmarshal(line, &msg) != nil {
		return
	}
	switch msg["type"] {
	case "stream_event":
		ev, _ := msg["event"].(map[string]any)
		r.handleEvent(ev)
	case "result":
		if isErr, _ := msg["is_error"].(bool); isErr {
			r.resultErr = fmt.Sprint(msg["result"])
		}
		if u, ok := msg["usage"].(map[string]any); ok {
			r.setUsage(u)
		}
	}
}

func (r *relay) handleEvent(ev map[string]any) {
	switch ev["type"] {
	case "message_start":
		r.blocks = map[int]int{}
	case "content_block_start":
		cb, _ := ev["content_block"].(map[string]any)
		native, _ := ev["index"].(float64)
		idx := len(r.content)
		switch cb["type"] {
		case "text":
			r.blocks[int(native)] = idx
			r.content = append(r.content, map[string]any{"type": "text", "text": ""})
			r.push(map[string]any{"type": "text_start", "contentIndex": idx})
		case "thinking":
			r.blocks[int(native)] = idx
			r.content = append(r.content, map[string]any{"type": "thinking", "thinking": "", "thinkingSignature": ""})
			r.push(map[string]any{"type": "thinking_start", "contentIndex": idx})
		}
	case "content_block_delta":
		idx, blk, ok := r.block(ev)
		if !ok {
			return
		}
		d, _ := ev["delta"].(map[string]any)
		switch d["type"] {
		case "text_delta":
			t, _ := d["text"].(string)
			blk["text"] = blk["text"].(string) + t
			r.push(map[string]any{"type": "text_delta", "contentIndex": idx, "delta": t})
		case "thinking_delta":
			t, _ := d["thinking"].(string)
			blk["thinking"] = blk["thinking"].(string) + t
			r.push(map[string]any{"type": "thinking_delta", "contentIndex": idx, "delta": t})
		case "signature_delta":
			sig, _ := d["signature"].(string)
			blk["thinkingSignature"] = blk["thinkingSignature"].(string) + sig
		}
	case "content_block_stop":
		idx, blk, ok := r.block(ev)
		if !ok {
			return
		}
		if blk["type"] == "text" {
			r.push(map[string]any{"type": "text_end", "contentIndex": idx, "content": blk["text"]})
		} else {
			r.push(map[string]any{"type": "thinking_end", "contentIndex": idx, "content": blk["thinking"]})
		}
	case "message_delta":
		d, _ := ev["delta"].(map[string]any)
		if reason, _ := d["stop_reason"].(string); reason == "max_tokens" {
			r.stop = "length"
		}
	}
}

func (r *relay) setUsage(u map[string]any) {
	num := func(k string) int { f, _ := u[k].(float64); return int(f) }
	in, out := num("input_tokens"), num("output_tokens")
	cacheRead, cacheWrite := num("cache_read_input_tokens"), num("cache_creation_input_tokens")
	usage := r.msg["usage"].(map[string]any)
	usage["input"], usage["output"], usage["cacheRead"], usage["cacheWrite"] = in, out, cacheRead, cacheWrite
	usage["totalTokens"] = in + out + cacheRead + cacheWrite
}

func (r *relay) fail(reason, message string) {
	r.msg["stopReason"], r.msg["errorMessage"] = reason, message
	r.emit(map[string]any{"type": "error", "reason": reason, "error": r.partial()})
}

func (r *relay) finish(aborted bool, waitErr error, stderr string) {
	switch {
	case aborted:
		r.fail("aborted", "aborted")
	case r.resultErr != "":
		r.fail("error", "claude: "+r.resultErr)
	case waitErr != nil:
		r.fail("error", fmt.Sprintf("claude exited: %v: %s", waitErr, strings.TrimSpace(stderr)))
	default:
		r.msg["stopReason"] = r.stop
		r.emit(map[string]any{"type": "done", "reason": r.stop, "message": r.partial()})
	}
}
