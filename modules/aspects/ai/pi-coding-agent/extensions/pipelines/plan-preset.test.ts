import { describe, expect, mock, test } from "bun:test";

mock.module("@mariozechner/pi-ai", () => ({
  StringEnum: {},
  Type: {},
}));
mock.module("@mariozechner/pi-tui", () => ({
  truncateToWidth: (text: string) => text,
}));

const { buildPlanPresetStages } = await import("./index.ts");

describe("buildPlanPresetStages", () => {
  test("inserts scout before planner", () => {
    const stages = buildPlanPresetStages("ship feature", ["scout", "planner", "worker", "reviewer", "visual-tester"]);
    expect(stages.map((s) => s.id)).toEqual(["scout", "plan", "confirm", "implement", "review", "test"]);
    expect(stages.find((s) => s.id === "plan")?.dependsOn).toEqual(["scout"]);
    expect(stages.find((s) => s.id === "confirm")?.dependsOn).toEqual(["plan"]);
  });

  test("planner task consumes scout output", () => {
    const stages = buildPlanPresetStages("ship feature", ["scout", "planner", "worker", "reviewer", "visual-tester"]);
    const plan = stages.find((s) => s.id === "plan");
    expect(plan?.task).toContain("{stage:scout}");
    expect(plan?.agent).toBe("planner");
  });

  test("falls back when planner missing", () => {
    const stages = buildPlanPresetStages("ship feature", ["scout", "worker", "reviewer", "visual-tester"]);
    expect(stages.find((s) => s.id === "plan")?.agent).toBe("scout");
  });
});
