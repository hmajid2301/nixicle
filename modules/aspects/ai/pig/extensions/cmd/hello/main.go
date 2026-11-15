package main

import (
	"fmt"
	"os"

	sdk "github.com/MichaelKinsy/PiG/extensions/sdk"
)

func echoText(params map[string]any) (string, error) {
	text, _ := params["text"].(string)
	if text == "" {
		return "", fmt.Errorf("text is required")
	}
	return fmt.Sprintf("hello: %s", text), nil
}

func main() {
	ext := sdk.New("hello")

	ext.Tool("hello_echo", "Echo a string back", sdk.Schema{
		"type": "object",
		"properties": map[string]any{
			"text": map[string]any{
				"type":        "string",
				"description": "The text to echo",
			},
		},
		"required": []string{"text"},
	}, func(_ sdk.Context, params map[string]any) (any, error) {
		msg, err := echoText(params)
		if err != nil {
			return nil, err
		}
		return map[string]any{"content": msg}, nil
	})

	ext.Command("hello", "Send a hello notification", func(ctx sdk.Context, _ string) error {
		ctx.Notify("hello from pig", "info")
		return nil
	})

	if err := ext.Run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
