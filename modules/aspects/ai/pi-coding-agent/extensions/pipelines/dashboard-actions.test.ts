import { describe, expect, test } from "bun:test";
import { PipelineEngine } from "./pipeline.ts";
import { applyDashboardAction } from "./dashboard-actions.ts";

function fixture() {
  const spawned: string[] = [];
  const stopped: string[] = [];
  const engine = new PipelineEngine({
    spawn: (_p, s) => { spawned.push(s.id); },
    notify() {}, steer() {}, gatePrompt() {},
  });
  engine.create("pl", "Build", [
    { id: "gate", gate: true, task: "Approve?" },
    { id: "work", agent: "worker", task: "Build", dependsOn: ["gate"] },
  ]);
  engine.start("pl");
  const dispatch = (action: string, pipelineId = "pl", stageId?: string, snapshot?: { status: string; attempt: number }) => {
    const stage = engine.get(pipelineId)?.stages.find((candidate) => candidate.id === stageId);
    return applyDashboardAction(engine, {
      cancelPipeline: (id) => { stopped.push(id); engine.cancel(id); },
      stopStage: (p, s) => { stopped.push(`${p}:${s}`); },
    }, action, pipelineId, stageId, snapshot ?? (stage ? { status: stage.status, attempt: stage.attempt } : undefined));
  };
  return { engine, dispatch, spawned, stopped };
}

describe("dashboard actions", () => {
  test("approves a waiting gate and schedules its dependent exactly once", () => {
    const { engine, dispatch, spawned } = fixture();
    dispatch("resume", "pl", "gate");
    dispatch("resume", "pl", "gate");
    expect(engine.get("pl")?.stages[0].status).toBe("done");
    expect(spawned).toEqual(["work"]);
  });

  test("resumes a help request rather than skipping the stage", () => {
    const { engine, dispatch, spawned } = fixture();
    dispatch("resume", "pl", "gate");
    engine.complete("pl", "work", { reason: "ping", ping: { name: "worker", message: "Help" } });
    dispatch("resume", "pl", "work");
    expect(engine.get("pl")?.stages[1].status).toBe("running");
    expect(spawned).toEqual(["work", "work"]);
  });

  test("stops a help run before credit-gated resume queues the stage", () => {
    const { engine, dispatch, spawned, stopped } = fixture();
    dispatch("resume", "pl", "gate");
    engine.complete("pl", "work", { reason: "ping", ping: { name: "worker", message: "Help" } });
    engine.get("pl")!.creditLimit = true;
    dispatch("resume", "pl", "work");
    expect(stopped).toEqual(["pl:work"]);
    expect(engine.get("pl")?.stages[1].status).toBe("queued");
    expect(spawned).toEqual(["work"]);
  });

  test("does not reuse an old help control for a later attempt", () => {
    const { engine, dispatch, spawned, stopped } = fixture();
    dispatch("resume", "pl", "gate");
    engine.complete("pl", "work", { reason: "ping", ping: { name: "worker", message: "First question" } });
    const old = { status: "waiting-help", attempt: engine.get("pl")!.stages[1].attempt };
    dispatch("resume", "pl", "work", old);
    stopped.length = 0;
    engine.complete("pl", "work", { reason: "ping", ping: { name: "worker", message: "New question" } });
    dispatch("resume", "pl", "work", old);
    dispatch("cancel-stage", "pl", "work", old);
    expect(engine.get("pl")?.stages[1].status).toBe("waiting-help");
    expect(spawned).toEqual(["work", "work"]);
    expect(stopped).toEqual([]);
  });

  test("cancels a live stage before failing it", () => {
    const { engine, dispatch, stopped } = fixture();
    dispatch("resume", "pl", "gate");
    dispatch("cancel-stage", "pl", "work");
    expect(stopped).toEqual(["pl:work"]);
    expect(engine.get("pl")?.stages[1].status).toBe("failed");
  });

  test("rejects unknown actions and cannot resume or cancel a gate as a live stage", () => {
    const { engine, dispatch, spawned, stopped } = fixture();
    dispatch("unknown", "pl", "gate");
    dispatch("cancel-stage", "pl", "gate");
    dispatch("resume", "missing", "gate");
    dispatch("resume", "pl", "missing");
    expect(engine.get("pl")?.stages[0].status).toBe("waiting-gate");
    expect(spawned).toEqual([]);
    expect(stopped).toEqual([]);
  });

  test("cannot resume an already running stage", () => {
    const { dispatch, spawned } = fixture();
    dispatch("resume", "pl", "gate");
    dispatch("resume", "pl", "work");
    expect(spawned).toEqual(["work"]);
  });

  test("does not force-proceed failures or accept stale stage actions", () => {
    const { engine, dispatch, spawned, stopped } = fixture();
    dispatch("resume", "pl", "gate");
    engine.failStage("pl", "work", "broken");
    dispatch("resume", "pl", "work");
    dispatch("cancel-stage", "pl", "gate");
    dispatch("cancel-stage", "missing", "work");
    dispatch("unknown", "pl", "work");
    expect(engine.get("pl")?.stages[1].status).toBe("failed");
    expect(spawned).toEqual(["work"]);
    expect(stopped).toEqual([]);
  });

  test("cancels an active pipeline but ignores duplicate cancellation", () => {
    const { engine, dispatch, stopped } = fixture();
    dispatch("cancel-pipeline");
    dispatch("cancel-pipeline");
    expect(engine.get("pl")?.status).toBe("cancelled");
    expect(stopped).toEqual(["pl"]);
  });
});
