// extensions/pipelines/backends.ts
// One spawn interface: Herdr/TUIOS panes or headless child processes.
import { spawn } from "node:child_process";
import { chmodSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { DEFAULT_PANE_CONFIG, DEFAULT_STALL_GRACE_MS, subDir } from "./config.ts";
import { readExitFile, waitForCompletion, type WaitOpts } from "./completion.ts";
import { log } from "./log.ts";
import { buildLaunch, isHeadlessCapable, shellQuote, type LaunchOpts } from "./drivers.ts";
import { isHerdrAvailable, paneClose, paneGet, paneReadAsync, paneRun, paneSendKeys } from "./herdr.ts";
import { placePane, type PanePlacement } from "./placement.ts";
import { readSessionTail } from "./session-tail.ts";
import type { AgentConfig, CompletionResult, HarnessCli, RunHandle } from "./types.ts";

export function currentBackend(): "pane" | "headless" {
  return isHerdrAvailable() ? "pane" : "headless";
}

export interface ResolvedSpawn {
  id: string;
  name: string;
  agentName?: string;
  agent?: AgentConfig;
  task: string;
  cwd: string;
  harness: HarnessCli;
  model?: string;
  thinking?: string;
  tools?: string[];
  skills?: string[]; // resolved paths
  extensions?: string[]; // resolved paths
  systemPromptAppend?: string;
  autoExit: boolean;
  childExtPath?: string;
  sessionPath?: string; // override (resume)
  timeoutMs?: number;
  onTimeout?: (elapsedSeconds: number) => void;
  onStall?: (elapsedSeconds: number) => void;
  onRecover?: (elapsedSeconds: number) => void;
  watcher?: (handle: RunHandle, result: CompletionResult) => void;
  panePlacement?: PanePlacement;
  env?: Record<string, string>;
  /** Keep the pane after the run settles so a follow-up can resume in it. */
  retainPane?: boolean;
  stallGraceMs?: number;
}

export interface RunRecord {
  handle: RunHandle;
  req: ResolvedSpawn;
  controller?: AbortController;
}

const runs = new Map<string, RunRecord>();
let resumeCounter = 0;

export function buildResumedSpawn(
  req: ResolvedSpawn,
  message: string,
  nextId: string,
  opts?: { autoExit?: boolean },
): ResolvedSpawn {
  return {
    ...req,
    id: nextId,
    task: message,
    sessionPath: sessionFileOf(req),
    autoExit: opts?.autoExit ?? req.autoExit,
  };
}

export function getRun(id: string): RunRecord | undefined {
  return runs.get(id);
}

export function listRuns(): RunRecord[] {
  return [...runs.values()];
}

/** Stop a retained run: interrupt, close its pane, and forget it. */
export function stopRun(id: string): boolean {
  const rec = runs.get(id);
  if (!rec) return false;
  runs.delete(id);
  try {
    void rec.handle.interrupt().catch(() => {});
  } catch {
    // best effort — the process may already be gone
  }
  closePaneIfAny(rec.handle);
  return true;
}

const ANSI_RE = /\x1b\[[0-9;]*[a-zA-Z]/g;

// The five CLIs drivers.ts has dedicated launch builders for; anything else
// goes through the unquoted custom-CLI slot in buildLaunch and must be a
// boring filesystem-style command name.
const BUILT_IN_HARNESSES: ReadonlySet<string> = new Set([
  "pi",
  "claude",
  "codex",
  "grok",
  "opencode",
]);

function clip(text: string, n = 4000): string {
  return text.length > n ? `${text.slice(0, n)}\n…(truncated ${text.length - n} chars)` : text;
}

function sessionFileOf(req: ResolvedSpawn): string {
  return req.sessionPath ?? join(subDir("sessions"), `${req.id}.jsonl`);
}

function exitFileOf(req: ResolvedSpawn): string {
  return join(subDir("exit"), `${req.id}.json`);
}

function paneWaitOptions(req: ResolvedSpawn, o: LaunchOpts, paneId: string): WaitOpts {
  return {
    intervalMs: 750,
    exitFile: o.exitFile,
    readScreen: () => paneReadAsync(paneId, 30),
    inspectPane: () => paneGet(paneId),
    timeoutMs: o.timeoutMs,
    onTimeout: o.onTimeout,
    stallGraceMs: req.stallGraceMs ?? DEFAULT_STALL_GRACE_MS,
    onStall: req.onStall,
    onRecover: req.onRecover,
  };
}

function clearExitFile(exitFile?: string): void {
  if (!exitFile) return;
  try {
    rmSync(exitFile, { force: true });
  } catch {
    // best effort — completion also falls back to sentinel/process status
  }
}

export function buildOpts(req: ResolvedSpawn, backend: "pane" | "headless"): LaunchOpts {
  const systemPromptAppend = [req.agent?.systemPrompt, req.systemPromptAppend]
    .filter((s): s is string => typeof s === "string" && s.length > 0)
    .join("\n\n") || undefined;
  return {
    id: req.id,
    name: req.name,
    task: req.task,
    cwd: req.cwd,
    harness: req.harness,
    mode: backend,
    model: req.model,
    thinking: req.thinking,
    tools: req.tools,
    skills: req.skills,
    extensions: req.extensions,
    systemPromptAppend,
    agentName: req.agentName,
    autoExit: req.autoExit,
    childExtPath: req.childExtPath,
    sessionFile: req.harness === "pi" ? sessionFileOf(req) : undefined,
    exitFile: req.harness === "pi" ? exitFileOf(req) : undefined,
    timeoutMs: req.timeoutMs,
    onTimeout: req.onTimeout,
    env: req.env,
  };
}

export function spawnRun(req: ResolvedSpawn): RunHandle {
  if (!BUILT_IN_HARNESSES.has(req.harness) && !/^[A-Za-z0-9._/-]+$/.test(req.harness)) {
    throw new Error("invalid harness name: " + req.harness);
  }
  const backend = currentBackend();
  if (backend === "headless" && !isHeadlessCapable(req.harness)) {
    throw new Error(
      `harness "${req.harness}" cannot run headless — start pi inside Herdr or TUIOS for pane mode`,
    );
  }
  return backend === "pane" ? spawnPane(req, buildOpts(req, "pane")) : spawnHeadless(req, buildOpts(req, "headless"));
}

export async function paneOutputOf(paneId: string): Promise<string> {
  try {
    const screen = (await paneReadAsync(paneId, 80)).replace(ANSI_RE, "");
    const idx = screen.lastIndexOf("__PIPL_EXIT_");
    const body = idx >= 0 ? screen.slice(0, idx) : screen;
    return body
      .split("\n")
      .map((l) => l.replace(/\s+$/, ""))
      .filter((l) => l.trim())
      .slice(-30)
      .join("\n");
  } catch {
    return "";
  }
}

function writeLaunchScript(o: LaunchOpts): string {
  const path = join(subDir("launch"), `${o.id}.sh`);
  writeFileSync(path, `#!/bin/bash\n${buildLaunch(o)}\n`, "utf8");
  chmodSync(path, 0o755);
  return path;
}

function spawnPane(req: ResolvedSpawn, o: LaunchOpts): RunHandle {
  const paneId = placePane(req.name, req.cwd, req.panePlacement ?? DEFAULT_PANE_CONFIG);
  clearExitFile(o.exitFile);
  const scriptPath = writeLaunchScript(o);
  paneRun(paneId, `bash ${shellQuote(scriptPath)}`);

  const controller = new AbortController();
  const sessionFile = o.sessionFile;

  const completion = (async (): Promise<CompletionResult> => {
    const result = await waitForCompletion(controller.signal, paneWaitOptions(req, o, paneId));
    if (result.reason === "ping") return result;
    const output = result.output ?? (sessionFile
      ? (readSessionTail(sessionFile)?.lastText || (await paneOutputOf(paneId)))
      : await paneOutputOf(paneId));
    return { ...result, output: clip(output) };
  })();

  const handle: RunHandle = {
    id: req.id,
    name: req.name,
    backend: "pane",
    paneId,
    sessionPath: sessionFile,
    startedAt: Date.now(),
    completion,
    async interrupt() {
      paneSendKeys(paneId, "Escape");
    },
  };
  register(req, handle, completion, controller);
  return handle;
}

/** Resume an interrupted/interactive pane child with a guidance message in the same pane. */
export function resumePaneRun(
  id: string,
  message: string,
  opts?: { autoExit?: boolean },
): RunHandle | null {
  const rec = runs.get(id);
  if (!rec || rec.handle.backend !== "pane" || !rec.handle.paneId) return null;
  runs.delete(id);
  rec.controller?.abort();
  const req = buildResumedSpawn(
    rec.req,
    message,
    `${rec.req.id}-r${Date.now().toString(36)}-${++resumeCounter}`,
    opts,
  );
  const o = buildOpts(req, "pane");
  clearExitFile(o.exitFile);
  const scriptPath = writeLaunchScript(o);
  // Clear the screen first so the previous run's exit sentinel lingering in
  // scrollback cannot false-complete this run's screen-based wait.
  paneRun(rec.handle.paneId, `clear; bash ${shellQuote(scriptPath)}`);

  const controller = new AbortController();
  const completion = (async (): Promise<CompletionResult> => {
    const result = await waitForCompletion(controller.signal, paneWaitOptions(req, o, rec.handle.paneId!));
    if (result.reason === "ping") return result;
    const output = result.output ?? (o.sessionFile
      ? (readSessionTail(o.sessionFile)?.lastText || (await paneOutputOf(rec.handle.paneId!)))
      : await paneOutputOf(rec.handle.paneId!));
    return { ...result, output: clip(output) };
  })();

  const handle: RunHandle = {
    id: req.id,
    name: req.name,
    backend: "pane",
    paneId: rec.handle.paneId,
    sessionPath: o.sessionFile,
    startedAt: Date.now(),
    completion,
    async interrupt() {
      paneSendKeys(rec.handle.paneId!, "Escape");
    },
  };
  register(req, handle, completion, controller);
  return handle;
}

function spawnHeadless(req: ResolvedSpawn, o: LaunchOpts): RunHandle {
  clearExitFile(o.exitFile);
  const child = spawn("bash", ["-c", buildLaunch(o)], {
    cwd: req.cwd,
    stdio: ["ignore", "pipe", "pipe"],
  });
  const controller = new AbortController();
  let stdout = "";
  let stderr = "";
  child.stdout?.on("data", (d) => { stdout += d; });
  child.stderr?.on("data", (d) => { stderr += d; });

  // Resolves with the exit code when the child process exits. This is the
  // headless completion signal (no pane/screen to poll), and it lets
  // waitForCompletion apply the same watchdog timeout as the pane backend.
  const childExit = new Promise<number | null>((resolve) => {
    child.on("close", (code) => resolve(code ?? null));
  });
  controller.signal.addEventListener("abort", () => {
    child.kill("SIGINT");
  });

  const completion = (async () => {
    const result = await waitForCompletion(controller.signal, {
      intervalMs: 750,
      exitFile: o.exitFile,
      childExit,
      timeoutMs: o.timeoutMs,
      onTimeout: o.onTimeout,
    });
    if (result.reason === "ping") return result;
    const info = o.sessionFile ? readSessionTail(o.sessionFile) : null;
    const output = clip(result.output ?? (req.harness === "pi" ? info?.lastText ?? stdout : stdout));
    if (result.reason === "error") {
      // Prefer the sidecar message for pi; otherwise surface stderr.
      const errorMessage =
        req.harness === "pi" && result.errorMessage
          ? result.errorMessage
          : clip(stderr || result.errorMessage || `child exited with code ${result.exitCode}`);
      return { ...result, output, errorMessage };
    }
    return { ...result, output };
  })();

  const handle: RunHandle = {
    id: req.id,
    name: req.name,
    backend: "headless",
    pid: child.pid ?? undefined,
    sessionPath: o.sessionFile,
    startedAt: Date.now(),
    completion,
    async interrupt() {
      controller.abort();
    },
  };
  register(req, handle, completion, controller);
  return handle;
}

function closePaneIfAny(handle: RunHandle): void {
  if (handle.backend === "pane" && handle.paneId) {
    try {
      paneClose(handle.paneId);
    } catch {
      // best effort — pane may already be gone
    }
  }
}

export function register(
  req: ResolvedSpawn,
  handle: RunHandle,
  completion: Promise<CompletionResult>,
  controller?: AbortController,
): void {
  handle.completion.catch(() => {}); // avoid unhandled rejection while parent works
  runs.set(handle.id, { handle, req, controller });
  log("info", "run_spawned", { id: handle.id, name: handle.name, backend: handle.backend });
  completion
    .then((result) => {
      if (runs.get(handle.id)?.handle !== handle) return;
      log(
        result.reason === "error" ? "error" : "info",
        "run_completed",
        { id: handle.id, reason: result.reason, exitCode: result.exitCode, isCreditLimit: result.isCreditLimit },
      );
      try {
        req.watcher?.(handle, result);
      } catch {
        // Watchers are advisory; do not break run cleanup on supervisor errors.
      }
      if (!req.retainPane && result.reason !== "ping" && runs.get(handle.id)?.handle === handle) {
        runs.delete(handle.id);
        closePaneIfAny(handle);
      }
    })
    .catch((error) => {
      if (runs.get(handle.id)?.handle !== handle) return;
      log("error", "run_error", { id: handle.id, error: error instanceof Error ? error.message : String(error) });
      try {
        req.watcher?.(handle, {
          reason: "error",
          exitCode: 1,
          errorMessage: error instanceof Error ? error.message : String(error),
        });
      } catch {
        // Watchers are advisory; do not break run cleanup on supervisor errors.
      }
      if (runs.get(handle.id)?.handle === handle) {
        runs.delete(handle.id);
        closePaneIfAny(handle);
      }
    });
}