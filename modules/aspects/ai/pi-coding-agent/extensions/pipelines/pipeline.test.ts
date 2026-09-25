// extensions/pipelines/pipeline.test.ts
import { describe, expect, test } from "bun:test";
import {
  PipelineEngine,
  aggregateText,
  applyStageDefaults,
  substituteTask,
  validateSpecs,
  type PipelineHooks,
  type StageState,
  type PipelineState,
} from "./pipeline.ts";
import type { CompletionResult } from "./types.ts";

interface Log {
  spawned: string[]; // stage ids in spawn order
  steers: { kind: string; text: string; stage?: string }[];
  gates: string[]; // stage ids that prompted
  notifies: number;
}

function makeEngine() {
  const log: Log = { spawned: [], steers: [], gates: [], notifies: 0 };
  const hooks: PipelineHooks = {
    spawn(_p, s) { log.spawned.push(s.id); },
    notify() { log.notifies++; },
    steer(_p, s, kind, text) { log.steers.push({ kind, text, stage: s?.id }); },
    gatePrompt(_p, s) { log.gates.push(s.id); },
  };
  return { engine: new PipelineEngine(hooks), log };
}

const done = (id: string, output = ""): CompletionResult => ({ reason: "done", exitCode: 0, output });

describe("create", () => {
  test("carries per-stage model and thinking into stage state", () => {
    const { engine } = makeEngine();
    const p = engine.create("p1", "demo", [
      { id: "a", agent: "scout", task: "look", model: "opencode-go/glm-5.3", thinking: "high" },
      { id: "b", agent: "worker", task: "build" },
    ]);
    expect(p.stages[0]?.model).toBe("opencode-go/glm-5.3");
    expect(p.stages[0]?.thinking).toBe("high");
    expect(p.stages[1]?.model).toBeUndefined();
    expect(p.stages[1]?.thinking).toBeUndefined();
  });
});

describe("validateSpecs", () => {
  test("accepts valid graph", () => {
    expect(validateSpecs([
      { id: "a", agent: "planner", task: "t" },
      { id: "b", agent: "worker", task: "t", dependsOn: ["a"] },
    ])).toBeNull();
  });
  test("rejects duplicate ids", () => {
    expect(validateSpecs([{ id: "a", agent: "x", task: "t" }, { id: "a", agent: "x", task: "t" }])).toContain("duplicate");
  });
  test("rejects unknown dependency", () => {
    expect(validateSpecs([{ id: "a", agent: "x", task: "t", dependsOn: ["nope"] }])).toContain("unknown");
  });
  test("rejects cycles", () => {
    expect(validateSpecs([
      { id: "a", agent: "x", task: "t", dependsOn: ["b"] },
      { id: "b", agent: "x", task: "t", dependsOn: ["a"] },
    ])).toContain("cycle");
  });
  test("rejects stage without agent (unless gate)", () => {
    expect(validateSpecs([{ id: "a", task: "t" }])).toContain("agent");
    expect(validateSpecs([{ id: "a", task: "t", gate: true }])).toBeNull();
  });
  test("rejects self-dependency", () => {
    expect(validateSpecs([{ id: "a", agent: "x", task: "t", dependsOn: ["a"] }])).toContain("itself");
  });
});

describe("applyStageDefaults", () => {
  test("pipeline-level model/thinking apply to every stage", () => {
    const out = applyStageDefaults(
      [
        { id: "a", agent: "scout", task: "t" },
        { id: "b", agent: "worker", task: "t" },
      ],
      { model: "opencode-go/glm-5.3", thinking: "high" },
    );
    expect(out.map((s) => s.model)).toEqual(["opencode-go/glm-5.3", "opencode-go/glm-5.3"]);
    expect(out.map((s) => s.thinking)).toEqual(["high", "high"]);
  });

  test("a stage override wins over the pipeline default", () => {
    const out = applyStageDefaults(
      [{ id: "a", agent: "scout", task: "t", model: "openai-codex/gpt-5.4", thinking: "low" }],
      { model: "opencode-go/glm-5.3", thinking: "high" },
    );
    expect(out[0]?.model).toBe("openai-codex/gpt-5.4");
    expect(out[0]?.thinking).toBe("low");
  });

  test("no defaults leaves specs untouched", () => {
    const specs = [{ id: "a", agent: "scout", task: "t" }];
    expect(applyStageDefaults(specs, {})).toEqual(specs);
  });
});

describe("substituteTask", () => {
  const stages: StageState[] = [
    { id: "plan", agent: "x", task: "orig", dependsOn: [], gate: false, status: "done", attempt: 1, result: "THE PLAN", startedAt: 1, endedAt: 10 },
    { id: "impl", agent: "x", task: "orig", dependsOn: ["plan"], gate: false, status: "done", attempt: 1, result: "THE IMPL", startedAt: 11, endedAt: 20 },
    { id: "test", agent: "x", task: "orig", dependsOn: ["impl"], gate: false, status: "queued", attempt: 0 },
  ];
  test("{stage:id} substitutes completed stage", () => {
    expect(substituteTask("use {stage:plan} now", stages, [])).toBe("use THE PLAN now");
  });
  test("unknown/not-done stage left literal", () => {
    expect(substituteTask("use {stage:missing}", stages, [])).toBe("use {stage:missing}");
    expect(substituteTask("use {stage:test}", stages, [])).toBe("use {stage:test}");
  });
  test("{previous} = last-completed dependency", () => {
    expect(substituteTask("after: {previous}", stages, ["plan"])).toBe("after: THE PLAN");
    expect(substituteTask("after: {previous}", stages, ["plan", "impl"])).toBe("after: THE IMPL");
  });
  test("{previous} with no completed deps stays literal", () => {
    expect(substituteTask("{previous}", stages, [])).toBe("{previous}");
  });
});

describe("PipelineEngine", () => {
  test("sequential scheduling, substitution, results, aggregate", () => {
    const { engine, log } = makeEngine();
    engine.create("p1", "demo", [
      { id: "plan", agent: "planner", task: "plan {goal}" },
      { id: "impl", agent: "worker", task: "do it based on {previous}", dependsOn: ["plan"] },
    ]);
    engine.start("p1");
    expect(log.spawned).toEqual(["plan"]); // impl waits
    engine.complete("p1", "plan", done("plan", "THE PLAN"));
    expect(log.spawned).toEqual(["plan", "impl"]);
    const implStage = engine.get("p1")!.stages.find((s) => s.id === "impl")!;
    expect(implStage.task).toBe("do it based on THE PLAN");
    engine.complete("p1", "impl", done("impl", "THE IMPL"));
    const p = engine.get("p1")!;
    expect(p.status).toBe("complete");
    const agg = log.steers.find((s) => s.kind === "aggregate")!;
    expect(agg.text).toContain("✓ plan: THE PLAN");
    expect(agg.text).toContain("✓ impl: THE IMPL");
  });

  test("parallel branches both spawn before fan-in", () => {
    const { engine, log } = makeEngine();
    engine.create("p2", "fan", [
      { id: "a", agent: "worker", task: "A" },
      { id: "b", agent: "worker", task: "B" },
      { id: "c", agent: "worker", task: "C {stage:a} {stage:b}", dependsOn: ["a", "b"] },
    ]);
    engine.start("p2");
    expect(log.spawned).toEqual(["a", "b"]);
    engine.complete("p2", "a", done("a", "RA"));
    expect(log.spawned).toEqual(["a", "b"]); // c waits for b
    engine.complete("p2", "b", done("b", "RB"));
    expect(log.spawned).toEqual(["a", "b", "c"]);
    const c = engine.get("p2")!.stages.find((s) => s.id === "c")!;
    expect(c.task).toBe("C RA RB");
  });

  test("failure halts dependents; independent branch finishes; pipeline failed", () => {
    const { engine, log } = makeEngine();
    engine.create("p3", "fail", [
      { id: "a", agent: "worker", task: "A" },
      { id: "bad", agent: "worker", task: "B", dependsOn: ["a"] },
      { id: "dep", agent: "worker", task: "C", dependsOn: ["bad"] },
      { id: "indep", agent: "worker", task: "D" },
    ]);
    engine.start("p3");
    expect(log.spawned).toEqual(["a", "indep"]); // bad waits for a
    engine.complete("p3", "a", done("a", "RA"));
    expect(log.spawned).toEqual(["a", "indep", "bad"]); // bad now runs
    engine.complete("p3", "bad", { reason: "error", exitCode: 1, errorMessage: "boom" });
    expect(engine.get("p3")!.stages.find((s) => s.id === "dep")!.status).toBe("halted");
    const failSteer = log.steers.find((s) => s.kind === "failure")!;
    expect(failSteer.text).toContain("boom");
    engine.complete("p3", "indep", done("indep", "RD"));
    expect(engine.get("p3")!.status).toBe("failed");
    const agg = log.steers.find((s) => s.kind === "aggregate")!;
    expect(agg.text).toContain("✗ bad: boom");
    expect(agg.text).toContain("⊘ dep");
    expect(agg.text).toContain("✓ indep: RD");
  });

  test("gate flow: waiting-gate → proceedGate → gate records pass, dependents spawn", () => {
    const { engine, log } = makeEngine();
    engine.create("p4", "gated", [
      { id: "plan", agent: "planner", task: "P" },
      { id: "confirm", gate: true, task: "confirm with user", dependsOn: ["plan"] },
      { id: "build", agent: "worker", task: "B", dependsOn: ["confirm"] },
    ]);
    engine.start("p4");
    expect(log.spawned).toEqual(["plan"]);
    engine.complete("p4", "plan", done("plan", "PLAN"));
    expect(log.gates).toEqual(["confirm"]);
    expect(engine.get("p4")!.stages.find((s) => s.id === "confirm")!.status).toBe("waiting-gate");
    const gateSteer = log.steers.find((s) => s.kind === "gate");
    expect(gateSteer?.text).toContain("PLAN");
    engine.proceedGate("p4", "confirm");
    // gate stages never spawn children — they complete by decision
    expect(log.spawned).toEqual(["plan", "build"]);
    const confirm = engine.get("p4")!.stages.find((s) => s.id === "confirm")!;
    expect(confirm.status).toBe("done");
    expect(confirm.result).toContain("gate passed");
    engine.complete("p4", "build", done("build", "RB"));
    expect(engine.get("p4")!.status).toBe("complete");
  });

  test("dependent listed before its gate dep is unblocked when the gate passes (fixpoint)", () => {
    const { engine, log } = makeEngine();
    engine.create("p7", "reorder", [
      { id: "build", agent: "worker", task: "B", dependsOn: ["confirm"] },
      { id: "confirm", gate: true, task: "t" },
    ]);
    engine.start("p7");
    // build is listed before confirm, so the first pass skips it; the gate prompts
    expect(log.gates).toEqual(["confirm"]);
    expect(log.spawned).toEqual([]);
    engine.proceedGate("p7", "confirm");
    // fixpoint re-examines build once the gate is done mid-schedule
    const build = engine.get("p7")!.stages.find((s) => s.id === "build")!;
    expect(build.status).toBe("running");
    expect(log.spawned).toEqual(["build"]);
    engine.complete("p7", "build", done("build", "RB"));
    expect(engine.get("p7")!.status).toBe("complete");
  });

  test("gate chain: dependent gate listed before its gate dep reaches waiting-gate", () => {
    const { engine, log } = makeEngine();
    engine.create("p8", "gatechain", [
      { id: "g2", gate: true, task: "t", dependsOn: ["g1"] },
      { id: "g1", gate: true, task: "t" },
    ]);
    engine.start("p8");
    expect(log.gates).toEqual(["g1"]); // g2 listed first but not stuck-queued forever
    expect(engine.get("p8")!.stages.find((s) => s.id === "g2")!.status).toBe("queued");
    engine.proceedGate("p8", "g1");
    const g2 = engine.get("p8")!.stages.find((s) => s.id === "g2")!;
    expect(g2.status).toBe("waiting-gate");
    expect(log.gates).toEqual(["g1", "g2"]);
  });

  test("repeated resumeHelped replaces prior guidance instead of accumulating", () => {
    const { engine } = makeEngine();
    engine.create("p9", "rehelp", [{ id: "w", agent: "worker", task: "W" }]);
    engine.start("p9");
    engine.complete("p9", "w", { reason: "ping", exitCode: 0, ping: { name: "w", message: "stuck" } });
    engine.resumeHelped("p9", "w", "note-ONE");
    engine.complete("p9", "w", { reason: "ping", exitCode: 0, ping: { name: "w", message: "stuck again" } });
    engine.resumeHelped("p9", "w", "note-TWO");
    const s = engine.get("p9")!.stages[0];
    expect(s.attempt).toBe(3);
    expect(s.task).toContain("note-TWO");
    expect(s.task).not.toContain("note-ONE");
    expect(s.task).toContain("W");
  });

  test("ping → waiting-help → resumeHelped respawns with guidance prepended", () => {
    const { engine, log } = makeEngine();
    engine.create("p5", "help", [{ id: "w", agent: "worker", task: "W" }]);
    engine.start("p5");
    expect(engine.get("p5")!.stages[0].attempt).toBe(1);
    engine.complete("p5", "w", { reason: "ping", exitCode: 0, ping: { name: "w", message: "stuck" } });
    expect(engine.get("p5")!.stages[0].status).toBe("waiting-help");
    expect(log.steers.find((s) => s.kind === "help")?.text).toContain("stuck");
    engine.resumeHelped("p5", "w", "use nix develop first");
    const s = engine.get("p5")!.stages[0];
    expect(s.attempt).toBe(2);
    expect(s.status).toBe("running");
    expect(s.task).toContain("use nix develop first");
    expect(s.task).toContain("W");
    engine.complete("p5", "w", done("w", "RESUMED"));
    expect(engine.get("p5")!.status).toBe("complete");
  });

  test("orphaned running stage can be relaunched via resumeRunning", () => {
    const { engine, log } = makeEngine();
    engine.create("p10", "orphan", [{ id: "decider", agent: "worker", task: "Decide" }]);
    engine.start("p10");
    const first = engine.get("p10")!.stages[0]!;
    expect(first.status).toBe("running");
    expect(first.attempt).toBe(1);
    expect(log.spawned).toEqual(["decider"]);

    engine.resumeRunning("p10", "decider", "please continue after the interruption");

    const resumed = engine.get("p10")!.stages[0]!;
    expect(resumed.status).toBe("running");
    expect(resumed.attempt).toBe(2);
    expect(resumed.task).toContain("please continue after the interruption");
    expect(resumed.task).toContain("Decide");
    expect(log.spawned).toEqual(["decider", "decider"]);

    engine.complete("p10", "decider", done("decider", "done now"));
    expect(engine.get("p10")!.status).toBe("complete");
  });

  test("create throws on invalid specs", () => {
    const { engine } = makeEngine();
    expect(() => engine.create("p6", "bad", [{ id: "a", task: "t", dependsOn: ["ghost"] }])).toThrow();
  });

  test("complete on unknown pipeline/stage is a no-op", () => {
    const { engine } = makeEngine();
    expect(() => engine.complete("ghost", "x", done("x"))).not.toThrow();
  });

  test("failStage fails a running stage and halts dependents", () => {
    const { engine } = makeEngine();
    engine.create("f1", "demo", [
      { id: "a", agent: "worker", task: "A" },
      { id: "b", agent: "worker", task: "B", dependsOn: ["a"] },
    ]);
    engine.start("f1");
    engine.failStage("f1", "a", "timed out");
    expect(engine.get("f1")!.stages[0]!.status).toBe("failed");
    expect(engine.get("f1")!.stages[0]!.error).toBe("timed out");
    expect(engine.get("f1")!.stages[1]!.status).toBe("halted");
    expect(engine.get("f1")!.status).toBe("failed");
  });

  test("proceedStage marks a failed stage done and unblocks dependents", () => {
    const { engine } = makeEngine();
    engine.create("f2", "demo", [
      { id: "a", agent: "worker", task: "A" },
      { id: "b", agent: "worker", task: "B", dependsOn: ["a"] },
    ]);
    engine.start("f2");
    engine.failStage("f2", "a", "timed out");
    engine.proceedStage("f2", "a");
    expect(engine.get("f2")!.stages[0]!.status).toBe("done");
    expect(engine.get("f2")!.stages[0]!.result).toContain("proceeded");
    expect(engine.get("f2")!.stages[1]!.status).toBe("running");
  });

  test("credit-limit error sets the gate and halts dependents (no new spawns)", () => {
    const { engine, log } = makeEngine();
    engine.create("cl1", "demo", [
      { id: "a", agent: "worker", task: "A" },
      { id: "b", agent: "worker", task: "B", dependsOn: ["a"] },
      { id: "c", agent: "worker", task: "C" },
    ]);
    engine.start("cl1");
    const spawnedBefore = log.spawned.length;
    engine.complete("cl1", "a", { reason: "error", exitCode: 1, errorMessage: "Insufficient balance", isCreditLimit: true });
    const p = engine.get("cl1")!;
    expect(p.creditLimit).toBe(true);
    expect(p.stages[0]!.status).toBe("failed");
    expect(p.stages[1]!.status).toBe("halted");
    // c is independent and already running; no NEW stage spawns after the gate.
    expect(log.spawned.length).toBe(spawnedBefore);
  });

  test("proceedStage clears the credit-limit gate (break-glass)", () => {
    const { engine, log } = makeEngine();
    engine.create("cl2", "demo", [
      { id: "a", agent: "worker", task: "A" },
      { id: "b", agent: "worker", task: "B", dependsOn: ["a"] },
    ]);
    engine.start("cl2");
    engine.complete("cl2", "a", { reason: "error", exitCode: 1, errorMessage: "Insufficient balance", isCreditLimit: true });
    const p = engine.get("cl2")!;
    expect(p.creditLimit).toBe(true);
    expect(p.stages[1]!.status).toBe("halted");
    engine.proceedStage("cl2", "a");
    expect(p.creditLimit).toBe(false);
    expect(p.stages[1]!.status).toBe("running");
  });

  test("proceedStage approves a waiting-gate stage (go-ahead)", () => {
    const { engine, log } = makeEngine();
    engine.create("g1", "demo", [
      { id: "a", agent: "worker", task: "A" },
      { id: "confirm", gate: true, task: "confirm", dependsOn: ["a"] },
      { id: "b", agent: "worker", task: "B", dependsOn: ["confirm"] },
    ]);
    engine.start("g1");
    engine.complete("g1", "a", done("a", "A"));
    const p = engine.get("g1")!;
    expect(p.stages[1]!.status).toBe("waiting-gate");
    engine.proceedStage("g1", "confirm");
    expect(p.stages[1]!.status).toBe("done");
    expect(p.stages[1]!.gatePassed).toBe(true);
    expect(p.stages[2]!.status).toBe("running");
    expect(log.spawned).toContain("b");
  });

  test("proceedStage skips a waiting-help stage", () => {
    const { engine } = makeEngine();
    engine.create("h1", "demo", [
      { id: "a", agent: "worker", task: "A" },
      { id: "b", agent: "worker", task: "B", dependsOn: ["a"] },
    ]);
    engine.start("h1");
    engine.complete("h1", "a", { reason: "ping", exitCode: 0, ping: { name: "a", message: "help" } });
    const p = engine.get("h1")!;
    expect(p.stages[0]!.status).toBe("waiting-help");
    engine.proceedStage("h1", "a");
    expect(p.stages[0]!.status).toBe("done");
    expect(p.stages[1]!.status).toBe("running");
  });

  test("transient error retries the stage up to retries count", () => {
    const { engine } = makeEngine();
    engine.create("r1", "demo", [
      { id: "a", agent: "worker", task: "A", retries: 1 },
      { id: "b", agent: "worker", task: "B", dependsOn: ["a"] },
    ]);
    engine.start("r1");
    engine.complete("r1", "a", { reason: "error", exitCode: 1, errorMessage: "overloaded, try again" });
    const p = engine.get("r1")!;
    expect(p.stages[0]!.status).toBe("running"); // retried, not failed
    expect(p.stages[0]!.attempt).toBe(2);
    expect(p.stages[1]!.status).toBe("queued"); // dependents not halted
    engine.complete("r1", "a", { reason: "error", exitCode: 1, errorMessage: "overloaded, try again" });
    expect(p.stages[0]!.status).toBe("failed"); // retries exhausted
    expect(p.stages[1]!.status).toBe("halted");
  });

  test("non-transient error does not retry", () => {
    const { engine } = makeEngine();
    engine.create("r2", "demo", [{ id: "a", agent: "worker", task: "A", retries: 2 }]);
    engine.start("r2");
    engine.complete("r2", "a", { reason: "error", exitCode: 1, errorMessage: "syntax error in task" });
    expect(engine.get("r2")!.stages[0]!.status).toBe("failed");
  });

  test("credit-limit error is never retried", () => {
    const { engine } = makeEngine();
    engine.create("r3", "demo", [{ id: "a", agent: "worker", task: "A", retries: 2 }]);
    engine.start("r3");
    engine.complete("r3", "a", { reason: "error", exitCode: 1, errorMessage: "Insufficient balance", isCreditLimit: true });
    const p = engine.get("r3")!;
    expect(p.stages[0]!.status).toBe("failed");
    expect(p.creditLimit).toBe(true);
  });

  test("aggregateText lists all stages", () => {
    const p: PipelineState = {
      id: "px", name: "n", createdAt: 0, status: "failed",
      stages: [
        { id: "ok", agent: "a", task: "t", dependsOn: [], gate: false, status: "done", attempt: 1, result: "R" },
        { id: "bad", agent: "a", task: "t", dependsOn: [], gate: false, status: "failed", attempt: 1, error: "E" },
        { id: "st", agent: "a", task: "t", dependsOn: [], gate: false, status: "halted", attempt: 0 },
        { id: "gate", task: "t", dependsOn: [], gate: true, status: "waiting-gate", attempt: 0 },
        { id: "help", agent: "a", task: "t", dependsOn: [], gate: false, status: "waiting-help", attempt: 1 },
        { id: "run", agent: "a", task: "t", dependsOn: [], gate: false, status: "running", attempt: 1 },
        { id: "queue", agent: "a", task: "t", dependsOn: [], gate: false, status: "queued", attempt: 0 },
      ],
    };
    const text = aggregateText(p);
    expect(text).toContain("✓ ok: R");
    expect(text).toContain("✗ bad: E");
    expect(text).toContain("⊘ st");
    expect(text).toContain("◆ gate: waiting for gate");
    expect(text).toContain("? help: waiting for help");
    expect(text).toContain("● run: running");
    expect(text).toContain("○ queue: queued");
  });
});