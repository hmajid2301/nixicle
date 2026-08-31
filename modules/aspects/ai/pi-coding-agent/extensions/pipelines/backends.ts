// extensions/pipelines/backends.ts
// One spawn interface, two implementations: herdr pane (primary), headless child process.
import { spawn } from "node:child_process";
import { chmodSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { subDir } from "./config.ts";
import { readExitFile, waitForCompletion } from "./completion.ts";
import { buildLaunch, isHeadlessCapable, shellQuote, type LaunchOpts } from "./drivers.ts";
import { createPane, isHerdrAvailable, paneGet, paneReadAsync, paneRun, paneSendKeys } from "./herdr.ts";
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
  watcher?: (handle: RunHandle, result: CompletionResult) => void;
}

interface RunRecord {
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

function clearExitFile(exitFile?: string): void {
  if (!exitFile) return;
  try {
    rmSync(exitFile, { force: true });
  } catch {
    // best effort — completion also falls back to sentinel/process status
  }
}

function buildOpts(req: ResolvedSpawn, backend: "pane" | "headless"): LaunchOpts {
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
  };
}

export function spawnRun(req: ResolvedSpawn): RunHandle {
  if (!BUILT_IN_HARNESSES.has(req.harness) && !/^[A-Za-z0-9._/-]+$/.test(req.harness)) {
    throw new Error("invalid harness name: " + req.harness);
  }
  const backend = currentBackend();
  if (backend === "headless" && !isHeadlessCapable(req.harness)) {
    throw new Error(
      `harness "${req.harness}" cannot run headless — start pi inside herdr for pane mode`,
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
  const paneId = createPane(req.name, req.cwd);
  clearExitFile(o.exitFile);
  const scriptPath = writeLaunchScript(o);
  paneRun(paneId, `bash ${shellQuote(scriptPath)}`);

  const controller = new AbortController();
  const sessionFile = o.sessionFile;

  const completion = (async (): Promise<CompletionResult> => {
    const result = await waitForCompletion(controller.signal, {
      intervalMs: 750,
      exitFile: o.exitFile,
      readScreen: () => paneReadAsync(paneId, 30),
      inspectPane: () => paneGet(paneId),
    });
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
    const result = await waitForCompletion(controller.signal, {
      intervalMs: 750,
      exitFile: o.exitFile,
      readScreen: () => paneReadAsync(rec.handle.paneId!, 30),
      inspectPane: () => paneGet(rec.handle.paneId!),
    });
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

  const completion = new Promise<CompletionResult>((resolve) => {
    child.on("close", (code) => {
      if (req.harness === "pi") {
        const sidecar = readExitFile(o.exitFile);
        const info = o.sessionFile ? readSessionTail(o.sessionFile) : null;
        if (sidecar) {
          resolve({
            ...sidecar,
            output: sidecar.reason === "ping" ? undefined : clip(sidecar.output ?? info?.lastText ?? stdout),
          });
          return;
        }
        if (code === 0) {
          resolve({ reason: "done", exitCode: 0, output: clip(info?.lastText ?? stdout) });
          return;
        }
        resolve({
          reason: "error",
          exitCode: code ?? 1,
          errorMessage: clip(stderr || `child exited with code ${code}`),
        });
        return;
      }
      if (code === 0) {
        resolve({ reason: "done", exitCode: 0, output: clip(stdout) });
        return;
      }
      resolve({
        reason: "error",
        exitCode: code ?? 1,
        errorMessage: clip(stderr || `child exited with code ${code}`),
      });
    });
    controller.signal.addEventListener("abort", () => {
      child.kill("SIGINT");
    });
  });

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

function register(
  req: ResolvedSpawn,
  handle: RunHandle,
  completion: Promise<CompletionResult>,
  controller?: AbortController,
): void {
  handle.completion.catch(() => {}); // avoid unhandled rejection while parent works
  runs.set(handle.id, { handle, req, controller });
  completion
    .then((result) => {
      if (runs.get(handle.id)?.handle !== handle) return;
      try {
        req.watcher?.(handle, result);
      } catch {
        // Watchers are advisory; do not break run cleanup on supervisor errors.
      }
      if (result.reason !== "ping" && runs.get(handle.id)?.handle === handle) runs.delete(handle.id);
    })
    .catch((error) => {
      if (runs.get(handle.id)?.handle !== handle) return;
      try {
        req.watcher?.(handle, {
          reason: "error",
          exitCode: 1,
          errorMessage: error instanceof Error ? error.message : String(error),
        });
      } catch {
        // Watchers are advisory; do not break run cleanup on supervisor errors.
      }
      if (runs.get(handle.id)?.handle === handle) runs.delete(handle.id);
    });
}