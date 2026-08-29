---
name: zellij
description: Use the local Zellij CLI to inspect and control sessions, tabs, and panes.
---

# Zellij

Use this skill whenever you need to inspect or control Zellij.

## Rules

- Prefer the `zellij` CLI directly.
- Be careful with commands that send keys, create panes/tabs, detach clients, or mutate layouts.
- Prefer read-only inspection first.
- If the user asks to monitor a running task, prefer reading pane output over sending input.

## Common commands

### Sessions

- List sessions:

```bash
zellij list-sessions
```

### Tabs

- List tabs for the current session as JSON:

```bash
zellij action list-tabs -j
```

### Panes

- List panes for the current session as JSON:

```bash
zellij action list-panes -j -a -c -g -s -t
```

Useful fields usually include pane id, title, tab name, cwd, focus state, and floating state.

### Current tab

- Show current tab info:

```bash
zellij action current-tab-info -j
```

### Read pane contents

- Dump a pane including scrollback:

```bash
zellij action dump-screen -p <pane-id> -f
```

- Dump only the visible viewport:

```bash
zellij action dump-screen -p <pane-id>
```

## Mutating commands

Use these only when the user asked for changes.

### New pane

Split right:

```bash
zellij action new-pane --direction right
```

Split down:

```bash
zellij action new-pane --direction down
```

Run a command in a new pane:

```bash
zellij action new-pane --direction right -- bash -c '<command>'
```

Create a floating pane:

```bash
zellij action new-pane --floating --name notes -- bash -c 'exec $SHELL'
```

### New tab

```bash
zellij action new-tab --name logs
```

With a layout:

```bash
zellij action new-tab --name dev --layout ~/.config/zellij/layouts/dev.kdl
```

### Send input

Send raw text:

```bash
zellij action write-chars --pane-id <pane-id> 'echo hello'
```

Paste multiline text:

```bash
zellij action paste --pane-id <pane-id> 'line 1
line 2'
```

Send special keys:

```bash
zellij action send-keys --pane-id <pane-id> Enter
zellij action send-keys --pane-id <pane-id> Ctrl c
zellij action send-keys --pane-id <pane-id> Escape
```

## Session targeting

If you need to act on a specific session, set:

```bash
export ZELLIJ_SESSION_NAME='<session>'
```

Then run the same `zellij action ...` commands.

## Suggested workflow

1. Inspect sessions.
2. Inspect tabs or panes.
3. Read pane output.
4. Only then send input or create panes/tabs if needed.

When summarizing for the user, mention the session, tab, pane id, and cwd you acted on.
