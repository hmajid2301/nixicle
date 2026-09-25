// extensions/pipelines/specialists.test.ts
import { describe, expect, mock, test } from "bun:test";
import type { SpecialistDeps, SpecialistRun } from "./specialists.ts";
import type { RunHandle } from "./types.ts";

// specialists.ts builds tool schemas with pi-ai's Type at import time; stub it
// so the module loads outside the Pi runtime.
mock.module("@mariozechner/pi-ai", () => ({
  Type: {
    Object: (shape: unknown) => shape,
    Optional: (schema: unknown) => schema,
    String: (options: unknown) => options,
  },
}));

const { registerSpecialistTools } = await import("./specialists.ts");

function runHandle(id: string, name = "expert"): RunHandle {
  return {
    id,
    name,
    backend: "pane",
    paneId: `pane-${id}`,
    startedAt: Date.now(),
    completion: Promise.resolve({ reason: "done", exitCode: 0 }),
    interrupt: async () => {},
  };
}

function specialist(retainPane: boolean, retained = true, id = "r1"): SpecialistRun {
  return { req: { retainPane } as any, handle: runHandle(id), retained };
}

function setup(overrides: Partial<SpecialistDeps> = {}) {
  const tools: any[] = [];
  const calls: string[] = [];
  const deps: SpecialistDeps = {
    find: () => undefined,
    send: () => null,
    stop: (id) => calls.push(`stop:${id}`),
    ...overrides,
  };
  registerSpecialistTools({ registerTool: (def: any) => tools.push(def) } as any, deps);
  return { tools, calls };
}

function tool(tools: any[], name: string) {
  return tools.find((t) => t.name === name);
}

describe("subagent_send", () => {
  test("errors when nothing matches", async () => {
    const { tools } = setup();
    const result = await tool(tools, "subagent_send").execute("id", { id: "nope", message: "hi" });
    expect(result.isError).toBe(true);
  });

  test("refuses a non-persistent run", async () => {
    const { tools } = setup({ find: () => ({ runId: "r1", run: specialist(false) }) });
    const result = await tool(tools, "subagent_send").execute("id", { id: "r1", message: "hi" });
    expect(result.isError).toBe(true);
  });

  test("refuses a specialist that is still running", async () => {
    const { tools, calls } = setup({
      find: () => ({ runId: "r1", run: specialist(true, false) }),
      send: () => {
        calls.push("send");
        return null;
      },
    });
    const result = await tool(tools, "subagent_send").execute("id", { id: "r1", message: "hi" });
    expect(result.isError).toBe(true);
    expect(result.content[0].text).toContain("still working");
    expect(calls).not.toContain("send");
  });

  test("sends to a persistent specialist and reports the resumed run", async () => {
    const { tools, calls } = setup({
      find: () => ({ runId: "r1", run: specialist(true) }),
      send: (runId, _run, message) => {
        calls.push(`send:${runId}:${message}`);
        return runHandle("r2");
      },
    });
    const result = await tool(tools, "subagent_send").execute("id", { id: "r1", message: "next" });
    expect(result.isError).toBeUndefined();
    expect(calls).toContain("send:r1:next");
    expect(result.content[0].text).toContain("r2");
  });

  test("errors when the pane cannot be resumed", async () => {
    const { tools } = setup({ find: () => ({ runId: "r1", run: specialist(true) }), send: () => null });
    const result = await tool(tools, "subagent_send").execute("id", { id: "r1", message: "next" });
    expect(result.isError).toBe(true);
  });
});

describe("subagent_stop", () => {
  test("stops a persistent specialist", async () => {
    const { tools, calls } = setup({ find: () => ({ runId: "r1", run: specialist(true) }) });
    const result = await tool(tools, "subagent_stop").execute("id", { id: "r1" });
    expect(calls).toContain("stop:r1");
    expect(result.content[0].text).toContain("r1");
  });

  test("refuses a non-persistent run", async () => {
    const { tools } = setup({ find: () => ({ runId: "r1", run: specialist(false) }) });
    const result = await tool(tools, "subagent_stop").execute("id", { id: "r1" });
    expect(result.isError).toBe(true);
  });

  test("refuses to stop a specialist that is still running", async () => {
    const { tools, calls } = setup({ find: () => ({ runId: "r1", run: specialist(true, false) }) });
    const result = await tool(tools, "subagent_stop").execute("id", { id: "r1" });
    expect(result.isError).toBe(true);
    expect(calls).not.toContain("stop:r1");
  });
});
