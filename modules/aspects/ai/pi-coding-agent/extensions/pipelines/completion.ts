// extensions/pipelines/completion.ts
import { existsSync, readFileSync, rmSync } from "node:fs";
import type { CompletionResult } from "./types.ts";

// global flag: parseSentinel iterates all matches via matchAll, which
// throws on non-global regexes (verified against Bun/JSC).
export const SENTINEL_RE = /__PIPL_EXIT_(\d+)__/g;

export function interpretExitSidecar(data: unknown): CompletionResult | null {
  const p = data as {
    type?: unknown;
    name?: unknown;
    message?: unknown;
    errorMessage?: unknown;
    output?: unknown;
  };
  if (p?.type === "ping") {
    return {
      reason: "ping",
      exitCode: 0,
      ping: {
        name: typeof p.name === "string" ? p.name : "subagent",
        message: typeof p.message === "string" ? p.message : "",
      },
    };
  }
  if (p?.type === "error") {
    const errorMessage =
      typeof p.errorMessage === "string" && p.errorMessage.trim()
        ? p.errorMessage
        : "child exited with stopReason=error (no message in sidecar)";
    const result: CompletionResult = { reason: "error", exitCode: 1, errorMessage };
    if (p.isCreditLimit === true) result.isCreditLimit = true;
    return result;
  }
  if (p?.type === "done") {
    const result: CompletionResult = { reason: "done", exitCode: 0 };
    if (typeof p.output === "string") result.output = p.output;
    return result;
  }
  return null;
}

export function readExitFile(exitFile: string | undefined): CompletionResult | null {
  if (!exitFile || !existsSync(exitFile)) return null;
  let raw: string;
  try {
    raw = readFileSync(exitFile, "utf8");
  } catch {
    return null; // read race / partial write — retry next tick
  }
  let result: CompletionResult | null;
  try {
    result = interpretExitSidecar(JSON.parse(raw));
  } catch {
    return null; // partial write (unparseable JSON) — retry next tick
  }
  if (result) {
    rmSync(exitFile, { force: true });
    return result;
  }
  // Valid JSON but an unrecognized sidecar: consume the file so the
  // watcher doesn't re-read it forever, surfacing the payload as an error.
  rmSync(exitFile, { force: true });
  return {
    reason: "error",
    exitCode: 1,
    errorMessage: `unrecognized exit sidecar: ${raw.slice(0, 200)}`,
  };
}

export function parseSentinel(screen: string): number | null {
  // A child can echo the sentinel literal in its own output, and stale
  // sentinels linger in pane scrollback — take the LAST match so the
  // fresh exit code wins.
  const m = [...screen.matchAll(SENTINEL_RE)].pop();
  return m ? Number.parseInt(m[1], 10) : null;
}

export interface WaitOpts {
  intervalMs: number;
  exitFile?: string;
  readScreen?: () => Promise<string>;
  inspectPane?: () => Promise<"present" | "missing" | "unavailable">;
  paneDisappearanceGraceMs?: number;
  onTick?: (elapsedSeconds: number) => void;
  timeoutMs?: number;
  onTimeout?: (elapsedSeconds: number) => void;
  // Resolves with the exit code when the underlying child process exits.
  // Used by the headless backend, which has no pane/screen to poll.
  childExit?: Promise<number | null>;
}

function delay(ms: number, signal: AbortSignal): Promise<void> {
  if (signal.aborted) return Promise.reject(new Error("aborted while waiting for child"));
  return new Promise((resolve, reject) => {
    const onAbort = () => {
      clearTimeout(timer);
      reject(new Error("aborted while waiting for child"));
    };
    const timer = setTimeout(() => {
      signal.removeEventListener("abort", onAbort);
      resolve();
    }, ms);
    signal.addEventListener("abort", onAbort, { once: true });
  });
}

function sentinelResult(code: number): CompletionResult {
  return code === 0
    ? { reason: "done", exitCode: 0 }
    : { reason: "error", exitCode: code, errorMessage: `child exited with code ${code}` };
}

export async function waitForCompletion(signal: AbortSignal, o: WaitOpts): Promise<CompletionResult> {
  const startedAt = Date.now();
  // Watchdog: a single timer that fires onTimeout once at the deadline and is
  // cleared on settle — no per-tick elapsed bookkeeping, no repeated firing.
  let watchdog: ReturnType<typeof setTimeout> | undefined;
  if (o.timeoutMs && o.onTimeout) {
    watchdog = setTimeout(() => {
      o.onTimeout?.(Math.floor((Date.now() - startedAt) / 1000));
    }, o.timeoutMs);
  }
  try {
    for (;;) {
      if (signal.aborted) throw new Error("aborted while waiting for child");

      const sidecar = readExitFile(o.exitFile);
      if (sidecar) return sidecar;

      // A readable screen implies the pane is present, so skip the separate
      // inspectPane probe (one fewer herdr subprocess spawn per poll).
      let screenOk = false;
      if (o.readScreen) {
        try {
          const screen = await o.readScreen();
          screenOk = screen.length > 0;
          const code = parseSentinel(screen);
          if (code !== null) return sentinelResult(code);
        } catch {
          screenOk = false; // screen probe failed — keep polling
        }
      }

      if (o.inspectPane && !screenOk) {
        let state: "present" | "missing" | "unavailable";
        try {
          state = await o.inspectPane();
        } catch {
          state = "unavailable";
        }
        if (state === "missing") {
          const graceEnd = Date.now() + (o.paneDisappearanceGraceMs ?? 500);
          while (Date.now() < graceEnd) {
            await delay(Math.min(25, graceEnd - Date.now()), signal);
            const late = readExitFile(o.exitFile);
            if (late) return late;
            if (o.readScreen) {
              try {
                const code = parseSentinel(await o.readScreen());
                if (code !== null) return sentinelResult(code);
              } catch { /* ignore */ }
            }
          }
          return { reason: "error", exitCode: 1, errorMessage: "child pane disappeared before completion" };
        }
      }

      o.onTick?.(Math.floor((Date.now() - startedAt) / 1000));
      if (o.childExit) {
        const exited = await Promise.race([
          o.childExit.then((code) => ({ exited: true as const, code })),
          delay(o.intervalMs, signal).then(() => ({ exited: false as const, code: null })),
        ]);
        if (exited.exited) {
          // Child exited — prefer a late sidecar (pi writes it on clean exit),
          // otherwise fall back to the exit code.
          const late = readExitFile(o.exitFile);
          if (late) return late;
          return sentinelResult(exited.code ?? 0);
        }
      } else {
        await delay(o.intervalMs, signal);
      }
    }
  } finally {
    if (watchdog) clearTimeout(watchdog);
  }
}