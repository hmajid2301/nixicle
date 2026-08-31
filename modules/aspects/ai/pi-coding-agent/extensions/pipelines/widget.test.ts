// extensions/pipelines/widget.test.ts
import { describe, expect, test } from "bun:test";
import { buildVM } from "./widget-render.ts";
import type { PipelineState } from "./pipeline.ts";
import type { RunHandle } from "./types.ts";

function makePipeline(over: Partial<PipelineState> & { id: string; name: string }): PipelineState {
  return {
    id: over.id,
    name: over.name,
    createdAt: Date.now(),
    status: "active",
    stages: [],
    ...over,
  };
}

const noRuns: { handle: RunHandle; stageLabel?: string }[] = [];

describe("buildVM", () => {
  test("shows a recently-finished pipeline as a dimmed root row", () => {
    const p = makePipeline({
      id: "pl1",
      name: "done-pipe",
      status: "complete",
      finishedAt: Date.now() - 5_000,
    });
    const vm = buildVM({ pipelines: [p], runs: noRuns });
    const row = vm.rows.find((r) => r.name === "done-pipe");
    expect(row).toBeDefined();
    expect(row!.dimmed).toBe(true);
    expect(row!.glyph).toBe("✓");
    expect(row!.status).toBe("complete");
  });

  test("hides a finished pipeline older than the grace window", () => {
    const p = makePipeline({
      id: "pl2",
      name: "old-pipe",
      status: "failed",
      finishedAt: Date.now() - 120_000,
    });
    const vm = buildVM({ pipelines: [p], runs: noRuns });
    expect(vm.rows.find((r) => r.name === "old-pipe")).toBeUndefined();
  });

  test("root glyph reflects failed/cancelled status", () => {
    const failed = makePipeline({ id: "a", name: "f", status: "failed", finishedAt: Date.now() - 1_000 });
    const cancelled = makePipeline({ id: "b", name: "c", status: "cancelled", finishedAt: Date.now() - 1_000 });
    const vm = buildVM({ pipelines: [failed, cancelled], runs: noRuns });
    expect(vm.rows.find((r) => r.name === "f")!.glyph).toBe("✗");
    expect(vm.rows.find((r) => r.name === "c")!.glyph).toBe("⊘");
  });

  test("flags a credit-limit pipeline in the note", () => {
    const p = makePipeline({ id: "pl3", name: "billing", status: "active", creditLimit: true });
    const vm = buildVM({ pipelines: [p], runs: noRuns });
    expect(vm.rows.find((r) => r.name === "billing")!.note).toContain("credit");
  });

  test("counts done/failed across pipelines", () => {
    const done = makePipeline({ id: "a", name: "d", status: "complete", finishedAt: Date.now() - 1_000 });
    const failed = makePipeline({ id: "b", name: "f", status: "failed", finishedAt: Date.now() - 1_000 });
    const vm = buildVM({ pipelines: [done, failed], runs: noRuns });
    expect(vm.done).toBe(1);
    expect(vm.failed).toBe(1);
  });
});
