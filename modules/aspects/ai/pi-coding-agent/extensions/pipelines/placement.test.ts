// extensions/pipelines/placement.test.ts
import { describe, expect, test } from "bun:test";
import {
  buildPaneSplitArgs,
  containsCwd,
  extractPaneId,
  extractTabId,
  matchWorkspace,
  parsePaneList,
  parseWorktreeList,
  pruneDeadTabs,
  selectOwnedTab,
} from "./placement.ts";

describe("buildPaneSplitArgs", () => {
  test("splits parent pane with direction, cwd and no focus", () => {
    expect(buildPaneSplitArgs("pane-1", "down", "/repo")).toEqual([
      "pane", "split", "pane-1", "--direction", "down", "--no-focus", "--cwd", "/repo",
    ]);
  });
});

describe("extractPaneId", () => {
  test("reads result.pane.pane_id", () => {
    expect(extractPaneId(`{"result":{"pane":{"pane_id":"pane-9"}}}`)).toBe("pane-9");
  });
  test("throws on malformed output", () => {
    expect(() => extractPaneId("nope")).toThrow(/Unexpected herdr/);
  });
});

describe("extractTabId", () => {
  test("reads result.tab.tab_id", () => {
    expect(extractTabId(`{"result":{"tab":{"tab_id":"tab-3"}}}`)).toBe("tab-3");
  });
  test("throws when absent", () => {
    expect(() => extractTabId(`{"result":{}}`)).toThrow(/Unexpected herdr/);
  });
});

describe("parsePaneList", () => {
  test("maps pane entries", () => {
    const output = `{"result":{"type":"pane_list","panes":[{"pane_id":"p1","tab_id":"t1","workspace_id":"w1"}]}}`;
    expect(parsePaneList(output)).toEqual([{ paneId: "p1", tabId: "t1", workspaceId: "w1" }]);
  });
  test("throws on wrong type", () => {
    expect(() => parsePaneList(`{"result":{"type":"other","panes":[]}}`)).toThrow(/Unexpected herdr/);
  });
  test("throws on malformed entry", () => {
    expect(() => parsePaneList(`{"result":{"type":"pane_list","panes":[{"pane_id":"p1"}]}}`)).toThrow(
      /Unexpected herdr pane list entry/,
    );
  });
});

describe("parseWorktreeList", () => {
  test("maps open worktrees to workspace + checkout path", () => {
    const output = `{"result":{"type":"worktree_list","worktrees":[{"path":"/repo","open_workspace_id":"w1","branch":"main"}]}}`;
    expect(parseWorktreeList(output)).toEqual([{ workspaceId: "w1", checkoutPath: "/repo" }]);
  });
  test("skips worktrees that are not open in a workspace", () => {
    const output = `{"result":{"type":"worktree_list","worktrees":[{"path":"/closed"},{"path":"/open","open_workspace_id":"w2"}]}}`;
    expect(parseWorktreeList(output)).toEqual([{ workspaceId: "w2", checkoutPath: "/open" }]);
  });
  test("throws on unexpected output", () => {
    expect(() => parseWorktreeList(`{"result":{"type":"other"}}`)).toThrow(/Unexpected herdr/);
  });
});

describe("containsCwd", () => {
  test("true for the root and descendants", () => {
    expect(containsCwd("/repo", "/repo")).toBe(true);
    expect(containsCwd("/repo", "/repo/sub/dir")).toBe(true);
  });
  test("false for siblings and prefix collisions", () => {
    expect(containsCwd("/repo", "/repository")).toBe(false);
    expect(containsCwd("/repo", "/other")).toBe(false);
  });
});

describe("matchWorkspace", () => {
  const worktrees = [
    { workspaceId: "ws-root", checkoutPath: "/repo" },
    { workspaceId: "ws-sub", checkoutPath: "/repo/sub" },
    { workspaceId: "ws-other", checkoutPath: "/elsewhere" },
  ];
  test("prefers the longest containing checkout", () => {
    expect(matchWorkspace(worktrees, "ws-caller", "/repo/sub/dir")).toBe("ws-sub");
  });
  test("falls back to caller when nothing contains cwd", () => {
    expect(matchWorkspace(worktrees, "ws-caller", "/tmp/x")).toBe("ws-caller");
  });
});

describe("selectOwnedTab", () => {
  const panes = [
    { paneId: "p1", tabId: "t1", workspaceId: "w1" },
    { paneId: "p2", tabId: "t1", workspaceId: "w1" },
  ];
  test("reuses an under-capacity tab and prefers an owned anchor", () => {
    const tabs = new Map([["t1", { workspaceId: "w1", panes: new Set(["p2"]) }]]);
    expect(selectOwnedTab(tabs, panes, "w1", 4)).toEqual({ tabId: "t1", anchorPaneId: "p2" });
  });
  test("returns null when the tab is full", () => {
    const tabs = new Map([["t1", { workspaceId: "w1", panes: new Set(["p1", "p2"]) }]]);
    expect(selectOwnedTab(tabs, panes, "w1", 2)).toBeNull();
  });
  test("ignores a tab whose panes are gone without mutating", () => {
    const tabs = new Map([["t-gone", { workspaceId: "w1", panes: new Set(["px"]) }]]);
    expect(selectOwnedTab(tabs, panes, "w1", 4)).toBeNull();
    expect(tabs.has("t-gone")).toBe(true);
  });
  test("ignores tabs in other workspaces", () => {
    const tabs = new Map([["t1", { workspaceId: "w2", panes: new Set(["p1"]) }]]);
    expect(selectOwnedTab(tabs, panes, "w1", 4)).toBeNull();
  });
});

describe("pruneDeadTabs", () => {
  test("drops owned tabs with no live panes in the workspace", () => {
    const tabs = new Map([
      ["t-live", { workspaceId: "w1", panes: new Set(["p1"]) }],
      ["t-gone", { workspaceId: "w1", panes: new Set(["px"]) }],
      ["t-other", { workspaceId: "w2", panes: new Set(["px"]) }],
    ]);
    pruneDeadTabs(tabs, [{ paneId: "p1", tabId: "t-live", workspaceId: "w1" }], "w1");
    expect([...tabs.keys()]).toEqual(["t-live", "t-other"]);
  });
});
