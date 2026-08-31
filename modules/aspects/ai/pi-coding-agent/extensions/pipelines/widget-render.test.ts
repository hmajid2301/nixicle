// extensions/pipelines/widget-render.test.ts
import { describe, expect, test } from "bun:test";
import { collapsedLine, renderDashboard, type DashboardVM, type RowVM } from "./widget-render.ts";

const vm: DashboardVM = {
  title: "plan-demo",
  active: 1,
  waiting: 1,
  done: 0,
  failed: 0,
  tokens: "15.5k",
  attention: false,
  rows: [
    { branch: "root", glyph: "◈", name: "plan-demo", status: "active", time: "0:42", tools: "", note: "" },
    { branch: "tee", glyph: "✓", name: "plan", status: "done", time: "0:10", tools: "", note: "" },
    { branch: "elbow", glyph: "●", name: "review", status: "running", time: "0:32", tools: "read", note: "audit findings" },
  ],
};

describe("renderDashboard", () => {
  test("box borders at exact width 60 on every line", () => {
    const lines = renderDashboard(vm, 60);
    expect(lines.length).toBe(6); // top, header, 3 rows, bottom
    expect(lines[0]).toBe("╭" + "─".repeat(58) + "╮");
    expect(lines[5]).toBe("╰" + "─".repeat(58) + "╯");
    for (const line of lines) expect(line.length).toBe(60);
  });
  test("header carries title, counts, tokens", () => {
    const line = renderDashboard(vm, 60)[1];
    expect(line.startsWith("│ plan-demo · ●1 active · ○1 waiting · 15.5k tok")).toBe(true);
    expect(line.endsWith("│")).toBe(true);
  });
  test("root row and stage rows with branch glyphs + aligned columns", () => {
    const lines = renderDashboard(vm, 60);
    expect(lines[2].startsWith("│   ◈  plan-demo")).toBe(true);
    expect(lines[2]).toContain("active");
    expect(lines[2]).toContain("0:42");
    expect(lines[3].startsWith("│   ├ ✓  plan")).toBe(true);
    expect(lines[3]).toContain("done");
    expect(lines[4].startsWith("│   └ ●  review")).toBe(true);
    expect(lines[4]).toContain("running");
    expect(lines[4]).toContain("read");
    expect(lines[4]).toContain("audit findings");
  });
  test("truncates long notes to box width", () => {
    const wide = renderDashboard({
      ...vm,
      rows: [{ branch: "root", glyph: "◈", name: "x", status: "s", time: "0:00", tools: "", note: "n".repeat(80) }],
    }, 60);
    expect(wide[2].length).toBe(60);
  });
  test("over-long column values truncate with a visible ellipsis", () => {
    const lines = renderDashboard({
      ...vm,
      rows: [{ branch: "root", glyph: "◈", name: "very-long-pipeline-name-xyz", status: "active", time: "0:42", tools: "", note: "" }],
    }, 60);
    expect(lines[2]).toContain("very-long…");
    expect(lines[2].length).toBe(60);
  });
  test("attention flag adds ⚑ to header", () => {
    const lines = renderDashboard({ ...vm, attention: true }, 60);
    expect(lines[1]).toContain("⚑");
    expect(lines[1].length).toBe(60);
  });
});

describe("collapsedLine", () => {
  test("one-liner summary", () => {
    expect(collapsedLine(vm)).toBe(" ◈ Pipelines · ●1 running · ○1 waiting · 15.5k tok");
  });
});
