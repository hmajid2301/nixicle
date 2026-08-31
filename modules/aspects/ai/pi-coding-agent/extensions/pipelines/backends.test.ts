import { describe, expect, test, mock } from "bun:test";
import { buildOpts, buildResumedSpawn, register } from "./backends.ts";
import { PipelineEngine, type PipelineHooks } from "./pipeline.ts";
import type { CompletionResult, RunHandle } from "./types.ts";

const paneCloseMock = mock(() => {});
mock.module("./herdr.ts", () => ({
  paneClose: paneCloseMock,
}));

function done(output = "ok"): CompletionResult {
  return { reason: "done", exitCode: 0, output };
}

describe("buildOpts", () => {
  test("carries timeoutMs and onTimeout into the launch opts", () => {
    const onTimeout = () => {};
    const req = {
      id: "r1",
      name: "n",
      task: "t",
      cwd: process.cwd(),
      harness: "pi" as const,
      autoExit: true,
      timeoutMs: 30_000,
      onTimeout,
    };
    const o = buildOpts(req, "headless");
    expect(o.timeoutMs).toBe(30_000);
    expect(o.onTimeout).toBe(onTimeout);
  });
});

describe("register", () => {
  test("closes the pane on done and keeps it open on ping", async () => {
    paneCloseMock.mockClear();
    const doneHandle: RunHandle = {
      id: "r-done", name: "n", backend: "pane", paneId: "p1", startedAt: Date.now(),
      completion: Promise.resolve({ reason: "done", exitCode: 0 }),
      async interrupt() {},
    };
    const req = { id: "r-done", name: "n", task: "t", cwd: process.cwd(), harness: "pi" as const, autoExit: true };
    register(req, doneHandle, doneHandle.completion);
    await doneHandle.completion;
    await new Promise((r) => setTimeout(r, 10));
    expect(paneCloseMock).toHaveBeenCalledWith("p1");

    paneCloseMock.mockClear();
    const pingHandle: RunHandle = {
      id: "r-ping", name: "n", backend: "pane", paneId: "p2", startedAt: Date.now(),
      completion: Promise.resolve({ reason: "ping", exitCode: 0, ping: { name: "n", message: "help" } }),
      async interrupt() {},
    };
    const req2 = { id: "r-ping", name: "n", task: "t", cwd: process.cwd(), harness: "pi" as const, autoExit: true };
    register(req2, pingHandle, pingHandle.completion);
    await pingHandle.completion;
    await new Promise((r) => setTimeout(r, 10));
    expect(paneCloseMock).not.toHaveBeenCalled();
  });
});

describe("buildResumedSpawn", () => {
  test("keeps the original completion linkage so a resumed pipeline stage can complete", () => {
    const hooks: PipelineHooks = {
      spawn() {},
      notify() {},
      steer() {},
      gatePrompt() {},
    };
    const engine = new PipelineEngine(hooks);
    engine.create("p1", "demo", [{ id: "decider", agent: "worker", task: "Decide" }]);
    engine.start("p1");

    const req = {
      id: "pl-demo-decider-1",
      name: "decider",
      task: "Decide",
      cwd: process.cwd(),
      harness: "pi" as const,
      autoExit: true,
      sessionPath: "/tmp/pi-pipelines-test/sessions/pl-demo-decider-1.jsonl",
      watcher(_handle: RunHandle, result: CompletionResult) {
        engine.complete("p1", "decider", result);
      },
    };

    const resumed = buildResumedSpawn(req, "continue", "pl-demo-decider-1-rresume-1");
    expect(resumed.id).toBe("pl-demo-decider-1-rresume-1");
    expect(resumed.sessionPath).toBe(req.sessionPath);
    expect(resumed.watcher).toBe(req.watcher);

    resumed.watcher?.({ id: resumed.id } as RunHandle, done("finished after resume"));
    const stage = engine.get("p1")!.stages[0]!;
    expect(stage.status).toBe("done");
    expect(stage.result).toBe("finished after resume");
    expect(engine.get("p1")!.status).toBe("complete");
  });
});
