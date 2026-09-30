---
name: debugging
description: Use when a bug, test failure, panic, crash, hang, or wrong value needs runtime evidence a code read cannot give — driving delve non-interactively for Go, inspect or profiling flags for Node/TypeScript, batch lldb/gdb for Rust and C/C++, tracing syscalls or Nix build failures, or reading a panic, goroutine dump, or core file. Covers the mechanics only; follow superpowers/systematic-debugging for root-cause process before proposing any fix.
---

Turn a hypothesis into an observation. This skill is the machinery under `systematic-debugging`'s process — it never licenses skipping that process, and it never replaces reading the code.

## Do you need a debugger at all

Climb in order, stop at the first rung that produces the observation:

1. **Reproduce deterministically.** A flaky repro is itself the bug; a debugger on a non-reproducible failure yields noise.
2. **Read the error and the whole stack trace.** Line numbers, error codes, and the first frame that is *your* code usually name the bug.
3. **Narrow with tests.** `go test -run TestThing -count=1 ./pkg`, smallest failing input, `git bisect run <script>` for regressions.
4. **Add a log line.** One well-placed print beats a stepping session when the question is "what is this value here".
5. **Drive a debugger** when the value at fault is only knowable at runtime — a stale field mid-loop, a wrong branch taken, which goroutine holds the lock.

## Go — non-interactive delve

Build a breakpoint script file instead of an interactive session. `--allow-non-terminal-interactive` is required when there is no TTY.

```sh
cat > /tmp/dlv-cmds.txt <<'EOF'
break main.boom
continue
args
locals
print xs
stack
exit
EOF
dlv debug --init /tmp/dlv-cmds.txt --allow-non-terminal-interactive
```

Verified output shape: `Breakpoint 1 set at ...`, the hit line and source, then `args`, `locals`, the printed expression, and `stack` frames. Exit code is 0, so this composes in a shell pipeline.

- **Tests:** `dlv test ./pkg -- -test.run TestThing -test.v`
- **`--continue` needs `--headless`.** To catch a panic, use an init file whose only command is `continue`; delve stops at `fatalpanic`, and
  `print runtime.curg._panic.arg` gives the message (`"runtime error: index out of range [3] with length 2"`).
- **Inspect:** `next` / `step` / `stepout`, `goroutines` (lists every goroutine with its blocking state), `goroutine <id>`, `bt`, `frame <n>`, `vars`, `whatis`, `print <expr>`, `list`.
- **Core file:** `dlv core ./binary ./core` (`dlv dump` writes one).
- **Attach:** `dlv attach <pid>` pauses the process — prefer `dlv exec ./binary` against a local build.
- **Breakpoint placement is binary search.** One breakpoint where the value is *wrong*, then bisect between entry and there. A breakpoint on every function buries the signal.

## Go without a debugger

- `GOTRACEBACK=all go run .` — every goroutine's stack at the panic, not just the faulting one. `GOTRACEBACK=system` adds runtime frames, `GOTRACEBACK=crash` aborts and writes a core file.
- `go test -race -count=1 ./...` for data races. `-count=1` defeats the test cache after a suspected stale pass.
- Hangs and hot spots: `net/http/pprof` + `go tool pprof`, or `runtime/debug.Stack()` dumped on a signal.

## Node and TypeScript

- `node --inspect-brk ./dist/x.js`, then drive over CDP. A `debugger;` statement in the suspect branch is the deterministic stop.
- For "why is this slow / why does memory grow", a `--cpu-prof` or `--heap-prof` run beats stepping: the profile names the frame.
- Browser UI bug: use the `playwright-cli` skill (screenshots, console, network), not `--inspect`.

## Rust and C/C++

- `RUST_BACKTRACE=full cargo test -- --nocapture`, plus `RUST_LOG=<crate>=debug` for instrumented paths.
- Batch debugger: `lldb -batch -o run -o bt ./target/debug/x`, `gdb -batch -ex run -ex bt ./x`.
- `rust-gdb`, `lldb`, and `gdb` are **not** installed in the dev profile — add them before relying on this section.

## Syscalls and processes

- `strace -f -e trace=file,network ./x 2>&1 | tail -40` — the `ENOENT`/`EACCES` on a path no stack trace mentions.
- `lsof -p <pid>`, `ss -tlnp`, `cat /proc/<pid>/stack` for a hang or a port conflict.

## Nix build failures

- Sandboxed failure whose log stops at a bare command: add `pkgs.breakpointHook` to `nativeBuildInputs`. It pauses the build and prints how to enter the namespace.
- `nix log <drv>` for the build log; `nix develop -c <cmd>` to reproduce the intended environment. **Fails in the sandbox, works in `nix develop`** means a missing build input or a network access, not a code bug.

## Evidence rules

- One runtime observation per hypothesis, **before** editing code: state the hypothesis, the command, then the real output.
- Verbatim beats paraphrase — "`xs` is `len: 2, cap: 2`", not "the slice was too short".
- Re-run the *same* command after the fix; that repeat is the verification, not a fresh claim.
- Remove breakpoint scripts, init files, and temporary instrumentation before finishing. They are not left in the tree.
- If the tool needed is not installed, say so and install it or say the claim is unverified. Reasoning from the source and calling it evidence is the failure this skill exists to prevent.
