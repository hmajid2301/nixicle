package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"strings"
	"time"

	sdk "github.com/MichaelKinsy/PiG/extensions/sdk"
)

func stream(m map[string]any, transcript map[string]any, opts sdk.ProviderStreamOptions) (*sdk.ModelEventStream, error) {
	s := sdk.CreateAssistantMessageEventStream()
	r := newRelay(m, time.Now().UnixMilli(), s.Push)
	system, prompt := flatten(transcript)
	cmd := exec.CommandContext(opts.Signal, "claude", cliArgs(fmt.Sprint(m["id"]), system, opts.Values)...)
	cmd.Stdin = strings.NewReader(prompt)
	cmd.Env = cliEnv(os.Environ())
	var stderr strings.Builder
	cmd.Stderr = &stderr
	out, err := cmd.StdoutPipe()
	if err == nil {
		err = cmd.Start()
	}
	if err != nil {
		r.fail("error", err.Error())
		return s, nil
	}
	go func() {
		r.start()
		sc := bufio.NewScanner(out)
		sc.Buffer(make([]byte, 1<<20), 64<<20)
		for sc.Scan() {
			r.handle(sc.Bytes())
		}
		werr := cmd.Wait()
		r.finish(opts.Signal.Err() != nil, werr, stderr.String())
	}()
	return s, nil
}

func checkAuth(in sdk.APIKeyAuthInput) (*sdk.AuthCheck, error) {
	out, err := exec.CommandContext(in.Signal, "claude", "auth", "status").Output()
	var status struct {
		LoggedIn bool `json:"loggedIn"`
	}
	if err != nil || json.Unmarshal(out, &status) != nil || !status.LoggedIn {
		return nil, nil
	}
	src := "Claude Code CLI"
	return &sdk.AuthCheck{Type: "api_key", Source: &src}, nil
}

func main() {
	ext := sdk.New(providerID)
	src := "Claude Code CLI"
	p := &sdk.Provider{
		ID:   providerID,
		Name: "Claude Code",
		Auth: sdk.ProviderAuth{APIKey: &sdk.APIKeyAuth{
			Name:  "Claude Code login",
			Check: checkAuth,
			Resolve: func(sdk.APIKeyAuthInput) (*sdk.AuthResult, error) {
				return &sdk.AuthResult{Auth: map[string]any{"apiKey": "external-process"}, Source: &src}, nil
			},
		}},
		GetModels:    func() ([]map[string]any, error) { return models(), nil },
		Stream:       stream,
		StreamSimple: stream,
	}
	if err := ext.RegisterNativeProvider(p); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(2)
	}
	if err := ext.Run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
