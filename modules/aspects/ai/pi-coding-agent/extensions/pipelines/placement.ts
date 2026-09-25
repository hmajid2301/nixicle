// extensions/pipelines/placement.ts
// Subagent pane placement policy: grouped Agents tabs, splits, and ownership.
import { realpathSync } from "node:fs";
import { isAbsolute, relative, resolve, sep } from "node:path";
import { buildTabCreateArgs, createPane, currentPaneInfo, extractRootPaneId, herdrExec, parseJson } from "./herdr.ts";

export type PaneDirection = "right" | "down";

export interface PanePlacement {
  mode: "grouped" | "tab" | "split";
  direction: PaneDirection;
  maxPerTab: number;
}

export interface PaneEntry {
  paneId: string;
  tabId: string;
  workspaceId: string;
}

export interface WorktreeEntry {
  workspaceId: string;
  checkoutPath: string;
}

export function buildPaneSplitArgs(parentPaneId: string, direction: PaneDirection, cwd: string): string[] {
  return ["pane", "split", parentPaneId, "--direction", direction, "--no-focus", "--cwd", cwd];
}

export function extractPaneId(output: string): string {
  const paneId = parseJson(output)?.result?.pane?.pane_id;
  if (typeof paneId !== "string" || !paneId) {
    throw new Error(`Unexpected herdr pane split output: ${output.trim() || "(empty)"}`);
  }
  return paneId;
}

export function extractTabId(output: string): string {
  const tabId = parseJson(output)?.result?.tab?.tab_id;
  if (typeof tabId !== "string" || !tabId) {
    throw new Error(`Unexpected herdr tab create identity: ${output.trim() || "(empty)"}`);
  }
  return tabId;
}

function recordOf(value: unknown): Record<string, unknown> | null {
  return typeof value === "object" && value !== null ? (value as Record<string, unknown>) : null;
}

export function parsePaneList(output: string): PaneEntry[] {
  const parsed = parseJson(output);
  const panes = parsed?.result?.panes;
  if (parsed?.result?.type !== "pane_list" || !Array.isArray(panes)) {
    throw new Error(`Unexpected herdr pane list output: ${output.trim() || "(empty)"}`);
  }
  return panes.map((raw: unknown): PaneEntry => {
    const pane = recordOf(raw);
    const paneId = pane?.pane_id;
    const tabId = pane?.tab_id;
    const workspaceId = pane?.workspace_id;
    if (typeof paneId !== "string" || typeof tabId !== "string" || typeof workspaceId !== "string") {
      throw new Error("Unexpected herdr pane list entry");
    }
    return { paneId, tabId, workspaceId };
  });
}

/** Open worktree workspaces from `herdr worktree list` (only open ones have a workspace). */
export function parseWorktreeList(output: string): WorktreeEntry[] {
  const parsed = parseJson(output);
  const worktrees = parsed?.result?.worktrees;
  if (parsed?.result?.type !== "worktree_list" || !Array.isArray(worktrees)) {
    throw new Error(`Unexpected herdr worktree list output: ${output.trim() || "(empty)"}`);
  }
  const entries: WorktreeEntry[] = [];
  for (const raw of worktrees) {
    const worktree = recordOf(raw);
    const workspaceId = worktree?.open_workspace_id;
    const checkoutPath = worktree?.path;
    if (typeof workspaceId === "string" && workspaceId && typeof checkoutPath === "string" && checkoutPath) {
      entries.push({ workspaceId, checkoutPath });
    }
  }
  return entries;
}

function canonicalPath(path: string): string {
  try {
    return realpathSync(path);
  } catch {
    return resolve(path);
  }
}

export function containsCwd(root: string, cwd: string): boolean {
  const child = relative(root, cwd);
  return child === "" || (child !== ".." && !child.startsWith(`..${sep}`) && !isAbsolute(child));
}

/** Pick the workspace whose checkout contains cwd, preferring the longest match, then the caller's. */
export function matchWorkspace(worktrees: WorktreeEntry[], callerWorkspaceId: string, cwd: string): string {
  const target = canonicalPath(cwd);
  let workspaceId = callerWorkspaceId;
  let matchLength = -1;
  for (const worktree of worktrees) {
    const canonical = canonicalPath(worktree.checkoutPath);
    if (
      containsCwd(canonical, target) &&
      (canonical.length > matchLength || (canonical.length === matchLength && worktree.workspaceId === callerWorkspaceId))
    ) {
      workspaceId = worktree.workspaceId;
      matchLength = canonical.length;
    }
  }
  return workspaceId;
}

export interface OwnedAgentsTab {
  workspaceId: string;
  panes: Set<string>;
}

// Ownership is process-local and survives /reload via a global symbol, matching
// the Herdr Agents tab lifecycle. Separate parent processes never share tabs.
const AGENTS_TABS_KEY = Symbol.for("pi-pipelines:agents-tabs");
const placementGlobal = globalThis as typeof globalThis & { [AGENTS_TABS_KEY]?: Map<string, OwnedAgentsTab> };
const agentsTabs = (placementGlobal[AGENTS_TABS_KEY] ??= new Map<string, OwnedAgentsTab>());

/** Drop owned tabs in a workspace whose panes are all gone. */
export function pruneDeadTabs(tabs: Map<string, OwnedAgentsTab>, panes: PaneEntry[], workspaceId: string): void {
  for (const [tabId, owned] of tabs) {
    if (owned.workspaceId !== workspaceId) continue;
    if (!panes.some((pane) => pane.tabId === tabId && pane.workspaceId === workspaceId)) tabs.delete(tabId);
  }
}

/** Pick a reusable owned tab with spare capacity. Pure — no pruning. */
export function selectOwnedTab(
  tabs: Map<string, OwnedAgentsTab>,
  panes: PaneEntry[],
  workspaceId: string,
  maxPerTab: number,
): { tabId: string; anchorPaneId: string } | null {
  for (const [tabId, owned] of tabs) {
    if (owned.workspaceId !== workspaceId) continue;
    const live = panes.filter((pane) => pane.tabId === tabId && pane.workspaceId === workspaceId);
    if (live.length === 0 || live.length >= maxPerTab) continue;
    const anchor = live.find((pane) => owned.panes.has(pane.paneId)) ?? live[0];
    return { tabId, anchorPaneId: anchor.paneId };
  }
  return null;
}

/** Split the caller's current pane, returning the new child pane ID. */
export function createSplitPane(name: string, direction: PaneDirection, cwd: string): string {
  const { paneId: parentPaneId } = currentPaneInfo();
  const paneId = extractPaneId(herdrExec(buildPaneSplitArgs(parentPaneId, direction, cwd)));
  renameQuiet(paneId, name);
  return paneId;
}

/**
 * Place a child in an owned `Agents` tab in the target checkout's workspace,
 * splitting an existing tab until it holds `maxPerTab` panes.
 */
export function createGroupedPane(name: string, cwd: string, maxPerTab: number, direction: PaneDirection): string {
  const callerWorkspaceId = currentPaneInfo().workspaceId;
  let workspaceId = callerWorkspaceId;
  try {
    workspaceId = matchWorkspace(parseWorktreeList(herdrExec(["worktree", "list"])), callerWorkspaceId, cwd);
  } catch {
    // no worktree info (e.g. a non-git cwd) — fall back to the caller's workspace
  }
  const panes = parsePaneList(herdrExec(["pane", "list"]));
  pruneDeadTabs(agentsTabs, panes, workspaceId);
  const reusable = selectOwnedTab(agentsTabs, panes, workspaceId, maxPerTab);
  let paneId: string;
  if (reusable) {
    paneId = extractPaneId(herdrExec(buildPaneSplitArgs(reusable.anchorPaneId, direction, cwd)));
    agentsTabs.get(reusable.tabId)?.panes.add(paneId);
  } else {
    const count = [...agentsTabs.values()].filter((tab) => tab.workspaceId === workspaceId).length;
    const label = count === 0 ? "Agents" : `Agents ${count + 1}`;
    const output = herdrExec(buildTabCreateArgs(label, cwd, workspaceId));
    paneId = extractRootPaneId(output);
    agentsTabs.set(extractTabId(output), { workspaceId, panes: new Set([paneId]) });
  }
  renameQuiet(paneId, name);
  return paneId;
}

export function placePane(name: string, cwd: string, placement: PanePlacement): string {
  if (placement.mode === "split") return createSplitPane(name, placement.direction, cwd);
  if (placement.mode === "tab") return createPane(name, cwd);
  return createGroupedPane(name, cwd, placement.maxPerTab, placement.direction);
}

function renameQuiet(paneId: string, name: string): void {
  try {
    herdrExec(["pane", "rename", paneId, name]);
  } catch {
    // cosmetic — pane label is optional
  }
}
