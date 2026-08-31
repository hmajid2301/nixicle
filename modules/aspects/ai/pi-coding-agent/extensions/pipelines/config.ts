// extensions/pipelines/config.ts
import { existsSync, mkdirSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

export interface PipelinesConfig {
  models?: { default?: string; agents?: Record<string, string> };
  widget?: { collapsed?: boolean };
}

export function pipelinesDir(): string {
  const dir = process.env.PIPELINES_DIR ?? join(homedir(), ".pi", "agent", "pipelines");
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
