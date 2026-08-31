// extensions/pipelines/config.test.ts
import { describe, expect, test, beforeAll } from "bun:test";
import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { loadConfig, pipelinesDir, resolveModel, subDir } from "./config.ts";

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
