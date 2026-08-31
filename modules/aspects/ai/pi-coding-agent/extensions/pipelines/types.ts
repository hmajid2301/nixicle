// extensions/pipelines/types.ts
// Shared types. Pure — no imports.

export type HarnessCli =
  | "pi"
  | "claude"
  | "codex"
  | "grok"
  | "opencode"
  | (string & {}); // custom CLIs allowed

export interface AgentConfig {
  name: string;
  description: string;
  systemPrompt: string;
  tools?: string[];
  skills?: string[];
  extensions?: string[];
  model?: string;
  thinking?: string;
  cli?: HarnessCli;
  sessionMode?: "standalone" | "lineage" | "fork";
  autoExit?: boolean;
  spawning?: boolean;
  cwd?: string;
  source: "project" | "user" | "bundled";
  filePath: string;
}

export interface CompletionResult {
  reason: "done" | "ping" | "error";
  exitCode: number;
  output?: string;
  ping?: { name: string; message: string };
  errorMessage?: string;
}

export interface RunHandle {
  id: string;
  name: string;
  backend: "pane" | "headless";
  sessionPath?: string;
  paneId?: string;
  pid?: number;
  startedAt: number;
  completion: Promise<CompletionResult>;
  interrupt(): Promise<void>;
}
