// extensions/pipelines/widget-render.ts
// Pure variant-A "dashboard" renderer + VM builder. Locked columns:
// glyph(1) + 2sp | name(10) + 1sp | status(8) + 1sp | time(6) + 1sp | tools(4) + 2sp | note(rest)
// NOTE: brief specified tools(3), but its own test data (tools: "read") cannot
// fit a 3-char column — widened to 4 so common tool names render untruncated.
import type { PipelineState, StageState } from "./pipeline.ts";
import { readSessionTail } from "./session-tail.ts";
import type { RunHandle } from "./types.ts";

export interface RowVM {
  branch: "root" | "tee" | "elbow" | "none";
  glyph: string;
  name: string;
  status: string;
  time: string;
  tools: string;
  note: string;
  dimmed?: boolean;
}

export interface DashboardVM {
  title: string;
  active: number;
  waiting: number;
  done: number;
  failed: number;
  tokens: string;
  attention: boolean;
  rows: RowVM[];
}

export interface WidgetModel {
  pipelines: PipelineState[];
  runs: { handle: RunHandle; stageLabel?: string }[];
}

// How long a finished pipeline stays visible in the widget before it drops out.
export const FINISHED_GRACE_MS = 60_000;

const GLYPHS: Record<StageState["status"], string> = {
  done: "✓",
  running: "●",
  queued: "○",
  failed: "✗",
  halted: "⊘",
  "waiting-gate": "⚑",
  "waiting-help": "⏸",
};

const PIPELINE_GLYPHS: Record<PipelineState["status"], string> = {
  active: "◈",
  complete: "✓",
  failed: "✗",
  cancelled: "⊘",
};

function fmtElapsed(ms: number): string {
  const s = Math.max(0, Math.floor(ms / 1000));
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  const sec = s % 60;
  if (h > 0) return `${h}:${String(m).padStart(2, "0")}:${String(sec).padStart(2, "0")}`;
  return `${m}:${String(sec).padStart(2, "0")}`;
}

function fmtTokens(n: number): string {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}m`;
  if (n >= 1000) return `${(n / 1000).toFixed(1)}k`;
  return String(n);
}

function noteFor(s: StageState, lastTool?: string): string {
  if (s.status === "waiting-gate") return "needs your go-ahead";
  if (s.status === "waiting-help") return "needs help";
  if (s.status === "failed") return (s.error ?? "failed").slice(0, 20);
  if (s.status === "running") return lastTool ? `via ${lastTool}` : "";
  if (s.status === "halted") return "halted upstream";
  return "";
}

export function buildVM(model: WidgetModel): DashboardVM {
  const rows: RowVM[] = [];
  let active = 0;
  let waiting = 0;
  let done = 0;
  let failed = 0;
  let tokens = 0;

  const runFor = (stageLabel: string): RunHandle | undefined =>
    model.runs.find((r) => r.stageLabel === stageLabel)?.handle;

  for (const p of model.pipelines) {
    const finished = p.status !== "active";
    // Drop finished pipelines once they fall outside the grace window.
    if (finished && (p.finishedAt ?? 0) < Date.now() - FINISHED_GRACE_MS) continue;
    if (finished) {
      if (p.status === "complete") done++;
      if (p.status === "failed") failed++;
    }
    rows.push({
      branch: "root",
      glyph: PIPELINE_GLYPHS[p.status],
      name: p.name.slice(0, 10),
      status: p.status,
      time: fmtElapsed(Date.now() - p.createdAt),
      tools: "",
      note: p.creditLimit ? "credit limit" : "",
      dimmed: finished,
    });
    if (finished) continue; // finished pipelines show just the summary row
    p.stages.forEach((s, i) => {
      if (s.status === "running") active++;
      if (s.status === "queued" || s.status === "waiting-gate" || s.status === "waiting-help") waiting++;
      const run = runFor(`${p.id}:${s.id}`);
      const info = run?.sessionPath ? readSessionTail(run.sessionPath) : undefined;
      tokens += info?.tokens ?? 0;
      rows.push({
        branch: i === p.stages.length - 1 ? "elbow" : "tee",
        glyph: GLYPHS[s.status],
        name: s.id.slice(0, 10),
        status: s.status,
        time: s.startedAt ? fmtElapsed(Date.now() - s.startedAt) : "—",
        tools: (info?.lastTool ?? "").slice(0, 4),
        note: noteFor(s, info?.lastTool),
      });
    });
  }

  for (const r of model.runs.filter((run) => run.stageLabel === undefined)) {
    const info = r.handle.sessionPath ? readSessionTail(r.handle.sessionPath) : undefined;
    tokens += info?.tokens ?? 0;
    active++;
    rows.push({
      branch: "root",
      glyph: "●",
      name: r.handle.name.slice(0, 10),
      status: "running",
      time: fmtElapsed(Date.now() - r.handle.startedAt),
      tools: (info?.lastTool ?? "").slice(0, 4),
      note: info?.lastTool ? `via ${info.lastTool}` : "",
    });
  }

  return {
    title: "Pipelines",
    active,
    waiting,
    done,
    failed,
    tokens: fmtTokens(tokens),
    attention: active === 0 && waiting > 0,
    rows,
  };
}

// Pad to exactly n chars. Over-long values truncate to n-1 chars + "…" so
// truncation is visible while the fixed-width column invariant holds (review T9-1).
function pad(value: string, n: number): string {
  if (value.length > n) return value.slice(0, n - 1) + "…";
  return value + " ".repeat(n - value.length);
}

function trunc(value: string, n: number): string {
  return value.length <= n ? value : value.slice(0, Math.max(0, n - 1)) + "…";
}

export function renderDashboard(vm: DashboardVM, width = 60): string[] {
  const top = `╭${"─".repeat(width - 2)}╮`;
  const bottom = `╰${"─".repeat(width - 2)}╯`;
  const line = (inner: string): string => {
    const body = inner.length >= width - 4 ? trunc(inner, width - 4) : inner.padEnd(width - 4);
    return `│ ${body} │`;
  };
  const header = line(
    `${vm.title}${vm.attention ? " ⚑" : ""} · ●${vm.active} active · ○${vm.waiting} waiting · ${vm.tokens} tok`,
  );
  const branchPrefix = (r: RowVM): string =>
    r.dimmed ? "  · "
    : r.branch === "root" ? "  "
    : r.branch === "tee" ? "  ├ "
    : r.branch === "elbow" ? "  └ "
    : "";
  const rows = vm.rows.map((r) => {
    const body =
      `${r.glyph}  ${pad(r.name, 10)} ${pad(r.status, 8)} ${pad(r.time, 6)} ${pad(r.tools, 4)}  ${r.note}`;
    return line(branchPrefix(r) + body);
  });
  return [top, header, ...rows, bottom];
}

export function collapsedLine(vm: DashboardVM): string {
  const done = vm.done > 0 ? ` · ✓${vm.done} done` : "";
  const failed = vm.failed > 0 ? ` · ✗${vm.failed} failed` : "";
  return ` ◈ Pipelines · ●${vm.active} running · ○${vm.waiting} waiting${done}${failed} · ${vm.tokens} tok`;
}
