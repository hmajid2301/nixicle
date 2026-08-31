// extensions/pipelines/agents.ts
// Agent discovery: project > user > bundled (first wins).
import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import type { AgentConfig, HarnessCli } from "./types.ts";

const EXT_DIR = dirname(fileURLToPath(import.meta.url));

export function agentDir(): string {
  return process.env.PI_CODING_AGENT_DIR ?? join(homedir(), ".pi", "agent");
}

export function userAgentsDir(): string {
  return join(agentDir(), "agents");
}

export function findProjectAgentsDir(startDir: string): string | null {
  let dir = startDir;
  for (;;) {
    const candidate = join(dir, ".pi", "agent", "agents");
    if (existsSync(candidate)) return candidate;
    const parent = dirname(dir);
    if (parent === dir) return null;
    dir = parent;
  }
}

export function bundledAgentsDir(): string {
  return join(EXT_DIR, "agents");
}

export function parseFrontmatterBlock(frontmatter: string): Record<string, string> {
  const out: Record<string, string> = {};
  let listKey: string | null = null;
  const listValues: string[] = [];
  const flushList = () => {
    if (listKey) out[listKey] = listValues.join(",");
    listKey = null;
    listValues.length = 0;
  };
  for (const line of frontmatter.split("\n")) {
    const item = line.match(/^\s*-\s*(.+)$/);
    if (item && listKey) {
      listValues.push(item[1].trim());
      continue;
    }
    flushList();
    const m = line.match(/^([a-zA-Z][a-zA-Z-]*):\s*(.*)$/);
    if (!m) continue;
    const key = m[1].toLowerCase();
    const value = m[2].trim();
    if (!value) {
      listKey = key;
      continue;
    }
    out[key] = value;
  }
  flushList();
  return out;
}

function parseList(value: string): string[] {
  return value.split(",").map((v) => v.trim()).filter(Boolean);
}

export function parseAgentFile(
  content: string,
  source: AgentConfig["source"],
  filePath: string,
): AgentConfig | null {
  const match = content.match(/^---\n([\s\S]*?)\n---\n?([\s\S]*)$/);
  if (!match) return null;
  const fm = parseFrontmatterBlock(match[1]);
  if (!fm.name) return null;
  const bool = (v?: string) => (v === undefined ? undefined : v.toLowerCase() === "true");
  return {
    name: fm.name,
    description: fm.description ?? "",
    systemPrompt: match[2].trim(),
    tools: fm.tools ? parseList(fm.tools) : undefined,
    skills: fm.skills ? parseList(fm.skills) : undefined,
    model: fm.model,
    thinking: fm.thinking ?? fm["thinking-level"],
    extensions: fm.extensions ? parseList(fm.extensions) : undefined,
    cli: (fm.cli as HarnessCli) ?? undefined,
    sessionMode: (fm["session-mode"] as AgentConfig["sessionMode"]) ?? undefined,
    autoExit: bool(fm["auto-exit"]),
    spawning: bool(fm["spawning"]),
    cwd: fm.cwd,
    source,
    filePath,
  };
}

function loadDir(dir: string, source: AgentConfig["source"], into: Map<string, AgentConfig>): void {
  if (!existsSync(dir)) return;
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    if (!entry.name.endsWith(".md")) continue;
    const filePath = join(dir, entry.name);
    try {
      // statSync follows symlinks: symlinked agent files load (nix/home-manager
      // deploys ~/.pi/agent/agents as symlinks into /nix/store), real or
      // symlinked directories skip, broken symlinks throw into the catch below
      if (!statSync(filePath).isFile()) continue;
      const agent = parseAgentFile(readFileSync(filePath, "utf8"), source, filePath);
      if (agent && !into.has(agent.name)) into.set(agent.name, agent);
    } catch {
      // unreadable (EACCES), vanished mid-read, or broken symlink — skip and continue
    }
  }
}

export function discoverAgents(cwd: string): AgentConfig[] {
  const byName = new Map<string, AgentConfig>();
  const project = findProjectAgentsDir(cwd);
  if (project) loadDir(project, "project", byName);
  loadDir(userAgentsDir(), "user", byName);
  loadDir(bundledAgentsDir(), "bundled", byName);
  return [...byName.values()].sort((a, b) => a.name.localeCompare(b.name));
}
