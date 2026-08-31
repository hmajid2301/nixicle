// extensions/pipelines/widget.ts
// Dashboard widget: expanded while anything runs, collapsed one-liner while
// only waiting/lingering, removed when idle.
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { truncateToWidth } from "@mariozechner/pi-tui";
import type { PipelineState, StageState } from "./pipeline.ts";
import { readSessionTail } from "./session-tail.ts";
import type { RunHandle } from "./types.ts";
import { collapsedLine, renderDashboard, type DashboardVM, type RowVM } from "./widget-render.ts";

export interface WidgetModel {
	pipelines: PipelineState[];
	runs: { handle: RunHandle; stageLabel?: string }[];
}

const GLYPHS: Record<StageState["status"], string> = {
	done: "✓",
	running: "●",
	queued: "○",
	failed: "✗",
	halted: "⊘",
	"waiting-gate": "⚑",
	"waiting-help": "⏸",
};

function fmtElapsed(ms: number): string {
	const s = Math.max(0, Math.floor(ms / 1000));
	const m = Math.floor(s / 60);
	return `${m}:${String(s % 60).padStart(2, "0")}`;
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
	let tokens = 0;

	const runFor = (stageLabel: string): RunHandle | undefined =>
		model.runs.find((r) => r.stageLabel === stageLabel)?.handle;

	for (const p of model.pipelines) {
		if (p.status !== "active") continue;
		rows.push({
			branch: "root",
			glyph: "◈",
			name: p.name.slice(0, 10),
			status: p.status,
			time: fmtElapsed(Date.now() - p.createdAt),
			tools: "",
			note: "",
		});
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
		tokens: fmtTokens(tokens),
		attention: active === 0 && waiting > 0,
		rows,
	};
}

export function registerWidget(
	pi: ExtensionAPI,
	getModel: () => WidgetModel,
	opts: { collapsedDefault?: boolean } = {},
): void {
	let timer: ReturnType<typeof setInterval> | undefined;
	let tuiRef: { requestRender?: () => void } | undefined;

	const draw = (ctx: ExtensionContext): void => {
		if (!ctx.hasUI) return;
		const vm = buildVM(getModel());
		if (vm.rows.length === 0) {
			ctx.ui.setWidget("pipelines", undefined);
			tuiRef = undefined;
			return;
		}

		ctx.ui.setWidget("pipelines", (tui: any, theme: any) => {
			tuiRef = tui;
			return {
				render(width: number): string[] {
					const expanded = vm.active > 0 && !opts.collapsedDefault;
					const lines = expanded ? renderDashboard(vm, Math.max(20, width)) : [collapsedLine(vm)];
					return lines.map((line) => {
						if (!vm.attention) return truncateToWidth(line, width);
						return theme.fg("warning", truncateToWidth(line, width));
					});
				},
				invalidate() {},
				dispose() {
					if (tuiRef === tui) tuiRef = undefined;
				},
			};
		});
	};

	pi.on("session_start", (_event, ctx: ExtensionContext) => {
		draw(ctx);
		timer = setInterval(() => {
			draw(ctx);
			tuiRef?.requestRender?.();
		}, 1000);
		if (timer.unref) timer.unref();
	});

	pi.on("session_shutdown", () => {
		if (timer) clearInterval(timer);
		timer = undefined;
		tuiRef = undefined;
	});
}
