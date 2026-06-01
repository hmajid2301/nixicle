/**
 * Footer Extension
 *
 * Replaces pi's built-in footer with a lualine-inspired status bar.
 *
 * Left:   [████░░░░░░] 35% ↑23k ↓8k $0.12
 * Center: ● working #7 12m
 * Right:  openai-codex/gpt-5.4 │ ● high [8t] │ PLAN
 */

import type { AssistantMessage } from "@mariozechner/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";

export default function statusline(pi: ExtensionAPI) {
	let enabled = false;
	let turnCount = 0;
	let agentState: "idle" | "working" = "idle";
	let errorCount = 0;
	let sessionStart = Date.now();
	let ctxUpdateTimer: ReturnType<typeof setInterval> | null = null;
	let tuiRef: any = null;

	function contextBar(theme: any, used: number, total: number): string {
		const pct = total > 0 ? used / total : 0;
		const w = 10;
		const filled = Math.max(0, Math.min(w, Math.round(pct * w)));
		const bar = "█".repeat(filled) + "░".repeat(w - filled);
		const color = pct > 0.85 ? "error" : pct > 0.6 ? "warning" : "success";
		return theme.fg(color, `[${bar}] ${Math.round(pct * 100)}%`);
	}

	function fmt(n: number): string {
		if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}m`;
		if (n >= 1_000) return `${(n / 1_000).toFixed(1)}k`;
		return `${n}`;
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

	function sessionTime(theme: any): string {
		const s = Math.floor((Date.now() - sessionStart) / 1000);
		if (s === 0) return theme.fg("dim", "–");
		const h = Math.floor(s / 3600);
		const m = Math.floor((s % 3600) / 60);
		if (h > 0) return theme.fg("dim", `${h}h${m}m`);
		if (m > 0) return theme.fg("dim", `${m}m`);
		return theme.fg("dim", `${s}s`);
	}

	function toolCount(theme: any): string {
		return theme.fg("dim", `[${pi.getActiveTools().length}t]`);
	}

	function thinkingBadge(theme: any): string {
		const level = pi.getThinkingLevel();
		if (!level || level === "off") return "";
		const icons: Record<string, string> = {
			minimal: "·", low: "··", medium: "···", high: "●", xhigh: "●●",
		};
		return theme.fg("warning", `${icons[level] || "·"} ${level}`);
	}

	function planBadge(theme: any): string {
		if (!pi.getFlag("plan")) return "";
		return theme.fg("warning", "PLAN");
	}

	function contextLimit(theme: any, total: number): string {
		if (!total) return "";
		return theme.fg("dim", `lim:${fmt(total)}`);
	}

	function sep(theme: any): string {
		return theme.fg("dim", " │ ");
	}


	pi.on("turn_start", async () => {
		turnCount++;
		agentState = "working";
		if (!ctxUpdateTimer) {
			ctxUpdateTimer = setInterval(() => {
				if (tuiRef) try { tuiRef.requestRender(); } catch {}
			}, 5000);
			if (ctxUpdateTimer.unref) ctxUpdateTimer.unref();
		}
	});

	pi.on("turn_end", async () => {
		agentState = "idle";
		if (ctxUpdateTimer) { clearInterval(ctxUpdateTimer); ctxUpdateTimer = null; }
	});

	pi.on("tool_execution_end", async (event: { isError?: boolean }) => {
		if (event.isError) errorCount++;
	});

	function buildFooter(ctx: ExtensionContext) {
		return (tui: any, theme: any, _footerData: any) => {
			const unsub = [
				pi.on("turn_start", () => tui.requestRender()),
				pi.on("turn_end", () => tui.requestRender()),
				pi.on("model_select", () => tui.requestRender()),
				pi.on("tool_execution_end", () => tui.requestRender()),
			];
			tuiRef = tui;

			return {
				dispose() {
					unsub.forEach((fn: unknown) => { if (typeof fn === "function") fn(); });
					tuiRef = null;
				},
				invalidate() {},
				render(width: number): string[] {
					const usage = ctx.getContextUsage();
					const used = usage?.tokens || 0;
					const total = usage?.maxTokens || ctx.model?.contextWindow || 128000;
					const { input, output, cost } = getTokenStats(ctx);

					const bar = contextBar(theme, used, total);
					const lim = contextLimit(theme, total);
					const tokens = theme.fg("dim", `↑${fmt(input)} ↓${fmt(output)}`);
					const costStr = theme.fg("dim", `$${cost.toFixed(3)}`);
					const left = `${bar}${lim ? " " + lim : ""} ${tokens} ${costStr}`;

					const stateIcon = agentState === "working"
						? theme.fg("accent", "●")
						: theme.fg("dim", "○");
					const stateLabel = agentState === "working"
						? theme.fg("accent", "working")
						: theme.fg("dim", "idle");
					const center = `${stateIcon} ${stateLabel} #${turnCount} ${sessionTime(theme)}`;

					const modelId = ctx.model?.id || "no-model";
					const rightParts = [
						theme.fg("accent", modelId),
						thinkingBadge(theme),
						toolCount(theme),
						planBadge(theme),
					].filter(Boolean);
					const right = rightParts.join(sep(theme).trimEnd() + " ");

					const s = sep(theme);
					const raw = `${left}${s}${center}${s}${right}`;
					if (visibleWidth(raw) <= width) {
						return [raw + " ".repeat(width - visibleWidth(raw))];
					}

					const noCenter = `${left}${s}${right}`;
					if (visibleWidth(noCenter) <= width) {
						return [noCenter + " ".repeat(width - visibleWidth(noCenter))];
					}

					const slimRight = [theme.fg("accent", modelId), contextLimit(theme, total)].filter(Boolean).join(" ");
					const slim = `${left}${s}${slimRight}`;
					if (visibleWidth(slim) <= width) {
						return [slim + " ".repeat(width - visibleWidth(slim))];
					}

					const minimal = `${bar} ${theme.fg("accent", modelId)}`;
					if (visibleWidth(minimal) <= width) {
						return [minimal + " ".repeat(width - visibleWidth(minimal))];
					}

					return [truncateToWidth(bar, width)];
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

	pi.on("session_start", async (_event: any, ctx: ExtensionContext) => {
		turnCount = 0;
		errorCount = 0;
		agentState = "idle";
		sessionStart = Date.now();
		if (ctxUpdateTimer) { clearInterval(ctxUpdateTimer); ctxUpdateTimer = null; }

		enabled = true;
		ctx.ui.setFooter(buildFooter(ctx));
	});
}
