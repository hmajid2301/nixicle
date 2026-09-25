// extensions/pipelines/pipeline.ts
// Reactive pipeline engine. Pure logic — spawning/steering are injected hooks.
import { isTransientError } from "./child-helpers.ts";
import type { CompletionResult } from "./types.ts";

export type StageStatus =
  | "queued"
  | "running"
  | "waiting-gate"
  | "waiting-help"
  | "done"
  | "failed"
  | "halted";

export interface StageSpec {
  id: string;
  agent?: string; // optional for gate stages
  task: string;
  dependsOn?: string[];
  gate?: boolean;
  retries?: number; // extra attempts on transient errors (default 0)
  model?: string; // per-stage model override, e.g. "opencode-go/glm-5.3"
  thinking?: string; // per-stage thinking level
}

export interface StageState {
  id: string;
  agent?: string;
  task: string;
  dependsOn: string[];
  gate: boolean;
  gatePassed?: boolean;
  helpNote?: string; // parent guidance attached when resuming a waiting-help stage
  retries: number;
  model?: string; // per-stage model override (inherited by every attempt)
  thinking?: string;
  status: StageStatus;
  attempt: number;
  result?: string;
  error?: string;
  startedAt?: number;
  endedAt?: number;
}

export interface PipelineState {
  id: string;
  name: string;
  createdAt: number;
  status: "active" | "complete" | "failed" | "cancelled";
  creditLimit?: boolean;
  finishedAt?: number;
  stages: StageState[];
}

export type SteerKind = "result" | "failure" | "help" | "aggregate" | "gate" | "retry";

export interface PipelineHooks {
  spawn(p: PipelineState, s: StageState): void;
  notify(p: PipelineState): void;
  steer(p: PipelineState, s: StageState | undefined, kind: SteerKind, text: string): void;
  gatePrompt(p: PipelineState, s: StageState): void;
}

export function validateSpecs(specs: StageSpec[]): string | null {
  const ids = new Set<string>();
  for (const s of specs) {
    if (!s.id) return "stage missing id";
    if (ids.has(s.id)) return `duplicate stage id "${s.id}"`;
    ids.add(s.id);
    if (!s.gate && !s.agent) return `stage "${s.id}" needs an agent (or set gate: true)`;
  }
  for (const s of specs) {
    if (s.dependsOn?.includes(s.id)) return `stage "${s.id}" depends on itself`;
    for (const dep of s.dependsOn ?? []) {
      if (!ids.has(dep)) return `stage "${s.id}" depends on unknown stage "${dep}"`;
    }
  }
  const byId = new Map(specs.map((s) => [s.id, s]));
  const visiting = new Set<string>();
  const visited = new Set<string>();
  const visit = (id: string): boolean => {
    if (visited.has(id)) return false;
    if (visiting.has(id)) return true;
    visiting.add(id);
    for (const dep of byId.get(id)?.dependsOn ?? []) {
      if (visit(dep)) return true;
    }
    visiting.delete(id);
    visited.add(id);
    return false;
  };
  for (const s of specs) {
    if (visit(s.id)) return `cycle detected at stage "${s.id}"`;
  }
  return null;
}

// Pipeline-level model/thinking act as defaults for every stage; a stage that
// sets its own value wins. Pure so the tool surface stays testable.
export interface StageDefaults {
  model?: string;
  thinking?: string;
}

export function applyStageDefaults(specs: StageSpec[], defaults: StageDefaults): StageSpec[] {
  return specs.map((s) => {
    const model = s.model ?? defaults.model;
    const thinking = s.thinking ?? defaults.thinking;
    return {
      ...s,
      ...(model ? { model } : {}),
      ...(thinking ? { thinking } : {}),
    };
  });
}

export function substituteTask(task: string, stages: StageState[], deps: string[]): string {
  return task.replace(/\{(?:previous|stage:([a-zA-Z0-9_-]+))\}/g, (whole, stageId?: string) => {
    if (stageId) {
      const s = stages.find((x) => x.id === stageId);
      return s?.status === "done" && s.result !== undefined ? s.result : whole;
    }
    const done = stages
      .filter((x) => deps.includes(x.id) && x.status === "done" && x.result !== undefined)
      .sort((a, b) => (b.endedAt ?? 0) - (a.endedAt ?? 0));
    return done[0]?.result ?? whole;
  });
}

function clip(text: string, n: number): string {
  return text.length > n ? `${text.slice(0, n)}…` : text;
}

export function aggregateText(p: PipelineState): string {
  const lines = p.stages.map((s) => {
    if (s.status === "done") return `✓ ${s.id}: ${clip(s.result ?? "", 120)}`;
    if (s.status === "failed") return `✗ ${s.id}: ${clip(s.error ?? "failed", 120)}`;
    if (s.status === "halted") return `⊘ ${s.id}: halted`;
    if (s.status === "waiting-gate") return `◆ ${s.id}: waiting for gate`;
    if (s.status === "waiting-help") return `? ${s.id}: waiting for help`;
    if (s.status === "running") return `● ${s.id}: running`;
    return `○ ${s.id}: queued`;
  });
  return `Pipeline "${p.name}" ${p.status}.\n${lines.join("\n")}`;
}

function resultText(s: StageState): string {
  return `Stage "${s.id}" (${s.agent ?? "gate"}) done:\n${s.result ?? ""}`;
}

function failText(s: StageState): string {
  return `Stage "${s.id}" (${s.agent ?? "gate"}) FAILED: ${s.error ?? "unknown error"}`;
}

function pingText(result: CompletionResult, s: StageState): string {
  return `Stage "${s.id}" (${s.agent ?? "gate"}) needs help: ${result.ping?.message ?? ""}`;
}

// Header for the guidance block prepended to a stage task on resume. Kept as
// a module const so repeated resumes can detect and strip a prior block
// instead of accumulating notes/headers across attempts.
const GUIDANCE_HEADER = "Guidance from the parent (act on it, then finish the original task):";

// Gate decision context: the results of every completed dependency, so the
// deciding user sees what they're gating on.
function gateText(p: PipelineState, s: StageState): string {
  const upstream = s.dependsOn
    .map((d) => p.stages.find((x) => x.id === d))
    .filter((x): x is StageState => x?.status === "done")
    .map((x) => `${x.id}: ${x.result ?? ""}`);
  return `Gate "${s.id}" reached. Review the upstream results and decide whether to proceed:\n${upstream.join("\n\n")}`;
}

export class PipelineEngine {
  private pipelines = new Map<string, PipelineState>();
  private hooks: PipelineHooks;

  constructor(hooks: PipelineHooks) {
    this.hooks = hooks;
  }

  create(id: string, name: string, specs: StageSpec[]): PipelineState {
    const err = validateSpecs(specs);
    if (err) throw new Error(err);
    const p: PipelineState = {
      id,
      name,
      createdAt: Date.now(),
      status: "active",
      stages: specs.map((s) => ({
        id: s.id,
        agent: s.agent,
        task: s.task,
        dependsOn: [...(s.dependsOn ?? [])],
        gate: s.gate ?? false,
        retries: s.retries ?? 0,
        model: s.model,
        thinking: s.thinking,
        status: "queued",
        attempt: 0,
      })),
    };
    this.pipelines.set(id, p);
    return p;
  }

  get(id: string): PipelineState | undefined {
    return this.pipelines.get(id);
  }

  list(): PipelineState[] {
    return [...this.pipelines.values()];
  }

  start(id: string): void {
    this.schedule(id);
  }

  private depsDone(p: PipelineState, s: StageState): boolean {
    return s.dependsOn.every((d) => p.stages.find((x) => x.id === d)?.status === "done");
  }

  private schedule(id: string): void {
    const p = this.get(id);
    if (!p || p.status !== "active") return;
    // Credit-limit gate: once a stage reports a billing error, stop spawning
    // any further work. The human can break the glass via proceedStage (clears
    // the flag) or cancel.
    if (p.creditLimit) return;
    // A gate can pass mid-pass (queued → done), unblocking stages listed
    // earlier in the array — so iterate to fixpoint rather than one pass.
    let anyChanged = false;
    let passChanged = true;
    while (passChanged) {
      passChanged = false;
      for (const s of p.stages) {
        if (s.status !== "queued") continue;
        if (!this.depsDone(p, s)) continue;
        if (s.gate && !s.gatePassed) {
          s.status = "waiting-gate";
          this.hooks.steer(p, s, "gate", gateText(p, s));
          this.hooks.gatePrompt(p, s);
          passChanged = true;
          continue;
        }
        if (s.gate && s.gatePassed) {
          // Gates are user decision points: nothing to run. Record the pass,
          // notify, and let dependents schedule below.
          s.status = "done";
          s.result = s.result ?? "(gate passed)";
          s.endedAt = Date.now();
          this.hooks.steer(p, s, "result", `Gate "${s.id}" passed; pipeline continues.`);
          this.settle(p);
          passChanged = true;
          continue;
        }
        s.status = "running";
        s.attempt += 1;
        s.startedAt = Date.now();
        s.endedAt = undefined;
        s.task = substituteTask(s.task, p.stages, s.dependsOn);
        if (s.attempt > 1 && s.helpNote) {
          // Replace (not accumulate) any prior guidance block: strip it, then
          // prepend the fresh one. split/pop keeps the text after the last
          // separator — the original task — even if a note contained one.
          if (s.task.startsWith(GUIDANCE_HEADER)) {
            s.task = s.task.split("\n\n---\n\n").pop() ?? s.task;
          }
          s.task = `${GUIDANCE_HEADER}\n${s.helpNote}\n\n---\n\n${s.task}`;
        }
        this.hooks.spawn(p, s);
        passChanged = true;
      }
      if (passChanged) anyChanged = true;
    }
    if (anyChanged) this.hooks.notify(p);
  }

  complete(id: string, stageId: string, result: CompletionResult): void {
    const p = this.get(id);
    const s = p?.stages.find((x) => x.id === stageId);
    if (!p || !s || s.status !== "running") return;
    s.endedAt = Date.now();
    if (result.reason === "ping") {
      s.status = "waiting-help";
      this.hooks.steer(p, s, "help", pingText(result, s));
      this.hooks.notify(p);
      return;
    }
    if (result.reason === "error") {
      // Transient failure with retries left: re-queue instead of failing, so
      // schedule() re-runs it. Credit-limit errors are never retried.
      if (
        !result.isCreditLimit &&
        isTransientError(result.errorMessage ?? "") &&
        s.attempt <= s.retries
      ) {
        s.status = "queued";
        s.error = undefined;
        this.hooks.steer(p, s, "retry", `Stage "${s.id}" hit a transient error; retrying (attempt ${s.attempt + 1}).`);
        this.schedule(id);
        this.hooks.notify(p);
        return;
      }
      s.status = "failed";
      s.error = result.errorMessage ?? "stage failed";
      this.haltDependents(p);
      if (result.isCreditLimit) {
        p.creditLimit = true;
        this.hooks.steer(
          p,
          s,
          "failure",
          `CREDIT LIMIT: ${s.error}. Pipeline stopped; no further stages will spawn. ` +
            `Cancel it (pipeline_cancel) or, if you've topped up, proceed past it (pipeline_proceed).`,
        );
      } else {
        this.hooks.steer(p, s, "failure", failText(s));
      }
    } else {
      s.status = "done";
      s.result = result.output ?? "";
      this.hooks.steer(p, s, "result", resultText(s));
    }
    this.settle(p);
    this.schedule(id);
    this.hooks.notify(p);
  }

  private haltDependents(p: PipelineState): void {
    const bad = new Set(
      p.stages.filter((x) => x.status === "failed" || x.status === "halted").map((x) => x.id),
    );
    let changed = true;
    while (changed) {
      changed = false;
      for (const s of p.stages) {
        if (s.status !== "queued") continue;
        if (s.dependsOn.some((d) => bad.has(d))) {
          s.status = "halted";
          bad.add(s.id);
          changed = true;
        }
      }
    }
  }

  private settle(p: PipelineState): void {
    const settled = (s: StageState) =>
      s.status === "done" || s.status === "failed" || s.status === "halted";
    if (!p.stages.every(settled)) return;
    p.status = p.stages.every((s) => s.status === "done") ? "complete" : "failed";
    p.finishedAt = Date.now();
    this.hooks.steer(p, undefined, "aggregate", aggregateText(p));
  }

  proceedGate(id: string, stageId: string): void {
    const p = this.get(id);
    const s = p?.stages.find((x) => x.id === stageId);
    if (!p || !s || s.status !== "waiting-gate") return;
    s.gatePassed = true;
    s.status = "queued";
    this.schedule(id);
    this.hooks.notify(p);
  }

  resumeHelped(id: string, stageId: string, helpNote?: string): void {
    const p = this.get(id);
    const s = p?.stages.find((x) => x.id === stageId);
    if (!p || !s || s.status !== "waiting-help") return;
    if (helpNote) s.helpNote = helpNote;
    s.status = "queued";
    this.schedule(id);
    this.hooks.notify(p);
  }

  resumeRunning(id: string, stageId: string, helpNote?: string): void {
    const p = this.get(id);
    const s = p?.stages.find((x) => x.id === stageId);
    if (!p || !s || s.status !== "running") return;
    if (helpNote) s.helpNote = helpNote;
    s.status = "queued";
    s.endedAt = undefined;
    this.schedule(id);
    this.hooks.notify(p);
  }

  failStage(id: string, stageId: string, reason: string): void {
    const p = this.get(id);
    const s = p?.stages.find((x) => x.id === stageId);
    if (!p || !s) return;
    if (s.status !== "running" && s.status !== "queued" && s.status !== "waiting-help") return;
    s.status = "failed";
    s.error = reason;
    s.endedAt = Date.now();
    this.haltDependents(p);
    this.hooks.steer(p, s, "failure", failText(s));
    this.settle(p);
    this.schedule(id);
    this.hooks.notify(p);
  }

  proceedStage(id: string, stageId: string): void {
    const p = this.get(id);
    const s = p?.stages.find((x) => x.id === stageId);
    if (!p || !s) return;
    if (s.status === "waiting-gate") {
      // Human gives the go-ahead: approve the gate; schedule() records the pass.
      s.gatePassed = true;
      s.status = "queued";
      this.hooks.steer(p, s, "result", `Gate "${s.id}" approved via proceed; pipeline continues.`);
      this.schedule(id);
      this.hooks.notify(p);
      return;
    }
    if (s.status === "waiting-help") {
      // Human skips the stage: mark it done and continue.
      s.status = "done";
      s.result = s.result ?? "(proceeded past waiting-help)";
      s.endedAt = Date.now();
      this.hooks.steer(p, s, "result", `Stage "${s.id}" proceeded past waiting-help; pipeline continues.`);
      this.settle(p);
      this.schedule(id);
      this.hooks.notify(p);
      return;
    }
    if (s.status !== "failed" && s.status !== "halted") return;
    const wasFailed = s.status === "failed";
    s.status = "done";
    s.result = s.result ?? `(proceeded past ${wasFailed ? "failure" : "halt"})`;
    s.endedAt = Date.now();
    // Break-glass: proceeding past a credit-limit failure reopens the gate so
    // the pipeline can spawn again (e.g. after the human topped up credits).
    p.creditLimit = false;
    // Un-halt dependents whose dependencies are now all done, so the pipeline
    // can continue past a manually-proceeded stage.
    for (const dep of p.stages) {
      if (dep.status === "halted" && this.depsDone(p, dep)) dep.status = "queued";
    }
    // A proceeded stage may leave queued/running work ahead; reopen the
    // pipeline so schedule() can drive it (failStage had settled it as failed).
    if (p.stages.some((x) => x.status === "queued" || x.status === "running")) {
      p.status = "active";
    }
    this.hooks.steer(p, s, "result", `Stage "${s.id}" proceeded past ${wasFailed ? "failure" : "halt"}; pipeline continues.`);
    this.settle(p);
    this.schedule(id);
    this.hooks.notify(p);
  }

  cancel(id: string, reason = "cancelled by supervisor"): void {
    const p = this.get(id);
    if (!p || p.status !== "active") return;
    const now = Date.now();
    for (const s of p.stages) {
      if (s.status === "done" || s.status === "failed" || s.status === "halted") continue;
      if (s.status === "running") s.endedAt = now;
      s.status = "halted";
      s.error = s.error ?? reason;
    }
    p.status = "cancelled";
    p.finishedAt = Date.now();
    this.hooks.steer(p, undefined, "aggregate", aggregateText(p));
    this.hooks.notify(p);
  }
}