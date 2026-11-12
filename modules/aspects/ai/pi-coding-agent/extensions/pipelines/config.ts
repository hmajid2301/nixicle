// extensions/pipelines/config.ts
import { existsSync, mkdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { agentDir } from "./agents.ts";

export type PaneMode = "grouped" | "tab" | "split";
export type PaneDirection = "right" | "down";

export interface PaneConfig {
  mode: PaneMode;
  direction: PaneDirection;
  maxPerTab: number;
}

export interface PipelinesConfig {
  models?: { default?: string; agents?: Record<string, string> };
  widget?: { collapsed?: boolean };
  stageTimeoutMinutes?: number;
  panes?: { mode?: PaneMode; direction?: PaneDirection; maxPerTab?: number };
  persistent?: { maxAgents?: number };
  supervision?: { stallGraceMs?: number };
  btw?: { tools?: string[] };
}

export const DEFAULT_STALL_GRACE_MS = 5000;

// A side question should not be able to mutate the checkout by default.
const DEFAULT_BTW_TOOLS = ["read", "grep", "find", "ls"];

export const DEFAULT_PANE_CONFIG: PaneConfig = { mode: "grouped", direction: "right", maxPerTab: 4 };

export function resolvePaneConfig(cfg: PipelinesConfig): PaneConfig {
  const panes = cfg.panes ?? {};
  return {
    mode: panes.mode === "grouped" || panes.mode === "split" || panes.mode === "tab" ? panes.mode : DEFAULT_PANE_CONFIG.mode,
    direction: panes.direction === "down" ? "down" : "right",
    maxPerTab:
      typeof panes.maxPerTab === "number" && Number.isSafeInteger(panes.maxPerTab) && panes.maxPerTab >= 1
        ? panes.maxPerTab
        : DEFAULT_PANE_CONFIG.maxPerTab,
  };
}

export function pipelinesDir(): string {
  const dir = process.env.PIPELINES_DIR ?? join(agentDir(), "pipelines");
  mkdirSync(dir, { recursive: true });
  return dir;
}

export function subDir(name: "state" | "sessions" | "exit" | "launch"): string {
  const dir = join(pipelinesDir(), name);
  mkdirSync(dir, { recursive: true });
  return dir;
}

export function loadConfig(dir?: string): PipelinesConfig {
  const path = join(dir ?? pipelinesDir(), "config.json");
  if (!existsSync(path)) return {};
  try {
    const parsed = JSON.parse(readFileSync(path, "utf8"));
    return typeof parsed === "object" && parsed ? parsed : {};
  } catch {
    return {};
  }
}

export function resolveStallGraceMs(cfg: PipelinesConfig): number {
  const ms = cfg.supervision?.stallGraceMs;
  return typeof ms === "number" && Number.isSafeInteger(ms) && ms >= 0 ? ms : DEFAULT_STALL_GRACE_MS;
}

export function resolveBtwTools(cfg: PipelinesConfig): string[] {
  const tools = cfg.btw?.tools;
  return Array.isArray(tools) && tools.length > 0 && tools.every((t) => typeof t === "string") ? tools : DEFAULT_BTW_TOOLS;
}

export function resolvePersistentMax(cfg: PipelinesConfig): number {
  const max = cfg.persistent?.maxAgents;
  return typeof max === "number" && Number.isSafeInteger(max) && max >= 1 ? max : 3;
}

export function resolveModel(
  cfg: PipelinesConfig,
  agentName: string | undefined,
  agentModel: string | undefined,
  argModel: string | undefined,
  parentModel: string | undefined,
): string | undefined {
  return (
    argModel
    ?? agentModel
    ?? (agentName ? cfg.models?.agents?.[agentName] : undefined)
    ?? cfg.models?.default
    ?? parentModel
  );
}

// A parent model id is only meaningful to the same harness: pi's
// "provider/model" strings mean nothing to the codex/claude/grok CLIs, so those
// children must be given a model explicitly (stage, agent, or config).
export function parentModelFor(harness: string | undefined, parentModel: string | undefined): string | undefined {
  return (harness ?? "pi") === "pi" ? parentModel : undefined;
}
