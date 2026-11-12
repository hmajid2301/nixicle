// extensions/pipelines/log.ts
// Minimal structured logger. Writes JSON lines to a file so pipeline lifecycle
// events (spawns, completions, failures, timeouts, credit-limit stops) are
// debuggable after the fact. Logging is best-effort and never throws.
import { appendFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

export type LogLevel = "debug" | "info" | "warn" | "error";

let logPath: string | undefined;

export function initLogging(path?: string): void {
  logPath =
    path ??
    process.env.PI_PIPELINES_LOG ??
    join(homedir(), ".local", "state", "pi", "pipelines.log");
}

export function log(level: LogLevel, event: string, data?: Record<string, unknown>): void {
  if (!logPath) return;
  try {
    appendFileSync(logPath, JSON.stringify({ ts: new Date().toISOString(), level, event, ...data }) + "\n");
  } catch {
    // Logging must never break the extension.
  }
}
