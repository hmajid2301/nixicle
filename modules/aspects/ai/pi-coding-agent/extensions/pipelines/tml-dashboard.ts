import { spawn, type ChildProcessWithoutNullStreams } from "node:child_process";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { FINISHED_GRACE_MS, type WidgetModel } from "./widget-render.ts";

type Action = "resume" | "cancel-stage" | "cancel-pipeline";
interface DashboardRow {
  title: string;
  status: string;
  task: string;
  result: string;
  error: string;
  context: string;
  resume: boolean;
  cancelStage: boolean;
  cancelPipeline: boolean;
  value: { pipelineId: string; stageId?: string; status?: string; attempt?: number };
}

const patchFor = (rows: DashboardRow[]) => JSON.stringify([{ op: "replace", path: "/rows", value: rows }]);
const clip = (value = "") => value.length > 2000 ? `${value.slice(0, 1999)}…` : value;

export function buildTmlDocument(model: WidgetModel) {
  const rows: DashboardRow[] = [];
  const add = (row: DashboardRow): boolean => {
    if (rows.length >= 100) return false;
    rows.push(row);
    if (Buffer.byteLength(patchFor(rows)) > 64 * 1024) { rows.pop(); return false; }
    return true;
  };
  const empty = { task: "", result: "", error: "", context: "", resume: false, cancelStage: false, cancelPipeline: false };
  for (const p of model.pipelines) {
    if (p.status !== "active" && (p.finishedAt ?? 0) < Date.now() - FINISHED_GRACE_MS) continue;
    if (!add({ ...empty, title: clip(p.name), status: p.status, error: p.creditLimit ? "Credit limit reached" : "", cancelPipeline: p.status === "active", value: { pipelineId: p.id } })) break;
    for (const s of p.stages) {
      const upstream = s.gate ? p.stages.filter((dep) => s.dependsOn.includes(dep.id)).map((dep) => `${clip(dep.id)} (${dep.status}): ${clip(dep.result ?? dep.error ?? dep.task)}`).join("\n\n") : s.helpNote;
      if (!add({ ...empty, title: clip(s.id), status: s.status, task: clip(s.task), result: clip(s.result), error: clip(s.error), context: clip(upstream),
        resume: p.status === "active" && (s.status === "waiting-gate" || s.status === "waiting-help"),
        cancelStage: p.status === "active" && ["running", "queued", "waiting-help"].includes(s.status),
        value: { pipelineId: p.id, stageId: s.id, status: s.status, attempt: s.attempt },
      })) break;
    }
  }
  for (const { handle, stageLabel } of model.runs) {
    if (stageLabel !== undefined) continue;
    if (!add({ ...empty, title: clip(handle.name), status: "running", value: { pipelineId: "" } })) break;
  }
  return {
    type: "tml", version: 1, title: "Pipelines", state: { rows },
    children: [{ type: "scroll", h: "fill", children: [{ type: "col", pad: 1, gap: 1, children: [
      { type: "text", if: "len(state.rows) == 0", children: ["No pipelines or runs"] },
      { type: "col", each: "state.rows", as: "entry", gap: 1, children: [
        { type: "heading", children: ["{entry.title} · {entry.status}"] },
        { type: "text", if: "entry.task != ''", children: ["Task: {entry.task}"] },
        { type: "text", if: "entry.context != ''", children: ["Context: {entry.context}"] },
        { type: "text", if: "entry.result != ''", children: ["Result: {entry.result}"] },
        { type: "text", if: "entry.error != ''", children: ["Error: {entry.error}"] },
        { type: "row", gap: 1, children: [
          { type: "button", if: "entry.resume", "on-press": "emit('resume', entry.value)", children: ["Resume"] },
          { type: "button", if: "entry.cancelStage", "on-press": "emit('cancel-stage', entry.value)", children: ["Cancel stage"] },
          { type: "button", if: "entry.cancelPipeline", "on-press": "emit('cancel-pipeline', entry.value)", children: ["Cancel pipeline"] },
        ] },
      ] },
    ] }] }],
  };
}

export function registerTmlDashboard(
  pi: ExtensionAPI,
  getModel: () => WidgetModel,
  onAction: (action: Action, pipelineId: string, stageId?: string, snapshot?: { status: string; attempt: number }) => void,
): void {
  let shutdown: (() => Promise<void>) | undefined;
  let reopen: (() => void) | undefined;
  let warned = false;

  pi.registerCommand("pipeline-dashboard", {
    description: "Reopen the live pipelines dashboard",
    handler: async () => { reopen?.(); },
  });

  pi.on("session_start", (_event, ctx: ExtensionContext) => {
    if (shutdown || process.env.TUIOS_ENV !== "1" || !process.env.TUIOS_SESSION?.trim()) return;
    const session = process.env.TUIOS_SESSION.trim();
    let stopped = false;
    let suppressed = false;
    let busy = false;
    let surface: string | undefined;
    let events: ChildProcessWithoutNullStreams | undefined;
    const childClosed = new WeakMap<ChildProcessWithoutNullStreams, Promise<void>>();
    let lastRows = "";
    let pending: Promise<void> = Promise.resolve();
    let openingDeadline: ReturnType<typeof setTimeout> | undefined;
    let opened = Promise.resolve();
    let finishOpening = () => {};
    let cleaning = Promise.resolve();
    let shutdownPromise: Promise<void> | undefined;

    const command = (args: string[], input = ""): Promise<void> => new Promise((resolve, reject) => {
      const child = spawn("tuios", ["tml", ...args], { timeout: 5000, killSignal: "SIGKILL" });
      let failure: Error | undefined;
      child.stdout.resume();
      child.stderr.resume();
      child.on("error", (error) => { failure = error; });
      child.stdin.on("error", (error) => { failure = error; child.kill("SIGKILL"); });
      child.on("close", (code) => code === 0 && !failure ? resolve() : reject(failure ?? new Error(`tuios tml ${args[0]} failed`)));
      child.stdin.end(input);
    });
    const closeOwned = (): Promise<void> => {
      const owned = surface;
      const child = events;
      surface = undefined;
      events = undefined;
      if (openingDeadline) clearTimeout(openingDeadline);
      openingDeadline = undefined;
      const closing = (async () => {
        if (owned) {
          await pending.catch(() => {});
          await command(["close", owned]).catch(() => {});
        }
        if (child) {
          child.kill();
          const escalation = setTimeout(() => child.kill("SIGKILL"), 250);
          try { await childClosed.get(child); }
          finally { clearTimeout(escalation); }
        }
      })();
      cleaning = Promise.all([cleaning, closing]).then(() => {});
      return cleaning;
    };
    const fail = () => {
      finishOpening();
      suppressed = true;
      if (!warned && !stopped) {
        warned = true;
        ctx.ui.notify("Pipeline dashboard unavailable; using the existing widget.", "warning");
      }
      void closeOwned();
    };
    const tick = async () => {
      if (stopped || suppressed || busy) return;
      busy = true;
      try {
        const doc = buildTmlDocument(getModel());
        const nextRows = patchFor(doc.state.rows);
        if (surface) {
          if (nextRows !== lastRows) {
            pending = command(["patch", surface, "-"], nextRows);
            await pending;
            lastRows = nextRows;
          }
          return;
        }
        if (events || doc.state.rows.length === 0) return;
        let resolveOpened!: () => void;
        opened = new Promise<void>((resolve) => { resolveOpened = resolve; });
        finishOpening = resolveOpened;
        const child = spawn("tuios", ["tml", "show", "-", "--pane", "--events", "-s", session]);
        childClosed.set(child, new Promise<void>((resolve) => { child.once("close", () => resolve()); }));
        events = child;
        const isCurrent = () => events === child;
        const failCurrent = () => { if (isCurrent()) fail(); };
        lastRows = nextRows;
        let buffer = "";
        child.stderr.resume();
        child.on("error", failCurrent);
        child.stdin.on("error", failCurrent);
        child.on("close", (code) => {
          if (!isCurrent()) return;
          resolveOpened();
          events = undefined;
          if (openingDeadline) clearTimeout(openingDeadline);
          if (surface || (!stopped && !suppressed && code !== 0)) fail();
          else if (!stopped) suppressed = true;
        });
        const deadline = setTimeout(failCurrent, 10000);
        openingDeadline = deadline;
        deadline.unref();
        child.stdout.setEncoding("utf8");
        child.stdout.on("data", (chunk: string) => {
          if (!isCurrent()) return;
          buffer += chunk;
          if (Buffer.byteLength(buffer) > 64 * 1024) { failCurrent(); return; }
          let end: number;
          while ((end = buffer.indexOf("\n")) >= 0) {
            if (!isCurrent()) return;
            const line = buffer.slice(0, end);
            buffer = buffer.slice(end + 1);
            try {
              const event = JSON.parse(line);
              if (event.type === "tml_opened" && typeof event.surface === "string" && /^tml-[a-zA-Z0-9-]+$/.test(event.surface) && !surface) {
                surface = event.surface;
                resolveOpened();
                clearTimeout(deadline);
                if (stopped || suppressed) void closeOwned();
              } else if (event.type === "tml-event" && event.tml?.surface === surface) {
                const { name, value } = event.tml;
                if (name === "close") {
                  suppressed = true;
                  surface = undefined;
                  void closeOwned();
                } else if (!stopped && !suppressed && ["resume", "cancel-stage", "cancel-pipeline"].includes(name) && value && typeof value.pipelineId === "string" && (name === "cancel-pipeline" || (typeof value.stageId === "string" && typeof value.status === "string" && Number.isSafeInteger(value.attempt) && value.attempt >= 0))) {
                  onAction(name, value.pipelineId, value.stageId, name === "cancel-pipeline" ? undefined : { status: value.status, attempt: value.attempt });
                }
              }
            } catch { failCurrent(); }
          }
        });
        child.stdin.end(JSON.stringify(doc));
      } catch { fail(); } finally { busy = false; }
    };
    const timer = setInterval(() => { void tick(); }, 1000);
    timer.unref();
    reopen = () => { if (!stopped) { suppressed = false; void tick(); } };
    shutdown = () => {
      if (shutdownPromise) return shutdownPromise;
      stopped = true;
      clearInterval(timer);
      reopen = undefined;
      shutdownPromise = (async () => {
        await opened;
        await closeOwned();
      })();
      return shutdownPromise;
    };
    void tick();
  });

  pi.on("session_shutdown", async () => {
    await shutdown?.();
    shutdown = undefined;
    reopen = undefined;
  });
}
