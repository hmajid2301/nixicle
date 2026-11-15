package main

import (
	"bufio"
	"encoding/json"
	"errors"
	"os"
	"reflect"
	"slices"
	"testing"
)

func replay(t *testing.T, fixture string, waitErr error) []map[string]any {
	t.Helper()
	f, err := os.Open("testdata/" + fixture)
	if err != nil {
		t.Fatal(err)
	}
	defer f.Close()
	var events []map[string]any
	r := newRelay(map[string]any{"id": "claude-sonnet-5-5", "api": apiID, "provider": providerID}, 1, func(ev map[string]any) {
		events = append(events, ev)
	})
	r.start()
	sc := bufio.NewScanner(f)
	sc.Buffer(make([]byte, 1<<20), 1<<20)
	for sc.Scan() {
		r.handle(sc.Bytes())
	}
	r.finish(false, waitErr, "")
	return events
}

func types(events []map[string]any) []string {
	var out []string
	for _, ev := range events {
		if t := ev["type"].(string); len(out) == 0 || out[len(out)-1] != t {
			out = append(out, t)
		}
	}
	return out
}

func TestRelayText(t *testing.T) {
	events := replay(t, "text.jsonl", nil)
	want := []string{"start", "text_start", "text_delta", "text_end", "done"}
	if got := types(events); !reflect.DeepEqual(got, want) {
		t.Fatalf("events = %v, want %v", got, want)
	}
	done := events[len(events)-1]
	msg := done["message"].(map[string]any)
	content := msg["content"].([]any)
	if len(content) != 1 || content[0].(map[string]any)["text"] != "Hello there, friend!" {
		t.Fatalf("content = %v", content)
	}
	if done["reason"] != "stop" || msg["stopReason"] != "stop" {
		t.Fatalf("stop = %v / %v", done["reason"], msg["stopReason"])
	}
	usage := msg["usage"].(map[string]any)
	want2 := map[string]int{"input": 2, "output": 10, "cacheRead": 649, "cacheWrite": 2991, "totalTokens": 3652}
	for k, v := range want2 {
		if usage[k] != v {
			t.Errorf("usage[%s] = %v, want %d", k, usage[k], v)
		}
	}
}

func TestRelayThinking(t *testing.T) {
	events := replay(t, "thinking.jsonl", nil)
	want := []string{"start", "thinking_start", "thinking_delta", "thinking_end", "text_start", "text_delta", "text_end", "done"}
	if got := types(events); !reflect.DeepEqual(got, want) {
		t.Fatalf("events = %v, want %v", got, want)
	}
	content := events[len(events)-1]["message"].(map[string]any)["content"].([]any)
	thinking := content[0].(map[string]any)
	if thinking["type"] != "thinking" || thinking["thinking"] == "" || thinking["thinkingSignature"] != "sig-fixture" {
		t.Fatalf("thinking block = %v", thinking)
	}
	for _, ev := range events {
		if ev["type"] == "text_delta" && ev["contentIndex"] != 1 {
			t.Fatalf("text delta index = %v, want 1", ev["contentIndex"])
		}
	}
}

func TestRelayResultError(t *testing.T) {
	events := replay(t, "error.jsonl", errors.New("exit status 1"))
	last := events[len(events)-1]
	if last["type"] != "error" || last["reason"] != "error" {
		t.Fatalf("last = %v", last)
	}
	msg := last["error"].(map[string]any)["errorMessage"].(string)
	if msg == "" || msg[:8] != "claude: " {
		t.Fatalf("errorMessage = %q", msg)
	}
}

func TestRelayFinish(t *testing.T) {
	cases := []struct {
		name    string
		aborted bool
		waitErr error
		stderr  string
		reason  string
		message string
	}{
		{"aborted wins over exit error", true, errors.New("killed"), "", "aborted", "aborted"},
		{"exit error includes stderr", false, errors.New("exit status 2"), " boom \n", "error", "claude exited: exit status 2: boom"},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			var last map[string]any
			r := newRelay(map[string]any{}, 1, func(ev map[string]any) { last = ev })
			r.finish(c.aborted, c.waitErr, c.stderr)
			msg := last["error"].(map[string]any)
			if last["reason"] != c.reason || msg["errorMessage"] != c.message {
				t.Fatalf("got %v %v", last["reason"], msg["errorMessage"])
			}
		})
	}
}

func TestRelayMaxTokens(t *testing.T) {
	var last map[string]any
	r := newRelay(map[string]any{}, 1, func(ev map[string]any) { last = ev })
	r.handle([]byte(`{"type":"stream_event","event":{"type":"message_delta","delta":{"stop_reason":"max_tokens"}}}`))
	r.handle([]byte(`not json`))
	r.finish(false, nil, "")
	if last["type"] != "done" || last["reason"] != "length" {
		t.Fatalf("last = %v", last)
	}
}

func TestRelayIgnoresUnknownBlocks(t *testing.T) {
	var events []map[string]any
	r := newRelay(map[string]any{}, 1, func(ev map[string]any) { events = append(events, ev) })
	for _, line := range []string{
		`{"type":"stream_event","event":{"type":"content_block_start","index":0,"content_block":{"type":"tool_use"}}}`,
		`{"type":"stream_event","event":{"type":"content_block_delta","index":0,"delta":{"type":"input_json_delta"}}}`,
		`{"type":"stream_event","event":{"type":"content_block_stop","index":0}}`,
		`{"type":"stream_event","event":{"type":"content_block_delta","index":5,"delta":{"type":"text_delta","text":"x"}}}`,
	} {
		r.handle([]byte(line))
	}
	if len(events) != 0 || len(r.content) != 0 {
		t.Fatalf("events = %v content = %v", events, r.content)
	}
}

func TestFlatten(t *testing.T) {
	cases := []struct {
		name       string
		transcript map[string]any
		system     string
		prompt     string
	}{
		{
			"single user message is sent verbatim",
			map[string]any{"systemPrompt": "sys", "messages": []any{map[string]any{"role": "user", "content": "hi"}}},
			"sys", "hi",
		},
		{
			"multi turn is tagged by role and skips empty and non-text parts",
			map[string]any{"messages": []any{
				map[string]any{"role": "user", "content": []any{map[string]any{"type": "text", "text": "a"}, map[string]any{"type": "image", "data": "x"}}},
				map[string]any{"role": "assistant", "content": []any{map[string]any{"type": "thinking", "thinking": "t"}, map[string]any{"type": "text", "text": "b"}}},
				map[string]any{"role": "assistant", "content": []any{map[string]any{"type": "toolCall"}}},
				map[string]any{"role": "user", "content": "c"},
			}},
			"", "<user>\na\n</user>\n<assistant>\nb\n</assistant>\n<user>\nc\n</user>\n",
		},
		{
			"single non-empty message after empty ones is verbatim",
			map[string]any{"messages": []any{map[string]any{"role": "assistant", "content": []any{}}, map[string]any{"role": "user", "content": "q"}}},
			"", "q",
		},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			system, prompt := flatten(c.transcript)
			if system != c.system || prompt != c.prompt {
				t.Fatalf("got (%q, %q), want (%q, %q)", system, prompt, c.system, c.prompt)
			}
		})
	}
}

func TestCliArgs(t *testing.T) {
	cases := []struct {
		name    string
		system  string
		options map[string]any
		effort  string
		summary bool
	}{
		{"no reasoning uses low effort without summaries", "", nil, "low", false},
		{"minimal maps to low without summaries", "", map[string]any{"reasoning": "minimal"}, "low", false},
		{"low asks for summaries", "", map[string]any{"reasoning": "low"}, "low", true},
		{"high is forwarded", "s", map[string]any{"reasoning": "high"}, "high", true},
		{"max is forwarded", "", map[string]any{"reasoning": "max"}, "max", true},
		{"unknown level is dropped", "", map[string]any{"reasoning": "bogus"}, "", false},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			args := cliArgs("claude-opus-5-5", c.system, c.options)
			if i := slices.Index(args, "--model"); args[i+1] != "claude-opus-5-5" {
				t.Fatalf("model arg = %v", args)
			}
			i := slices.Index(args, "--effort")
			if c.effort == "" && i >= 0 || c.effort != "" && (i < 0 || args[i+1] != c.effort) {
				t.Fatalf("effort args = %v, want %q", args, c.effort)
			}
			if got := slices.Contains(args, "--settings"); got != c.summary {
				t.Fatalf("settings args = %v, want summary %v", args, c.summary)
			}
			i = slices.Index(args, "--system-prompt")
			if c.system == "" && i >= 0 || c.system != "" && (i < 0 || args[i+1] != c.system) {
				t.Fatalf("system args = %v", args)
			}
		})
	}
}

func TestSummarizedThinkingSettings(t *testing.T) {
	var settings struct {
		Env map[string]string `json:"env"`
	}
	if err := json.Unmarshal([]byte(summarizedThinking), &settings); err != nil {
		t.Fatal(err)
	}
	var body map[string]map[string]string
	if err := json.Unmarshal([]byte(settings.Env["CLAUDE_CODE_EXTRA_BODY"]), &body); err != nil {
		t.Fatal(err)
	}
	if body["thinking"]["type"] != "adaptive" || body["thinking"]["display"] != "summarized" {
		t.Fatalf("body = %v", body)
	}
}

func TestCliEnvDropsAPIKey(t *testing.T) {
	got := cliEnv([]string{"HOME=/h", "ANTHROPIC_API_KEY=secret", "ANTHROPIC_API_KEY_HELPER=x"})
	want := []string{"HOME=/h", "ANTHROPIC_API_KEY_HELPER=x"}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("got %v, want %v", got, want)
	}
}

func TestModelsShareTSProviderIDs(t *testing.T) {
	for _, m := range models() {
		if m["provider"] != providerID || m["api"] != apiID {
			t.Fatalf("model %v", m)
		}
	}
}
