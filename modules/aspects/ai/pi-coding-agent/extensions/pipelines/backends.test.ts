import { describe, expect, test } from "bun:test";
import { buildResumedSpawn } from "./backends.ts";
import { PipelineEngine, type PipelineHooks } from "./pipeline.ts";
import type { CompletionResult, RunHandle } from "./types.ts";

function done(output = "ok"): CompletionResult {
  return { reason: "done", exitCode: 0, output };
}

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
