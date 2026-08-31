// extensions/pipelines/store.test.ts
import { describe, expect, test, beforeAll } from "bun:test";
import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { deletePipeline, loadPipelines, savePipeline } from "./store.ts";
import type { PipelineState } from "./pipeline.ts";

beforeAll(() => {
  process.env.PIPELINES_DIR = mkdtempSync(join(tmpdir(), "pipelines-store-"));
});

const p: PipelineState = {
  id: "p1", name: "demo", createdAt: 123, status: "active",
  stages: [{ id: "s1", agent: "scout", task: "t", dependsOn: [], gate: false, status: "done", attempt: 1, result: "r" }],
};

describe("store", () => {
  test("save → load roundtrip, delete removes", () => {
    savePipeline(p);
    expect(loadPipelines().map((x) => x.id)).toContain("p1");
    expect(loadPipelines().find((x) => x.id === "p1")?.stages[0].result).toBe("r");
    deletePipeline("p1");
    expect(loadPipelines().map((x) => x.id)).not.toContain("p1");
    deletePipeline("nonexistent"); // no-op, no throw
  });
  test("corrupt state files are skipped", () => {
    savePipeline(p);
    // Brief used `await import("node:fs")` in this non-async callback — a
    // syntax error. Top-level import instead (sanctioned by controller ruling).
    writeFileSync(join(process.env.PIPELINES_DIR!, "state", "junk.json"), "{corrupt");
    const ids = loadPipelines().map((x) => x.id);
    expect(ids).toContain("p1");
    deletePipeline("p1");
  });
});