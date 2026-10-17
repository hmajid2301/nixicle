/**
 * Footer Extension
 *
 * Replaces pi's built-in footer with a Catppuccin Mocha status bar.
 *
 * Left: rounded branch, session, and activity tabs.
 * Right: context usage, tokens, cost, model, and thinking level.
 */

import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";

const mocha = {
	mauve: "203;166;247",
	lavender: "180;190;254",
	green: "166;227;161",
	yellow: "249;226;175",
	peach: "250;179;135",
	red: "243;139;168",
	sky: "137;220;235",
	text: "205;214;244",
	overlay: "88;91;112",
	surface: "49;50;68",
	crust: "17;17;27",
};

export interface FooterStats {
	branch?: string | null;
	sessionName?: string;
	modelId: string;
	thinkingLevel?: string;
	used: number | null;
	total: number;
	input: number;
	output: number;
	cost: number;
	working: boolean;
	turnCount: number;
	elapsed: string;
}

function fg(color: keyof typeof mocha, text: string): string {
	return `\x1b[38;2;${mocha[color]}m${text}\x1b[0m`;
}

function clean(text: string): string {
	return text.replace(/[\x00-\x1f\x7f-\x9f]/g, " ").replace(/\s+/g, " ").trim();
}

function tab(color: keyof typeof mocha, icon: string, text: string, maxWidth: number): string {
	return fg(color, "")
		+ `\x1b[48;2;${mocha[color]}m\x1b[38;2;${mocha.crust}m\x1b[1m ${icon} \x1b[0m`
		+ `\x1b[48;2;${mocha.surface}m\x1b[38;2;${mocha.text}m ${truncateToWidth(clean(text), maxWidth)} \x1b[0m`
		+ fg("surface", "");
}

function fmt(n: number): string {
	if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}m`;
	if (n >= 1_000) return `${(n / 1_000).toFixed(1)}k`;
	return `${n}`;
}

export function renderFooterLine(data: FooterStats, width: number): string {
	if (width <= 0) return "";
	const pct = data.used === null ? null : Math.max(0, Math.min(100, data.total > 0 ? data.used / data.total * 100 : 0));
	const color = pct === null ? "sky" : pct >= 90 ? "red" : pct >= 70 ? "peach" : pct >= 40 ? "yellow" : "green";
	const filled = pct === null ? 0 : Math.floor(pct / 10);
	const bar = fg(color, "▓".repeat(filled)) + fg("overlay", "░".repeat(10 - filled));
	const percent = pct === null ? "--" : `${Math.round(pct)}%`;
	const context = `${fg(color, "")} ${bar} ${fg(color, `${data.used === null ? "--" : fmt(data.used)}/${fmt(data.total)} ${percent}`)}`;
	const tokens = fg("overlay", `↑${fmt(data.input)} ↓${fmt(data.output)} $${data.cost.toFixed(3)}`);
	const thinking = data.thinkingLevel && data.thinkingLevel !== "off" ? ` · ${clean(data.thinkingLevel)}` : "";
	const model = fg("mauve", `󰚩 ${clean(data.modelId)}${thinking}`);
	const branch = data.branch ? tab("lavender", "", data.branch, 24) : "";
	const session = data.sessionName ? tab("mauve", "", data.sessionName, 32) : "";
	const state = tab(data.working ? "peach" : "green", data.working ? "●" : "○", `${data.working ? "working" : "idle"} #${data.turnCount} ${data.elapsed}`, 28);
	const separator = fg("overlay", " │ ");
	const left = (...parts: string[]) => parts.filter(Boolean).join(" ");
	const right = (...parts: string[]) => parts.filter(Boolean).join(separator);
	const candidates = [
		[left(branch, session, state), right(context, tokens, model)],
		[left(branch, session), right(context, tokens, model)],
		[session, right(context, tokens, model)],
		[session, right(context, model)],
		["", right(context, model)],
		["", right(fg(color, ` ${percent}`), model)],
	];
	for (const [lhs, rhs] of candidates) {
		const length = visibleWidth(lhs) + visibleWidth(rhs);
		if (length + (lhs ? 1 : 0) <= width) {
			return lhs + " ".repeat(width - length) + rhs;
		}
	}
	return truncateToWidth(right(fg(color, percent), model), width);
}

export default function statusline(pi: ExtensionAPI) {
	let enabled = false;
	let turnCount = 0;
	let agentState: "idle" | "working" = "idle";
	let sessionStart = Date.now();
	let ctxUpdateTimer: ReturnType<typeof setInterval> | null = null;
	let tuiRef: { requestRender(): void } | null = null;

	function stopTimer() {
		if (ctxUpdateTimer) { clearInterval(ctxUpdateTimer); ctxUpdateTimer = null; }
	}

	function getTokenStats(ctx: ExtensionContext) {
		let input = 0, output = 0, cost = 0;
		for (const e of ctx.sessionManager.getBranch()) {
			if (e.type === "message" && e.message.role === "assistant") {
				const m = e.message as AssistantMessage;
				if (m.usage) {
					input += m.usage.input || 0;
					output += m.usage.output || 0;
					cost += m.usage.cost?.total || 0;
				}
			}
		}
		return { input, output, cost };
	}

	function sessionTime(): string {
		const s = Math.floor((Date.now() - sessionStart) / 1000);
		const h = Math.floor(s / 3600);
		const m = Math.floor((s % 3600) / 60);
		if (h > 0) return `${h}h${m}m`;
		if (m > 0) return `${m}m`;
		return `${s}s`;
	}

	pi.on("turn_start", async () => {
		turnCount++;
		agentState = "working";
		if (!ctxUpdateTimer) {
			ctxUpdateTimer = setInterval(() => tuiRef?.requestRender(), 5000);
			ctxUpdateTimer.unref();
		}
	});

	pi.on("turn_end", async () => {
		agentState = "idle";
		stopTimer();
	});
	pi.on("session_shutdown", stopTimer);

	function buildFooter(ctx: ExtensionContext) {
		let currentCtx = ctx;
		return (tui: any, _theme: any, footerData: any) => {
			const refresh = (_event: unknown, nextCtx: ExtensionContext) => {
				currentCtx = nextCtx;
				tui.requestRender();
			};
			const unsub = [
				pi.on("turn_start", refresh),
				pi.on("turn_end", refresh),
				pi.on("model_select", refresh),
				pi.on("session_info_changed", refresh),
				footerData.onBranchChange(() => tui.requestRender()),
			];
			tuiRef = tui;

			return {
				dispose() {
					unsub.forEach((fn) => fn());
					tuiRef = null;
				},
				invalidate() {},
				render(width: number): string[] {
					const usage = currentCtx.getContextUsage();
					return [renderFooterLine({
						...getTokenStats(currentCtx),
						used: usage?.tokens ?? null,
						total: usage?.contextWindow ?? currentCtx.model?.contextWindow ?? 128000,
						branch: footerData.getGitBranch(),
						sessionName: pi.getSessionName(),
						modelId: currentCtx.model?.id || "no-model",
						thinkingLevel: pi.getThinkingLevel(),
						working: agentState === "working",
						turnCount,
						elapsed: sessionTime(),
					}, width)];
				},
			};
		};
	}

	pi.registerCommand("statusline", {
		description: "Toggle statusline footer bar",
		handler: async (_args: string, ctx: ExtensionContext) => {
			enabled = !enabled;
			if (enabled) {
				ctx.ui.setFooter(buildFooter(ctx));
				ctx.ui.notify("Statusline enabled", "info");
			} else {
				ctx.ui.setFooter(undefined);
				ctx.ui.notify("Default footer restored", "info");
			}
		},
	});

	pi.on("session_start", async (_event, ctx) => {
		turnCount = 0;
		agentState = "idle";
		sessionStart = Date.now();
		stopTimer();
		if (!ctx.hasUI) return;
		enabled = true;
		ctx.ui.setFooter(buildFooter(ctx));
	});
}
