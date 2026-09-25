// extensions/pipelines/herdr.test.ts
import { describe, expect, test } from "bun:test";
import { buildTabCreateArgs, extractRootPaneId, isHerdrAvailable, parsePaneGet } from "./herdr.ts";

describe("buildTabCreateArgs", () => {
  test("targets workspace, labels, cwd, no focus", () => {
    expect(buildTabCreateArgs("scout", "/repo", "ws1")).toEqual([
      "tab", "create", "--workspace", "ws1",
      "--label", "scout", "--cwd", "/repo", "--no-focus",
    ]);
  });
});

describe("extractRootPaneId", () => {
  test("reads result.root_pane.pane_id", () => {
    expect(extractRootPaneId(`{"result":{"root_pane":{"pane_id":"pane-7"}}}`)).toBe("pane-7");
  });
  test("throws on malformed output", () => {
    expect(() => extractRootPaneId("not json")).toThrow(/Unexpected herdr/);
    expect(() => extractRootPaneId(`{"result":{}}`)).toThrow(/Unexpected herdr/);
  });
});

describe("parsePaneGet", () => {
  test("present when pane_id matches", () => {
    expect(parsePaneGet(`{"result":{"pane":{"pane_id":"p1"}}}`, "p1")).toBe("present");
  });
  test("missing on pane_not_found error code", () => {
    expect(parsePaneGet(`{"error":{"code":"pane_not_found"}}`, "p1")).toBe("missing");
  });
  test("missing on not_found code", () => {
    expect(parsePaneGet(`{"error":{"code":"not_found"}}`, "p1")).toBe("missing");
  });
  test("unavailable otherwise", () => {
    expect(parsePaneGet(`{"result":{"pane":{"pane_id":"other"}}}`, "p1")).toBe("unavailable");
    expect(parsePaneGet(`{`, "p1")).toBe("unavailable");
  });
});

describe("isHerdrAvailable", () => {
  test("false when HERDR_ENV is not 1", () => {
    delete process.env.HERDR_ENV;
    expect(isHerdrAvailable()).toBe(false);
  });
});
