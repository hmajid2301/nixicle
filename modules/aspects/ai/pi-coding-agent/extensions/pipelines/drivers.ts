// extensions/pipelines/drivers.ts
// Harness launch-command builders. Pure string assembly.
import type { HarnessCli } from "./types.ts";

export const CONTROL_TOOLS = ["subagent_done", "caller_ping"];

export function shellQuote(value: string): string {
  return "'" + value.replace(/'/g, "'\\''") + "'";
}

export interface LaunchOpts {
  id: string;
  name: string;
  task: string;
  cwd: string;
  harness: HarnessCli;
  mode: "pane" | "headless";
  model?: string;
  thinking?: string;
  tools?: string[];
  skills?: string[]; // resolved paths
  extensions?: string[]; // resolved paths
  systemPromptAppend?: string;
  agentName?: string;
  autoExit?: boolean;
  sessionFile?: string; // pi only
  exitFile?: string; // pi only
  childExtPath?: string; // pi only
  timeoutMs?: number;
  onTimeout?: (elapsedSeconds: number) => void;
}

export function buildToolAllowlist(tools: string[] | undefined): string | null {
  if (!tools || tools.length === 0) return null;
  return [...new Set([...tools, ...CONTROL_TOOLS])].join(",");
}

export function isHeadlessCapable(cli: HarnessCli): boolean {
  return cli === "pi" || cli === "claude" || cli === "codex" || cli === "opencode";
}

export function buildLaunch(o: LaunchOpts): string {
  const q = shellQuote;
  const env: string[] = [`PI_SUBAGENT_NAME=${q(o.name)}`];
  if (o.agentName) env.push(`PI_SUBAGENT_AGENT=${q(o.agentName)}`);
  if (o.autoExit) env.push("PI_SUBAGENT_AUTO_EXIT=1");
  if (o.harness === "pi") {
    if (!o.sessionFile) throw new Error("pi launch requires sessionFile");
    if (!o.exitFile) throw new Error("pi launch requires exitFile");
    env.push(`PI_SUBAGENT_EXIT_FILE=${q(o.exitFile)}`);
  }
  if (process.env.PI_CODING_AGENT_DIR) {
    env.push(`PI_CODING_AGENT_DIR=${q(process.env.PI_CODING_AGENT_DIR)}`);
  }

  let args: string[];
  switch (o.harness) {
    case "pi": {
      args = ["pi", "--no-extensions", "--session", q(o.sessionFile!)];
      // Quoted literals ("json") match the launch-command contract; -p stays bare.
      if (o.mode === "headless") args.push("--mode", q("json"), "-p");
      if (o.childExtPath) args.push("-e", q(o.childExtPath));
      for (const ext of o.extensions ?? []) args.push("-e", q(ext));
      if (o.model) args.push("--model", q(o.model));
      if (o.thinking) args.push("--thinking", q(o.thinking));
      const allow = buildToolAllowlist(o.tools);
      if (allow) args.push("--tools", q(allow));
      for (const s of o.skills ?? []) args.push("--skill", q(s));
      if (o.systemPromptAppend) args.push("--append-system-prompt", q(o.systemPromptAppend));
      args.push(q(o.task));
      break;
    }
    case "claude": {
      args = ["claude"];
      if (o.mode === "headless") args.push("--print", "--output-format", q("text"));
      else args.push("--dangerously-skip-permissions");
      if (o.model) args.push("--model", q(o.model));
      if (o.systemPromptAppend) args.push("--append-system-prompt", q(o.systemPromptAppend));
      args.push(q(o.task));
      break;
    }
    case "codex": {
      args = ["codex"];
      if (o.mode === "headless") args.push("exec");
      if (o.model) args.push("--model", q(o.model));
      if (o.thinking && ["low", "medium", "high"].includes(o.thinking)) {
        args.push("--reasoning-effort", q(o.thinking));
      }
      if (o.systemPromptAppend) args.push("--system-prompt", q(o.systemPromptAppend));
      args.push(q(o.task));
      break;
    }
    case "grok": {
      if (o.mode === "headless") throw new Error("grok CLI does not support headless mode");
      args = ["grok"];
      if (o.model) args.push("--model", q(o.model));
      if (o.systemPromptAppend) args.push("--system-prompt", q(o.systemPromptAppend));
      args.push(q(o.task));
      break;
    }
    case "opencode": {
      args = ["opencode", "run"];
      if (o.model) args.push("--model", q(o.model));
      args.push(q(o.task));
      break;
    }
    default: {
      if (o.mode === "headless") {
        throw new Error(`harness "${o.harness}" does not support headless mode`);
      }
      args = [o.harness as string];
      if (o.model) args.push("--model", q(o.model));
      args.push(q(o.task));
      break;
    }
  }

  const envPrefix = env.length > 0 ? `${env.join(" ")} ` : "";
  const cmd = `cd ${q(o.cwd)} && ${envPrefix}${args.join(" ")}`;
  return o.mode === "pane" ? `${cmd}; echo '__PIPL_EXIT_'$?'__'` : cmd;
}