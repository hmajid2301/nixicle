// extensions/pipelines/config.test.ts
import { describe, expect, test, beforeAll } from "bun:test";
import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
  DEFAULT_PANE_CONFIG,
  DEFAULT_STALL_GRACE_MS,
  loadConfig,
  pipelinesDir,
  parentModelFor,
  resolveBtwTools,
  resolveModel,
  resolvePaneConfig,
  resolvePersistentMax,
  resolveStallGraceMs,
  subDir,
} from "./config.ts";

let dir: string;

beforeAll(() => {
  dir = mkdtempSync(join(tmpdir(), "pipelines-config-"));
  process.env.PIPELINES_DIR = dir;
});

describe("pipelinesDir", () => {
  test("respects PIPELINES_DIR and creates it", () => {
    expect(pipelinesDir()).toBe(dir);
  });
});

describe("subDir", () => {
  test("creates and returns named subdirs", () => {
    expect(subDir("state")).toBe(join(dir, "state"));
    expect(subDir("sessions")).toBe(join(dir, "sessions"));
  });
});

describe("loadConfig", () => {
  test("empty when missing or invalid", () => {
    expect(loadConfig()).toEqual({});
    writeFileSync(join(dir, "config.json"), "{ not json");
    expect(loadConfig()).toEqual({});
  });
  test("parses models and widget sections", () => {
    writeFileSync(
      join(dir, "config.json"),
      JSON.stringify({ models: { default: "m-default", agents: { scout: "m-scout" } }, widget: { collapsed: true } }),
    );
    const cfg = loadConfig();
    expect(cfg.models?.default).toBe("m-default");
    expect(cfg.widget?.collapsed).toBe(true);
  });
  test("parses stageTimeoutMinutes", () => {
    const d = mkdtempSync(join(tmpdir(), "pipelines-config-timeout-"));
    writeFileSync(join(d, "config.json"), JSON.stringify({ stageTimeoutMinutes: 15 }));
    expect(loadConfig(d).stageTimeoutMinutes).toBe(15);
  });
});

describe("resolvePaneConfig", () => {
  test("defaults to grouped/right/4", () => {
    expect(resolvePaneConfig({})).toEqual(DEFAULT_PANE_CONFIG);
  });
  test("honours explicit overrides", () => {
    expect(resolvePaneConfig({ panes: { mode: "split", direction: "down", maxPerTab: 2 } })).toEqual({
      mode: "split",
      direction: "down",
      maxPerTab: 2,
    });
  });
  test("falls back on invalid values", () => {
    // SAFETY: an intentionally malformed config exercises the fallback branch.
    const invalid = { panes: { mode: "nope", direction: "left", maxPerTab: 0 } } as any;
    expect(resolvePaneConfig(invalid)).toEqual(DEFAULT_PANE_CONFIG);
  });
});

describe("resolvePersistentMax", () => {
  test("defaults to 3 and honours a positive override", () => {
    expect(resolvePersistentMax({})).toBe(3);
    expect(resolvePersistentMax({ persistent: { maxAgents: 5 } })).toBe(5);
  });
  test("falls back on invalid values", () => {
    expect(resolvePersistentMax({ persistent: { maxAgents: 0 } })).toBe(3);
    expect(resolvePersistentMax({ persistent: { maxAgents: -1 } })).toBe(3);
  });
});

describe("resolveStallGraceMs", () => {
  test("defaults and honours a non-negative override", () => {
    expect(resolveStallGraceMs({})).toBe(DEFAULT_STALL_GRACE_MS);
    expect(resolveStallGraceMs({ supervision: { stallGraceMs: 1000 } })).toBe(1000);
  });
  test("falls back on invalid values", () => {
    expect(resolveStallGraceMs({ supervision: { stallGraceMs: -1 } })).toBe(DEFAULT_STALL_GRACE_MS);
    expect(resolveStallGraceMs({ supervision: { stallGraceMs: 1.5 } })).toBe(DEFAULT_STALL_GRACE_MS);
  });
});

describe("resolveBtwTools", () => {
  test("defaults to a read-only toolset", () => {
    expect(resolveBtwTools({})).toEqual(["read", "grep", "find", "ls"]);
  });
  test("honours a non-empty override and rejects junk", () => {
    expect(resolveBtwTools({ btw: { tools: ["read"] } })).toEqual(["read"]);
    expect(resolveBtwTools({ btw: { tools: [] } })).toEqual(["read", "grep", "find", "ls"]);
  });
});

describe("resolveModel", () => {
  test("arg > agent > config-agent > config-default > parent", () => {
    // loaded inside the test: describe callbacks run during collection, before
    // beforeAll sets PIPELINES_DIR and before loadConfig tests write config.json
    const cfg = loadConfig();
    expect(resolveModel(cfg, "scout", undefined, "m-arg", "m-parent")).toBe("m-arg");
    expect(resolveModel(cfg, "scout", "m-agent", undefined, "m-parent")).toBe("m-agent");
    expect(resolveModel(cfg, "scout", undefined, undefined, "m-parent")).toBe("m-scout");
    expect(resolveModel(cfg, "unknown", undefined, undefined, "m-parent")).toBe("m-default");
    // empty config + nothing else → undefined (harness default applies).
    // The brief passed the shared cfg here, but that cfg has default "m-default"
    // (asserted above), so expecting undefined contradicts the chain; {} pins
    // the terminal fallback instead.
    expect(resolveModel({}, "unknown", undefined, undefined, undefined)).toBeUndefined();
  });
});

describe("parentModelFor", () => {
  test("pi (and an unset harness) inherit the parent model", () => {
    expect(parentModelFor("pi", "opencode-go/glm-5.3")).toBe("opencode-go/glm-5.3");
    expect(parentModelFor(undefined, "opencode-go/glm-5.3")).toBe("opencode-go/glm-5.3");
  });

  test("non-pi CLIs never inherit a pi model id", () => {
    for (const harness of ["codex", "claude", "grok", "opencode", "custom-cli"]) {
      expect(parentModelFor(harness, "opencode-go/glm-5.3")).toBeUndefined();
    }
  });
});
