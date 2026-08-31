// extensions/pipelines/pipeline.ts
// Reactive pipeline engine. Pure logic — spawning/steering are injected hooks.
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
}

export interface StageState {
  id: string;
  agent?: string;
  task: string;
  dependsOn: string[];
  gate: boolean;
  gatePassed?: boolean;
  helpNote?: string; // parent guidance attached when resuming a waiting-help stage
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
  stages: StageState[];
}

export type SteerKind = "result" | "failure" | "help" | "aggregate" | "gate";

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
      s.status = "failed";
      s.error = result.errorMessage ?? "stage failed";
      this.haltDependents(p);
      this.hooks.steer(p, s, "failure", failText(s));
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
    this.hooks.steer(p, undefined, "aggregate", aggregateText(p));
    this.hooks.notify(p);
  }
}