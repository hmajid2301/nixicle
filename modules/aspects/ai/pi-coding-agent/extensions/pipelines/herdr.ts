// extensions/pipelines/herdr.ts
// Thin herdr CLI seam: availability, exec, and pane/tab primitives.
// Placement policy and ownership live in placement.ts.
import { execFileSync } from "node:child_process";

let availableCache: boolean | null = null;

export function isHerdrAvailable(): boolean {
  if (availableCache === null) {
    const inHerdr = process.env.HERDR_ENV === "1";
    const inTuios = process.env.TUIOS_ENV === "1" && !!process.env.HERDR_BIN_PATH;
    availableCache = (inHerdr || inTuios) && hasBinary(herdrBinary());
  }
  return availableCache;
}

function herdrBinary(): string {
  return process.env.HERDR_BIN_PATH || "herdr";
}

function hasBinary(cmd: string): boolean {
  try {
    execFileSync("/bin/sh", ["-c", 'command -v "$1"', "sh", cmd], { stdio: "ignore" });
    return true;
  } catch {
    return false;
  }
}

export function herdrExec(args: string[]): string {
  return execFileSync(herdrBinary(), args, { encoding: "utf8" });
}

export function parseJson(value: string): any {
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
  // Resolve the calling pane fresh: inherited HERDR_* IDs go stale after a
  // pane moves, and `--current` keeps us on the caller rather than the
  // UI-focused pane (which may belong to another client/workspace).
  try {
    const pane = parseJson(herdrExec(["pane", "current", "--current"]))?.result?.pane;
    if (pane?.pane_id && pane?.tab_id && pane?.workspace_id) {
      return { paneId: pane.pane_id, tabId: pane.tab_id, workspaceId: pane.workspace_id };
    }
  } catch {
    // not inside a herdr pane yet — fall back to inherited env below
  }
  const paneId = process.env.HERDR_PANE_ID;
  const tabId = process.env.HERDR_TAB_ID;
  const workspaceId = process.env.HERDR_WORKSPACE_ID;
  if (!paneId || !tabId || !workspaceId) throw new Error("herdr pane current: no pane info");
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
  const paneId = extractRootPaneId(herdrExec(buildTabCreateArgs(name, cwd, workspaceId)));
  try {
    herdrExec(["pane", "rename", paneId, name]);
  } catch {
    // cosmetic — pane label is optional
  }
  return paneId;
}

export function paneRun(paneId: string, command: string): void {
  herdrExec(["pane", "run", paneId, command]);
}

export function paneSendKeys(paneId: string, keys: string): void {
  herdrExec(["pane", "send-keys", paneId, keys]);
}

export function paneRead(paneId: string, lines = 50): string {
  return herdrExec(["pane", "read", paneId, "--source", "visible", "--lines", String(lines)]);
}

export async function paneReadAsync(paneId: string, lines = 50): Promise<string> {
  const { execFile } = await import("node:child_process");
  const { promisify } = await import("node:util");
  const { stdout } = await promisify(execFile)(
    herdrBinary(),
    ["pane", "read", paneId, "--source", "visible", "--lines", String(lines)],
    { encoding: "utf8" },
  );
  return stdout;
}

export async function paneGet(paneId: string): Promise<PaneState> {
  const { execFile } = await import("node:child_process");
  const { promisify } = await import("node:util");
  try {
    const { stdout } = await promisify(execFile)(herdrBinary(), ["pane", "get", paneId], { encoding: "utf8" });
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
  herdrExec(["pane", "close", paneId]);
}
