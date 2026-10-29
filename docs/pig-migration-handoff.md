# Handoff: move from Pi to PiG and port extensions to Go

## Latest recheck: 2026-10-24

This section supersedes conflicting claims in the original 2026-10-13 handoff
below. This was a source/documentation recheck, not a runtime compatibility test.
No Nix commands, builds, logins, or extension spikes were run. The local extension
inventory below was not re-audited.

### Versions to target

- **Latest Pi release:** [`v1.4.0`](https://github.com/earendil-works/pi/releases/tag/v1.4.0),
  commit `4a080252f06caf63a525d7873c5d94d3c23887e0`.
- **Latest PiG release:** [`v0.5.3`](https://github.com/MichaelKinsy/PiG/releases/tag/v0.5.3),
  commit `526c86df885eba5e214355e7f70205e06d59bfa2`.
- PiG's behavior pin is **Pi `1.4.0+74f46864`**, commit
  `74f46864025c68504cd10c89eeb626b7e3d64cea`: v1.4.0 plus 13 commits.
  This is not a claim of parity with the latest Pi `main`.
- Pin the Go extension SDK to **`v0.5.3`**
  (`extensions/sdk/v0.5.3` tag), together with PiG.
- [Root `go.mod`](https://github.com/MichaelKinsy/PiG/blob/v0.5.3/go.mod)
  declares `go 1.26.0`, `toolchain go1.27.3`; the SDK declares `go 1.26`.
  Use Go 1.27.3 for the reproducible packaging attempt, matching upstream's
  release toolchain. Nix availability and the build remain unverified.
- Do not use v0.5.0: upstream retracts it because its module exceeds Go's
  module size limit. v0.5.3 includes security and validation fixes absent
  from the original v0.4.1 target.

### Changes to the migration assessment

The tagged [API parity report](https://github.com/MichaelKinsy/PiG/blob/v0.5.3/docs/extension-api-parity.md)
records upstream tests; these are not local spike results.

- **`model_select` is now implemented and marked complete.** Current/previous
  model and source are exposed across SDKs. Drop the proposed `turn_start`
  polling workaround. Test footer, quotas, and pipelines with `/model`.
- **Active theme access exists in Go:** `Context.UITheme`, including
  `UITheme.Fg`, `Bg`, and styling helpers, appears in the tagged
  [SDK surface map](https://github.com/MichaelKinsy/PiG/blob/v0.5.3/docs/extension-sdk-surface.md).
  The old named-theme-only limitation and mandatory hardcoded palette advice
  no longer apply. Some theme metadata, such as `sourceInfo`, remains missing.
- **Custom UI support is broader.** The shared component kit (D107) covers
  standard components, widget/header/footer views, and tool/message renderers.
  Go has `ViewComponent`, `SetFooterView`, and related view APIs. Native Pi
  objects still do not cross a subprocess boundary; do not treat the old
  “not planned” wording as meaning no supported Go UI equivalent exists.
- **Editor remains a spike gate.** The component kit does not establish that
  our embedded editor workflow works. Probe a custom editor before porting
  `ask-user-question`; keep TS if the probe fails. `tui` is now described as a
  public package, but the adapter and its dependency cost still need testing.
- **`setActiveTools` coverage improved:** activating registered built-ins
  outside the initial active set and next-turn tool instructions are covered.
  Still test our plan-mode restrictions and restore behavior.
- **Discovery order needs correction:** the current parity report says `-e`
  loads first and Package extensions last. Do not rely on the old order in §4.3.
  It covers exact standalone `-e` paths with `--no-extensions`; verify our full
  mixed TS/Go allowlist and absence of duplicate registration in the spike.

### Issue status and remaining risks

- [#136](https://github.com/MichaelKinsy/PiG/issues/136), Herdr agent-state
  reporting: **open**. Keep Herdr-dependent flows on Pi until a local test
  proves they work. Do not port pipelines first.
- [#115](https://github.com/MichaelKinsy/PiG/issues/115), terminal height after
  `/reload`: **closed**. Include reload/resize in the UI spike as a regression check.
- [#200](https://github.com/MichaelKinsy/PiG/issues/200), inconsistent XDG
  roots: **closed**. Current environment docs say host and SDKs follow the same
  root rule. With this user's `XDG_CONFIG_HOME`, the default remains
  `~/.config/pig`; `PIG_USE_PI_DIRS=1` still selects Pi's agent/project directories.
- [#201](https://github.com/MichaelKinsy/PiG/issues/201), dropped OAuth/login
  callbacks: **closed**. Test `openai-codex` login rather than assuming failure
  or success from the issue state.
- UI parity is not absolute. The report still lists component-kit callback
  constraints and partial mouse support. Exercise actual forms, cancellation,
  concurrent dialogs, terminal handoff, and shutdown.
- Settings remain shared, writable-state-sensitive files when using
  `PIG_USE_PI_DIRS=1`. Test against a writable scratch copy first; do not let
  the first spike modify the Home Manager-managed setup or live credentials.

### Multiplexer direction: generic backends

The user wants pipeline pane integration to support TUIOS, Zellij, and tmux
rather than depend on Herdr. Keep the Go port multiplexer-neutral.

- Separate agent launch construction (`pi`, `pig`, etc.) from pane operations.
- Put pane creation, output reads, input delivery, and close behind a small
  backend interface. Implement only operations the existing flows need.
- Support TUIOS, Zellij, and tmux through separate adapters; retain headless
  execution without a multiplexer. Implementation order is not yet decided.
- Keep agent busy/idle/blocked reporting optional. A backend without reporting
  must still support execution and result collection.
- Replace Herdr-specific blocked notifications with a backend-neutral signal
  when porting the affected extensions. Retain compatibility only where needed
  for the existing Pi setup.
- Verify each multiplexer's control API and lifecycle behavior before
  implementing its adapter. No backend compatibility spike has been run yet.

Herdr issue #136 is therefore not a go/no-go gate for the chosen migration.
References below to keeping Herdr flows on Pi or deferring pipelines because of
Herdr apply only to the old integration. Gate each backend on successful pane
control and result collection; verify headless fallback independently. The embedded-editor
spike remains a separate gate.

### Revised next steps

1. Keep the incremental strategy and Pi fallback. No extension port yet.
2. Target Pi v1.4.0 for the TS baseline. Check the installed Pi version before
   changing imports or dependency pins; this running harness reports Pi 1.2.0.
   Standardize on the current `@earendil-works/*` namespace for that baseline,
   update test dependencies together, and run TS tests.
3. Package PiG v0.5.3 and SDK v0.5.3, not v0.4.1. Ask before any Nix command.
   Keep wrapper flags `PIG_USE_PI_DIRS=1`, `PI_TELEMETRY=0`, and
   `PI_SKIP_VERSION_CHECK=1`.
4. Run Phase 2 against writable scratch resources first. Expect `/model`
   notifications to work, not fail. Add `/reload`, resize, concurrent prompts,
   and resume/tool activation checks.
5. Build/load one standalone Go extension before the port batches. Keep Pi's
   TS list intact; isolate PiG's mixed TS/Go list through explicit wrapper
   arguments. Never replace a shared TS entry while Pi still needs it.
6. Proceed with the original smallest-first batches only after the spike.
   The generic multiplexer backend and embedded-editor gates above apply.

## Original handoff: 2026-10-13 (historical)

Researched against PiG `main` at `e63c61c3` (then latest tag `v0.4.1`,
Go SDK tag `extensions/sdk/v0.4.1`). The latest recheck above takes precedence.
Anything marked **unverified** was read from docs but not run.

## 1. Goal and decision so far

- **Goal:** write our Pi extensions in Go instead of TypeScript. This is the
  user's main reason. Faster startup and no Node for the core agent are side
  benefits.
- **Approach:** incremental. PiG still runs TypeScript extensions, so:
  1. Package `pig` in Nix and run it **side by side** with `pi`.
  2. Run all existing TS extensions under PiG unchanged (spike, go/no-go).
  3. Port extensions to Go one at a time, smallest first.
  4. Keep any extension that can't be ported cleanly in TS.
- **Do not** remove Pi until every extension we care about works under PiG.

## 2. Ground rules for the implementing agent

From `AGENTS.md` and the user:

- Before committing, run in the devshell on tracked `.nix` files:
  `deadnix --fail`, `nixfmt --check`, `statix check .` (see `AGENTS.md` for
  the exact command and the fix variant).
- Commit titles only, conventional commits (`feat(pi): ...`,
  `refactor(pi): ...`). One logical change per commit; the repo must eval at
  every commit.
- Avoid code comments unless strictly necessary.
- Validate with
  `nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath`.
  Hosts: `dell`, `desktop`, `framework`, `nas`, `rpi`, `vm`, `vps`. The
  pi aspect is pulled in by `modules/aspects/ai/default.nix` and
  `modules/aspects/profiles/development/default.nix`, so check the dev hosts
  (at least `dell`, `framework`).
- **Ask the user before running `nix` commands.** They interrupted a
  `nix eval` during research; confirm before builds/evals.
- Never deploy unless asked.

## 3. Current setup in nixicle

### 3.1 Nix wiring

- `modules/aspects/ai/pi-coding-agent/default.nix`
  - home-manager `programs.pi-coding-agent` (upstream HM module).
    - Has `package` (`mkPackageOption pkgs "pi-coding-agent" { nullable = true; }`),
      `configDir` (default `~/.pi/agent`; changing it sets
      `PI_CODING_AGENT_DIR`), `settings`, `keybindings`, `models`, `context`,
      `appendSystem`.
    - Writes `settings.json`, `models.json`, `keybindings.json` into
      `configDir` as **read-only Nix store symlinks**.
  - Current settings: `defaultProvider = "openai-codex"`,
    `defaultModel = "gpt-5.4"`, `defaultThinkingLevel = "medium"`,
    `theme = "stylix"`, `packages = []`,
    `extensions = [ "~/.pi/agent/extensions/<rel>" ... ]`.
  - Extensions are copied with `home.file.".pi/agent/extensions/${rel}"`.
  - Agents: `home.file.".pi/agent/agents"` from `../agents`.
  - Other modules: `_ketch.nix`, `_theme.nix` (stylix theme), `_providers.nix`.
- `modules/aspects/ai/pi-coding-agent/_extensions.nix`: list of
  `{ rel; src; }` for every extension installed.
- `modules/aspects/cli/tools/herdr/default.nix:300` installs Herdr's own Pi
  integration as `~/.pi/agent/extensions/herdr-agent-state.ts`. It is
  auto-discovered (not in `settings.extensions`) and listens on
  `pi.events.on("herdr:blocked", ...)`.
- TS tests: root `package.json` (`bun test`) with devDependencies
  `@mariozechner/pi-ai@0.73.1`, `@mariozechner/pi-tui@0.73.1`,
  `typebox@1.3.36`. `package.json` and `bun.lock` are currently untracked.

### 3.2 Import mix to clean up first

Most files import `@mariozechner/pi-*`; `footer.ts` and `session-name.ts`
import `@earendil-works/pi-*` (Pi's newer package name). Fix this before the
spike so failures under PiG aren't really import-resolution failures.

### 3.3 Extension inventory

Line counts exclude tests. "Hooks" are `pi.on(...)` events.

| Extension | Lines | Tools | Commands / shortcuts / flags | Hooks | UI | Other |
|---|---|---|---|---|---|---|
| `session-name.ts` | 40 | – | – | `agent_end` | notify | `setSessionName` |
| `treesitter.ts` | 150 | `read_code_structure`, `read_code_symbol` | – | – | – | `exec("nvim")`; **not in `_extensions.nix`** |
| `codegraph.ts` | 204 | `codegraph_explore`, `_status`, `_init`, `_sync`, `_node`, `_impact` | – | `before_agent_start` | – | `exec("codegraph")` |
| `footer.ts` (+`footer-layout.ts`) | ~230 | – | `/statusline` | `session_start`, `session_shutdown`, `session_info_changed`, `turn_start`, `turn_end`, `model_select` | `setFooter`, notify | Catppuccin Mocha footer |
| `tokens.ts` | 277 | – | `/tokens` | `session_start`, `session_shutdown`, `turn_end` | setStatus, notify | aggregates usage across sessions |
| `ketch.ts` | 305 | `ketch_search`, `_code`, `_docs`, `_scrape`, `_crawl`, `_crawl_status`, `_config` | – | `before_agent_start` | – | config from `_ketch.nix` |
| `nvim-edit/` | 211 | `nvim_edit` | – | `session_start`, `session_shutdown` | notify | terminal handoff to nvim |
| `db.ts` | 533 | `db_discover`, `_query`, `_tables`, `_describe`, `_views`, `_indexes`, `_info` | `/db` | `session_start` | notify | `exec("docker")`, `exec("psql")`; discovers DBs from docker-compose |
| `quotas.ts` (+`quotas-ui.ts`) | ~575 | – | `/quotas` | `session_start`, `session_shutdown`, `turn_start`, `turn_end`, `model_select` | setStatus, notify | per-provider quota |
| `security-guard.ts` | 613 | – | – | `session_start`, `tool_call` (x2) | `custom` (`Container`, `Text`), `select`, notify | emits `herdr:blocked` |
| `ask-user-question.ts` | 667 | `ask_user_question` | – | – | `custom` with pi-tui `Editor` + `Text` | emits `herdr:blocked` |
| `plan-mode/` | 1210 | `plan_tracker` | `/plan`, `/plan-clear`, `/plan-review`, `/plan-status`, `/todos`; shortcut `ctrl+alt+p`; flag `plan` | `session_start`, `before_agent_start`, `context`, `tool_call`, `turn_end`, `agent_end` | select, editor, setStatus, setWidget, `Text` | `appendEntry("plan-mode")`, `sendMessage`, `sendUserMessage`, `setActiveTools` |
| `pipelines/` | 3816 | `subagent_spawn`, `subagent_interrupt`, `subagent_resume`, `subagents_list`, `subagent_research`, `pipeline`, `pipeline_status`, `pipeline_cancel`, `pipeline_cancel_stage`, `pipeline_proceed` | `/agents`, `/btw`, `/btw-close`, `/btw-merge`, `/iterate`, `/pipeline`, `/sub` | `session_start` (x2), `session_shutdown`, `agent_start`, `agent_end`, `agent_settled`, `input`, `model_select` | setWidget, notify | spawns child agents via `bash -c`; herdr panes |

`pipelines` details that matter:
- `pipelines/drivers.ts` `buildLaunch` hardcodes the child command
  `pi --no-extensions --session ... [-e ...] [--model] [--thinking] [--tools] [--skill] [--append-system-prompt] <task>`
  (plus `--mode json -p` headless). Harnesses: `pi`, `claude`, `codex`,
  `opencode`.
- Passes `PI_SUBAGENT_NAME`, `PI_SUBAGENT_AGENT`, `PI_SUBAGENT_AUTO_EXIT`,
  `PI_SUBAGENT_EXIT_FILE`, and forwards `PI_CODING_AGENT_DIR`.
- `pipelines/herdr.ts` wraps the herdr CLI (pane run/get/read/send-keys/close).
- Under PiG, children would still launch real `pi` unless a `pig` harness is
  added (and `PIG_USE_PI_DIRS` forwarded).

## 4. PiG facts (verified from source/docs)

### 4.1 Project

- Repo: <https://github.com/MichaelKinsy/PiG>, MIT, binary `pig`,
  module `github.com/MichaelKinsy/PiG`. Unofficial, not endorsed by Pi.
- Pinned upstream Pi 0.99.1 (`internal/coding/pigversion/pigversion.go`).
  `pig --version` prints `<pig>+<pi>` e.g. `0.4.1+0.99.1`.
- `go.mod`: `go 1.26.0`, `toolchain go1.27.1`. `cmd/pig` is the main package.
- Install: `go install github.com/MichaelKinsy/PiG/cmd/pig@v0.4.1`, release
  archives, npm `@pi-in-go/pig`, or `curl https://pi-in-go.dev/install.sh | sh`.
- Source build of the full repo/tests wants Node 24, Python 3.12, Rust, tmux.
  Building just `cmd/pig` needs only Go (**unverified** for `buildGoModule`).
- Docs to read: `docs/extensions.md`, `docs/extension-authoring.md`,
  `docs/extension-api-parity.md`, `docs/extension-sdk-surface.md`,
  `docs/site/docs/{configuration,settings,environment-variables,extensions}.md`,
  `docs/findings/pi-directories-opt-in.md`, `extensions/sdk/README.md`,
  `examples/extensions/{go-factory,plan-mode}`.

### 4.2 Directories and sharing with Pi

- Config root: `$PIG_HOME`, else `$XDG_CONFIG_HOME/pig`, else `~/.pig`.
  **The user has `XDG_CONFIG_HOME=~/.config`, so the root is `~/.config/pig`**
  and the agent dir is `~/.config/pig/agent`. (Note the README says `~/.pig`;
  issue #200 is about this inconsistency.)
- Agent dir layout: `settings.json`, `models.json`, `sessions/`,
  `extensions/`, `skills/`, `prompts/`, `themes/`, `agents/`, `SYSTEM.md`, ...
  Project-local: `<cwd>/.pig/`.
- **`PIG_USE_PI_DIRS=1`** (exact value) makes PiG use Pi's agent dir
  (`PI_CODING_AGENT_DIR` or `~/.pi/agent`), project `.pi/`, and
  `PI_CODING_AGENT_SESSION_DIR`. PiG implements Pi's lock protocol, and
  sessions/settings/auth round-trip with real Pi (tested). PiG-owned caches,
  staged SDKs and docs stay under the PiG root.
- Telemetry: setting `enableInstallTelemetry` defaults to **true** (install/
  update ping to `pi-in-go.dev`, attribution headers). Disable with
  `PI_TELEMETRY=0` or the setting. Also consider `PI_SKIP_VERSION_CHECK=1`
  since Nix manages updates.

### 4.3 Extension discovery and source forms

Discovery order: `<agent-dir>/extensions`, trusted `<cwd>/.pig/extensions`
(or `.pi` in shared mode), package members, Piglet, **exact paths in
settings**, **`-e` paths**, embedded. `--no-extensions` keeps `-e`.

Two accepted source forms:
- **Factory**: Go `func Extension() *sdk.Extension` in a non-main package.
  PiG compiles it itself with `go build` (needs Go on `PATH` at runtime,
  resolves the SDK from a copy staged under the config root, caches under
  `<root>/cache/{ext,cells,toolchains}`).
- **Exact standalone**: Go module with `package main`, or **any native
  executable file**. Runs isolated.

**Identity rule:** the extension name passed to `sdk.New("<name>")` must equal
the directory name (directory selection) or the file stem (file selection).
A Nix-built binary `.../bin/footer` must call `sdk.New("footer")`.

Standalone entrypoint: `ext.Run()` reads `PIG_EXT_SOCKET` (set by pig).
`ext.RunWithSocket(path)` exists for tests.

Validate: `pig install <path> --validate-only --json` (accepts several paths).
Scaffold: `pig extension init <dir> --lang go [--isolated]`.

### 4.4 Go SDK surface (`github.com/MichaelKinsy/PiG/extensions/sdk`)

Registration (`*sdk.Extension`):
- `sdk.New(name)`
- `Tool(name, description string, schema sdk.Schema, fn ToolFunc)`,
  `ToolFunc = func(ctx sdk.Context, params map[string]any) (any, error)`;
  return `map[string]any{"content": ...}` (string, or ordered blocks
  `{type:"text",text}` / `{type:"image",data,mimeType}`).
- `Command(name, description string, fn CommandFunc)`,
  `CommandFunc = func(ctx sdk.Context, args string) error`;
  `CommandOptions.GetArgumentCompletions` for completions.
- `Shortcut(key, description, fn)`, `Flag(name, FlagOptions)`.
- Events: `OnSessionStart`, `OnSessionShutdown`, `OnToolResult`,
  `OnProjectTrust`, and generic `OnEvent(name, EventFunc)` for everything
  else (`tool_call`, `before_agent_start`, `turn_start`, `turn_end`,
  `agent_end`, `agent_settled`, `input`, `context`, ...).
  `EventFunc = func(ctx sdk.Context, data map[string]any) (any, error)`.
  Check `docs/site/docs/extensions.md` for each event's return shape (e.g.
  tool_call block).
- Event bus: `ext.Events()` / `ctx.Events()` → `On(channel, handler)`,
  `Emit(channel, data)`. Crosses realms (Go ↔ Node), so `herdr:blocked` from a
  Go extension reaches the TS `herdr-agent-state.ts` listener.

`sdk.Context` methods (selection):
- UI: `Notify(msg, level)`, `SetStatus(key, text)`,
  `Select(title, options) (string, bool, error)`,
  `Confirm(title, msg) (bool, error)`,
  `Input(title, placeholder) (string, bool, error)`,
  `Editor(title, prefill) (string, bool, error)`,
  `SetWidget(key, content, ...WidgetOptions)` (string list),
  `SetFooter(lines)`, `SetFooterRenderer(func(width int) []string)`,
  `SetEditorText`, `Custom(component, sdk.RemoteOverlayOptions{...})`.
- Session: `SetSessionName`, `AppendEntry(customType, data)`,
  `SendMessage(customType, content, display, SendMessageOptions)`,
  `SendUserMessage(content, deliverAs)`, `GetEntries`, `GetBranch`,
  `GetFlag`, `GetActiveTools`, `SetActiveTools`, `GetModelInfo`,
  `GetContextUsage`.
- Process: `Exec(command, args) (*ExecResult, error)` (only inside handlers;
  no `pi` object at factory time).
- Since 0.3.0, host-backed getters return `error` and Pi's `undefined` maps to
  nil pointers (`*string`, `*int`). Optional bools use `sdk.Bool(true)`;
  don't replace omitted with `sdk.Bool(false)`.
- Handlers run on their own goroutine. Don't fire-and-forget goroutines; join
  work before returning (see "TypeScript async is a contract" in
  `docs/extensions.md`).

### 4.5 Parity status relevant to us

| API | Status | Impact |
|---|---|---|
| registerTool, registerCommand, shortcut, flag | complete | – |
| `tool_call` block + input mutation | complete (Go map key order differs if you add/move 2+ keys) | security-guard, plan-mode fine |
| `before_agent_start`, `input`, `agent_start/end`, `agent_settled`, `turn_end` | complete | – |
| `turn_start` | partial (timestamp unasserted) | – |
| `context` | wired | plan-mode |
| **`model_select`** | **planned: not emitted by PiG at all** | footer, quotas, pipelines won't react to `/model` even in TS. Workaround: re-read `GetModelInfo()` on `turn_start` |
| notify, setStatus, setFooter, setHeader, setEditorText | complete | – |
| select / confirm / input / editor | partial (`signal` option doesn't cross the process) | fine |
| setWidget | Go sends string lists | plan-mode, pipelines fine |
| setActiveTools | partial (subprocess topology closure) | plan-mode: test |
| setModel, thinking level | partial | – |
| `ctx.ui.custom` | partial; Go implements `sdk.RemoteComponent` (`Render(width) []string`, `HandleInput(data) (RemoteComponentResult, error)`; optional `RemoteComponentDisposer`, `RemoteComponentInvalidator`). Concurrent floating calls serialize (bug) | security-guard, ask-user-question |
| Real pi-tui components from Go | **not planned**; listed under "High-risk parity areas" | see 4.6 |
| `pi.events` across Go/Node | complete | herdr:blocked works |

### 4.6 Editor component in Go

- PiG ships a Go port of pi-tui: package `github.com/MichaelKinsy/PiG/tui`
  with `tui.NewEditor()`, `(*Editor).SetText`, `Render(width int) []string`,
  `HandleInput(data string)`. These match `sdk.RemoteComponent` closely, so a
  small adapter can host a real editor inside `ctx.Custom`.
- Caveats: `tui` is in the **root** module (pulls the whole PiG module as a
  dependency), it's not a documented extension API, and it may break between
  releases. Rendering inside an overlay is **unverified**. Theme styling from
  Go is limited: the Go SDK only has named-theme lookup (`GetTheme`), not the
  active theme (see `examples/extensions/plan-mode/README.md`, RPP-4).

### 4.7 Open issues to watch

- [#136](https://github.com/MichaelKinsy/PiG/issues/136) Herdr's official Pi
  agent-state integration is a silent no-op under PiG. Affects
  `herdr-agent-state.ts`.
- #115 Go factory extensions lose terminal height after `/reload`
  (`ctx.Height()` returns 0).
- #200 XDG config root differs between CLI, SDKs and sprite state.
- #201 `/login` drops a provider's OAuth login (we use `openai-codex`, check
  login works).
- #148 tracking interactive login / ModelRuntime parity gaps.

### 4.8 Reference port

`examples/extensions/plan-mode/` is PiG's own partial Go port of Pi's
plan-mode example (580 + 273 lines, tests). Our `plan-mode/` is derived from
the same upstream idea; use it as a template for structure, persistence and
`setActiveTools` handling. Its README lists what it couldn't port (theme
styling, lone surrogates).

## 5. Plan

### Phase 0: prep (TS only, no PiG)

1. Unify imports to one package namespace (`@earendil-works/*` if Pi upstream
   has fully renamed; check the installed `pkgs.pi-coding-agent` version).
   Run `bun test`.
2. Commit: `refactor(pi): unify pi package imports`.

### Phase 1: package PiG

1. Create `packages/pig/default.nix` with `buildGoModule`:
   - `src = fetchFromGitHub { owner = "MichaelKinsy"; repo = "PiG"; rev = "v0.4.1"; hash = ...; }`
   - `subPackages = [ "cmd/pig" ]`, `vendorHash = ...` (get via `lib.fakeHash`
     then the real hash from the build error; **ask the user before building**).
   - `doCheck = false` (the full suite needs Node/Rust/Python/tmux).
   - Needs Go ≥ 1.26; pick `go_1_26`/`go_1_27` if the default `go` is older.
     Check what nixpkgs offers via the nixos MCP tool rather than `nix eval`.
   - Look at existing `packages/*` (`dynacat`, `glci`, `envoluntary`, ...) for
     how packages are exposed (overlay / `pkgs.nixicle.*`).
2. Install `pig` next to `pi`, wrapped with:
   - `PIG_USE_PI_DIRS=1` so it reuses `~/.pi/agent` (settings, models,
     sessions, auth, extensions, agents) managed by home-manager.
   - `PI_TELEMETRY=0`, `PI_SKIP_VERSION_CHECK=1`.
   - Use `makeWrapper`/`symlinkJoin` or `home.sessionVariables` (prefer the
     wrapper so `pi` is unaffected).
3. Commit: `feat(pi): package pig alongside pi`.

### Phase 2: spike (go/no-go), record results in this file

Run each in a scratch dir:

1. `pig --version`; start `pig` and confirm it loads `~/.pi/agent` settings,
   `models.json` providers, the stylix theme, agents, and `openai-codex`
   login (#201).
2. Load all current TS extensions unchanged. Exercise:
   - footer renders; `/statusline`
   - `/tokens`, `/quotas`, status entries
   - `/plan`, `ctrl+alt+p`, `--plan` flag, `/todos`, plan review editor,
     tool restriction in plan mode
   - security-guard: trigger a blocked `rm -rf`/secret read, the select prompt
   - `ask_user_question` tool with free text
   - `db_discover` in a compose project, `nvim_edit`
   - `/sub`, `/pipeline`, `/btw` (headless and herdr pane)
   - `/model` switch: confirm footer/quotas don't update (model_select gap)
3. Herdr: run `pig` in a herdr pane; check agent state reporting (#136) and
   that security-guard's `herdr:blocked` reaches `herdr-agent-state.ts`.
4. Go hello world: `pig extension init /tmp/hello --lang go --isolated`,
   one tool + one command, `pig install /tmp/hello --validate-only --json`,
   then `pig -e /tmp/hello`.
5. Nix-built Go binary: build the same hello as a standalone with
   `buildGoModule`, load via `pig -e /nix/store/.../bin/hello`. Confirm the
   identity rule (binary name == `sdk.New` name) and that no runtime `go build`
   happens.
6. Editor probe: a command calling `ctx.Custom` with a `RemoteComponent`
   that wraps `tui.NewEditor()`; type, Enter submits, Escape cancels, resize.

Go/no-go:
- 1, 2 (except known gaps), 4, 5 must pass.
- 3 fails → keep herdr flows on `pi`, open/track upstream, don't port
  `pipelines` yet.
- 6 fails → keep `ask-user-question.ts` in TS.

### Phase 3: Nix wiring for Go extensions

Recommended layout:

```
modules/aspects/ai/pi-coding-agent/
  extensions-go/
    go.mod            # one module: github.com/haseebmajid/nixicle/pi-extensions
    go.sum
    cmd/session-name/main.go
    cmd/footer/main.go
    ...
    internal/...      # shared helpers (theme colors, exec helpers)
  _extensions-go.nix  # list of names to build/install
```

- One `buildGoModule` for the whole module (`subPackages = map (n: "cmd/${n}")`)
  so all extensions share `go.sum` and `vendorHash`.
- Each `cmd/<name>/main.go`: `package main`, `ext := sdk.New("<name>")`,
  register, `if err := ext.Run(); err != nil { os.Exit(1) }`.
- Pin `github.com/MichaelKinsy/PiG/extensions/sdk v0.4.1` to match the `pig`
  version; bump both together.
- Load Go extensions **only into pig**, not via `settings.extensions`
  (shared with Pi in `PIG_USE_PI_DIRS` mode; Pi would try to load the binary).
  Options:
  - pig wrapper adds `-e <store>/bin/<name>` per extension (preferred), or
  - a PiG-only settings path if PiG supports one (check).
- When a Go extension replaces a TS one, remove the TS entry from
  `_extensions.nix` in the same commit, or pi loses the feature. If Pi must
  keep working, keep the TS entry until Pi is dropped and have the pig wrapper
  pass `--no-extensions` plus explicit `-e` for both TS and Go (**unverified**
  that settings extensions are skipped with `--no-extensions`; docs say it
  "disables ambient discovery and settings").
- Optional later: a fused Piglet Binary (`docs/site/docs/piglet-binaries.md`)
  to compile Go factories into one `pig` binary.

### Phase 4: port extensions

One extension per commit (`feat(pi): port <name> extension to go`). For each:
port, move tests to Go table tests (`go test` in `checkPhase` of the
extension derivation), swap TS→Go in the Nix lists, run the spike checks for
that extension.

1. **Batch A (easy):** `session-name`, `codegraph`, `ketch`, `treesitter`,
   `tokens`, `footer`.
   - footer: `SetFooterRenderer`; no active theme in Go, so hardcode the
     Catppuccin Mocha palette or read it from stylix at build time (`_theme.nix`).
   - footer/quotas: re-read `GetModelInfo()` on `turn_start` until PiG emits
     `model_select`.
2. **Batch B:** `db`, `quotas`, `nvim-edit`, `security-guard`.
   - security-guard: `OnEvent("tool_call", ...)` returning block; the prompt
     becomes a `RemoteComponent` rendering lines + `Select`; keep emitting
     `herdr:blocked` via `ctx.Events().Emit`.
   - nvim-edit: verify terminal handoff from a subprocess extension.
3. **Batch C:** `plan-mode` (use PiG's example as a base; test
   `setActiveTools`, `appendEntry` restore on resume, `context` filtering).
4. **Batch D:** `ask-user-question` only if spike step 6 passed.
5. **Batch E:** `pipelines`. Add a `pig` harness to the launch builder
   (forward `PIG_USE_PI_DIRS`), then decide whether to port 1:1 or redesign.
   Biggest and herdr-dependent; do last.

### Phase 5: switch over

- Make `pig` the default (`programs.pi-coding-agent.package = null` +
  install pig, or keep pi for a while).
- Drop `package.json`/`bun.lock` once no TS extensions remain.

## 6. Suggestions and risks

- PiG is 0.x and moves fast (~110 commits, frequent releases). Pin a tag and
  bump `pig` and the Go SDK together, deliberately.
- Upstream bugs found during the spike; the maintainer closes issues quickly.
- Expect visual differences: Go extensions return plain lines and can't use
  the active theme yet.
- `model_select` gap affects TS extensions too; it's a reason to wait if
  the footer model display matters.
- Keep both agents installed until Phase 4 Batch C is done; rollback is just
  using `pi`.
