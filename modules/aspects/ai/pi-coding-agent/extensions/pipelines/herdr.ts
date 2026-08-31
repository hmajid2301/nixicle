// extensions/pipelines/herdr.ts
// herdr CLI wrappers. Builders/parsers are pure; exec paths are exercised by later integration tasks.
import { execFileSync, execSync } from "node:child_process";

let availableCache: boolean | null = null;

export function isHerdrAvailable(): boolean {
  if (availableCache === null) {
    availableCache = process.env.HERDR_ENV === "1" && hasBinary("herdr");
  }
  return availableCache;
}

function hasBinary(cmd: string): boolean {
  try {
    execSync(`command -v ${cmd}`, { stdio: "ignore" });
    return true;
  } catch {
    return false;
  }
}

function run(args: string[]): string {
  return execFileSync("herdr", args, { encoding: "utf8" });
}

function parseJson(value: string): any {
  try {
    return JSON.parse(value);
  } catch {
    return null;
  }
}

export function buildTabCreateArgs(name: string, cwd: string, workspaceId: string): string[] {
  return [
    "tab", "create", "--workspace", workspaceId,
    "--label", name, "--cwd", cwd, "--no-focus",
  ];
}

export function extractRootPaneId(output: string): string {
  const paneId = parseJson(output)?.result?.root_pane?.pane_id;
  if (typeof paneId !== "string" || !paneId) {
    throw new Error(`Unexpected herdr tab create output: ${output.trim() || "(empty)"}`);
  }
  return paneId;
}

export function currentPaneInfo(): { paneId: string; tabId: string; workspaceId: string } {
  const paneId = process.env.HERDR_PANE_ID;
  const tabId = process.env.HERDR_TAB_ID;
  const workspaceId = process.env.HERDR_WORKSPACE_ID;
  if (!paneId || !tabId || !workspaceId) {
    // --current: target the calling pane; without it herdr may pick the
    // UI-focused pane, which can belong to another client (wrong workspace).
    const pane = parseJson(run(["pane", "current", "--current"]))?.result?.pane;
    if (!pane?.pane_id || !pane?.tab_id || !pane?.workspace_id) {
      throw new Error("herdr pane current: no pane info");
    }
    return { paneId: pane.pane_id, tabId: pane.tab_id, workspaceId: pane.workspace_id };
  }
  return { paneId, tabId, workspaceId };
}

export type PaneState = "present" | "missing" | "unavailable";

export function parsePaneGet(output: string, paneId: string): PaneState {
  const parsed = parseJson(output);
  const err = parsed?.error;
  if (err?.code === "pane_not_found" || err?.code === "not_found") return "missing";
  if (parsed?.result?.pane?.pane_id === paneId) return "present";
  return "unavailable";
}

export function createPane(name: string, cwd: string): string {
  const { workspaceId } = currentPaneInfo();
  const paneId = extractRootPaneId(run(buildTabCreateArgs(name, cwd, workspaceId)));
  try {
    run(["pane", "rename", paneId, name]);
  } catch {
    // cosmetic — pane label is optional
  }
  return paneId;
}

export function paneRun(paneId: string, command: string): void {
  run(["pane", "run", paneId, command]);
}

export function paneSendKeys(paneId: string, keys: string): void {
  run(["pane", "send-keys", paneId, keys]);
}

export function paneRead(paneId: string, lines = 50): string {
  return run(["pane", "read", paneId, "--source", "visible", "--lines", String(lines)]);
}

export async function paneReadAsync(paneId: string, lines = 50): Promise<string> {
  const { execFile } = await import("node:child_process");
  const { promisify } = await import("node:util");
  const { stdout } = await promisify(execFile)(
    "herdr",
    ["pane", "read", paneId, "--source", "visible", "--lines", String(lines)],
    { encoding: "utf8" },
  );
  return stdout;
}

export async function paneGet(paneId: string): Promise<PaneState> {
  const { execFile } = await import("node:child_process");
  const { promisify } = await import("node:util");
  try {
    const { stdout } = await promisify(execFile)("herdr", ["pane", "get", paneId], { encoding: "utf8" });
    return parsePaneGet(stdout, paneId);
  } catch (e: any) {
    for (const raw of [e?.stderr, e?.stdout]) {
      if (typeof raw !== "string" || !raw.trim()) continue;
      if (parsePaneGet(raw, paneId) === "missing") return "missing";
      if (/\b(?:pane_not_found|not_found)\b/.test(raw)) return "missing";
    }
    return "unavailable";
  }
}

export function paneClose(paneId: string): void {
  run(["pane", "close", paneId]);
}
