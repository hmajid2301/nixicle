/**
 * Lualine-style Footer Extension
 *
 * Replaces pi's built-in footer with a lualine-inspired status bar.
 *
 * Left:   [████░░░░░░] 35% ↑23k ↓8k $0.12
 * Center: ● working #7 12m
 * Right:  openai-codex/gpt-5.4 │ 🦴 full │ ● high [8t] │ PLAN
 *
 * Weekly budget bar: set PI_WEEKLY_BUDGET=<dollars> or PI_WEEKLY_TOKEN_BUDGET=<tokens>
 * Hidden when no budget is configured.
 *
 * Caveman integration: /caveman command + statusline badge + auto-trigger
 */

import type { AssistantMessage } from "@mariozechner/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";
import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";

// ── Weekly Usage Scanner ─────────────────────────────────────────────────────

interface WeeklyStats {
	input: number;
	output: number;
	cost: number;
	sessions: number;
}

const CACHE_TTL_MS = 60_000;
let cachedStats: WeeklyStats | null = null;
let cachedStatsTime = 0;

function scanWeeklyUsage(): WeeklyStats {
	const now = Date.now();
	if (cachedStats && now - cachedStatsTime < CACHE_TTL_MS) {
		return cachedStats;
	}

	const sessionsDir = path.join(os.homedir(), ".pi", "agent", "sessions");
	const weekAgo = now - 7 * 24 * 60 * 60 * 1000;

	const stats: WeeklyStats = { input: 0, output: 0, cost: 0, sessions: 0 };

	try {
		const projectDirs = fs.readdirSync(sessionsDir);
		for (const projectDir of projectDirs) {
			const projectPath = path.join(sessionsDir, projectDir);
			if (!fs.statSync(projectPath).isDirectory()) continue;

			const files = fs.readdirSync(projectPath);
			for (const file of files) {
				if (!file.endsWith(".jsonl")) continue;

				const filePath = path.join(projectPath, file);
				try {
					const stat = fs.statSync(filePath);
					if (stat.mtimeMs < weekAgo) continue;

					stats.sessions++;
					const content = fs.readFileSync(filePath, "utf-8");
					for (const line of content.split("\n")) {
						if (!line.trim()) continue;
						try {
							const entry = JSON.parse(line);
							if (
								entry.type === "message" &&
								entry.message?.role === "assistant" &&
								entry.message.usage
							) {
								const u = entry.message.usage;
								stats.input += u.input || 0;
								stats.output += u.output || 0;
								if (u.cost) stats.cost += u.cost.total || 0;
							}
						} catch {
							// Skip malformed lines
						}
					}
				} catch {
					// Skip unreadable files
				}
			}
		}
	} catch {
		// Sessions dir doesn't exist or unreadable
	}

	cachedStats = stats;
	cachedStatsTime = now;
	return stats;
}

// ── Extension ────────────────────────────────────────────────────────────────

export default function statusline(pi: ExtensionAPI) {
	let enabled = false;
	let turnCount = 0;
	let agentState: "idle" | "working" = "idle";
	let errorCount = 0;
	let sessionStart = Date.now();
	let ctxUpdateTimer: ReturnType<typeof setInterval> | null = null;
	let tuiRef: any = null;

	// ── Caveman state ──────────────────────────────────────────────────────
	type CavemanLevel = "off" | "lite" | "full" | "ultra";
	let cavemanLevel: CavemanLevel = "off";
	const CAVEMAN_TRIGGERS = [
		"caveman mode", "talk like caveman", "use caveman",
		"less tokens", "be brief", "fewer tokens",
	];
	const CAVEMAN_STOP = ["stop caveman", "normal mode"];
	function cavemanLabel(l: CavemanLevel): string {
		return { off: "", lite: "🪨 lite", full: "🦴 full", ultra: "💀 ultra" }[l] ?? "";
	}

	// --- Helpers ---

	function contextBar(theme: any, used: number, total: number): string {
		const pct = total > 0 ? used / total : 0;
		const w = 10;
		const filled = Math.round(pct * w);
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

	function errorBadge(theme: any): string {
		if (errorCount === 0) return "";
		return theme.fg("error", `⚠${errorCount}`);
	}

	function planBadge(theme: any): string {
		if (!pi.getFlag("plan")) return "";
		return theme.fg("warning", "PLAN");
	}

	function cavemanBadge(theme: any): string {
		if (cavemanLevel === "off") return "";
		return theme.fg("warning", cavemanLabel(cavemanLevel));
	}

	function weeklyBar(theme: any): string {
		const wk = scanWeeklyUsage();
		const totalTokens = wk.input + wk.output;

		const costBudget = parseFloat(process.env.PI_WEEKLY_BUDGET || "");
		const tokenBudget = parseInt(process.env.PI_WEEKLY_TOKEN_BUDGET || "", 10);

		if (!isNaN(costBudget) && costBudget > 0) {
			const pct = wk.cost / costBudget;
			const w = 8;
			const filled = Math.min(w, Math.round(pct * w));
			const bar = "█".repeat(filled) + "░".repeat(w - filled);
			const color = pct > 0.9 ? "error" : pct > 0.7 ? "warning" : "success";
			const usedStr = wk.cost < 0.01 ? wk.cost.toFixed(4) : wk.cost.toFixed(2);
			const budgetStr = costBudget < 0.01 ? costBudget.toFixed(4) : costBudget.toFixed(2);
			return theme.fg(color, `[${bar}] wk $${usedStr}/$${budgetStr}`);
		}

		if (!isNaN(tokenBudget) && tokenBudget > 0) {
			const pct = totalTokens / tokenBudget;
			const w = 8;
			const filled = Math.min(w, Math.round(pct * w));
			const bar = "█".repeat(filled) + "░".repeat(w - filled);
			const color = pct > 0.9 ? "error" : pct > 0.7 ? "warning" : "success";
			return theme.fg(color, `[${bar}] wk ${fmt(totalTokens)}/${fmt(tokenBudget)}`);
		}

		if (wk.cost > 0 || totalTokens > 0) {
			const costStr = wk.cost < 0.01 ? `$${wk.cost.toFixed(4)}` : `$${wk.cost.toFixed(2)}`;
			return theme.fg("dim", `wk ${fmt(totalTokens)}t ${costStr}`);
		}

		return "";
	}

	function contextLimit(theme: any, total: number): string {
		if (!total) return "";
		return theme.fg("dim", `lim:${fmt(total)}`);
	}

	function sep(theme: any): string {
		return theme.fg("dim", " │ ");
	}

	// --- Event tracking ---

	pi.on("session_start", async () => {
		turnCount = 0;
		errorCount = 0;
		agentState = "idle";
		sessionStart = Date.now();
		if (ctxUpdateTimer) { clearInterval(ctxUpdateTimer); ctxUpdateTimer = null; }
		cachedStats = null;
		cachedStatsTime = 0;

		// ── Caveman command (lazy — registered per session) ─────────────────
		pi.registerCommand("caveman", {
			description: "Toggle caveman mode - fewer tokens",
			getArgumentCompletions: (prefix: string) => {
				return ["lite", "full", "ultra", "off"]
					.filter(l => l.startsWith(prefix))
					.map(l => ({ value: l, label: l }));
			},
			handler: async (args: string, ctx: ExtensionContext) => {
				const levelArg = (args ?? "").trim().toLowerCase().split(/\s+/)[0].replace(/[^a-z]/g, "");
				if (levelArg && ["lite", "full", "ultra", "off"].includes(levelArg)) {
					cavemanLevel = levelArg as CavemanLevel;
				} else {
					cavemanLevel = cavemanLevel === "off" ? "full" : "off";
				}
				ctx.ui.notify(cavemanLevel === "off" ? "caveman: off" : cavemanLabel(cavemanLevel), "info");
				if (tuiRef) tuiRef.requestRender();
			},
		});
	});

	pi.on("input", async (event: { text: string }) => {
		const text = event.text.toLowerCase();
		for (const t of CAVEMAN_TRIGGERS) {
			if (text.includes(t)) {
				cavemanLevel = text.includes("ultra") ? "ultra" : text.includes("lite") ? "lite" : "full";
				if (tuiRef) tuiRef.requestRender();
				break;
			}
		}
		for (const t of CAVEMAN_STOP) {
			if (text.includes(t)) { cavemanLevel = "off"; if (tuiRef) tuiRef.requestRender(); break; }
		}
	});

	pi.on("before_agent_start", async () => {
		if (cavemanLevel === "off") return;
		const INSTR: Record<CavemanLevel, string> = {
			off: "",
			lite: `Caveman Lite Mode: Keep grammar. Drop filler words like "just", "really", "basically", "actually", "simply". Remove pleasantries like "sure", "certainly", "of course", "happy to". Professional but no fluff.`,
			full: `Caveman Mode: Drop articles (a, an, the). Drop filler (just, really, basically, actually, simply). Drop pleasantries (sure, certainly, of course). Short synonyms (big not extensive, fix not "implement a solution for"). No hedging. Fragments fine. Technical terms stay exact. Code blocks unchanged. Pattern: [thing] [action] [reason]. [next step].`,
			ultra: `Caveman Ultra Mode: Maximum compression. Telegraphic. Drop almost everything. Technical terms exact. Example: "Inline obj prop → new ref → re-render. useMemo."`,
		};
		return {
			message: {
				role: "user",
				content: [{ type: "text", text: `[CAVEMAN MODE: ${INSTR[cavemanLevel]}]` }],
				display: false,
			},
		};
	});

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
		cachedStatsTime = 0;
		if (ctxUpdateTimer) { clearInterval(ctxUpdateTimer); ctxUpdateTimer = null; }
	});

	pi.on("tool_execution_end", async (event: { isError?: boolean }) => {
		if (event.isError) errorCount++;
	});

	// --- Footer builder ---

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

					// LEFT: context bar + limit + session tokens + session cost
					const bar = contextBar(theme, used, total);
					const lim = contextLimit(theme, total);
					const tokens = theme.fg("dim", `↑${fmt(input)} ↓${fmt(output)}`);
					const costStr = theme.fg("dim", `$${cost.toFixed(3)}`);
					const left = `${bar}${lim ? " " + lim : ""} ${tokens} ${costStr}`;

					// CENTER: state + turn count + session time
					const stateIcon = agentState === "working"
						? theme.fg("accent", "●")
						: theme.fg("dim", "○");
					const stateLabel = agentState === "working"
						? theme.fg("accent", "working")
						: theme.fg("dim", "idle");
					const center = `${stateIcon} ${stateLabel} #${turnCount} ${sessionTime(theme)}`;

					// RIGHT: model + badges
					const modelId = ctx.model?.id || "no-model";
					const rightParts = [
						theme.fg("accent", modelId),
						cavemanBadge(theme),
						thinkingBadge(theme),
						toolCount(theme),
						planBadge(theme),
					].filter(Boolean);
					const right = rightParts.join(sep(theme).trimEnd() + " ");

					// COMPOSE with graceful fallback
					const s = sep(theme);
					const raw = `${left}${s}${center}${s}${right}`;
					if (visibleWidth(raw) <= width) {
						return [raw + " ".repeat(width - visibleWidth(raw))];
					}

					// Drop center
					const noCenter = `${left}${s}${right}`;
					if (visibleWidth(noCenter) <= width) {
						return [noCenter + " ".repeat(width - visibleWidth(noCenter))];
					}

					// Drop weekly + badges, keep model + limit
					const slimRight = [theme.fg("accent", modelId), contextLimit(theme, total)].filter(Boolean).join(" ");
					const slim = `${left}${s}${slimRight}`;
					if (visibleWidth(slim) <= width) {
						return [slim + " ".repeat(width - visibleWidth(slim))];
					}

					// Minimal
					const minimal = `${bar} ${theme.fg("accent", modelId)}`;
					if (visibleWidth(minimal) <= width) {
						return [minimal + " ".repeat(width - visibleWidth(minimal))];
					}

					return [truncateToWidth(bar, width)];
				},
			};
		};
	}

	// --- Command ---

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

	// Enable on session start
	pi.on("session_start", async (_event: any, ctx: ExtensionContext) => {
		enabled = true;
		ctx.ui.setFooter(buildFooter(ctx));
	});
}