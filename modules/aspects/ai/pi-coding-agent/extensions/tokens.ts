/**
 * Token Usage Extension
 *
 * Aggregates token usage across all pi sessions. Provides:
 * - /tokens command to display token usage and cost
 * - Footer status showing total spend
 */

import { readFile, readdir } from "node:fs/promises";
import { join } from "node:path";
import { homedir } from "node:os";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";

const STATUS_ID = "token-usage";
const REFRESH_MS = 60_000;

interface TokenBuckets {
	input: number;
	output: number;
	cacheRead: number;
	cacheWrite: number;
	totalTokens: number;
	costTotal: number;
}

interface ModelUsage {
	provider: string;
	model: string;
	tokens: TokenBuckets;
	messageCount: number;
}

interface AggregateResult {
	totals: TokenBuckets;
	byModel: ModelUsage[];
	sessionCount: number;
	messageCount: number;
}

function emptyBuckets(): TokenBuckets {
	return { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, totalTokens: 0, costTotal: 0 };
}

function addBuckets(a: TokenBuckets, b: TokenBuckets): TokenBuckets {
	return {
		input: a.input + b.input,
		output: a.output + b.output,
		cacheRead: a.cacheRead + b.cacheRead,
		cacheWrite: a.cacheWrite + b.cacheWrite,
		totalTokens: a.totalTokens + b.totalTokens,
		costTotal: a.costTotal + b.costTotal,
	};
}

function sessionsBaseDir(): string {
	const agentDir = process.env.PI_CODING_AGENT_DIR ?? join(homedir(), ".pi", "agent");
	return join(agentDir, "sessions");
}

async function discoverSessionFiles(): Promise<string[]> {
	const baseDir = sessionsBaseDir();
	const files: string[] = [];

	let projectDirs: string[];
	try {
		const entries = await readdir(baseDir, { withFileTypes: true });
		projectDirs = entries.filter((e) => e.isDirectory()).map((e) => e.name);
	} catch {
		return [];
	}

	for (const projectDir of projectDirs) {
		const projectPath = join(baseDir, projectDir);
		try {
			const sessionEntries = await readdir(projectPath, { withFileTypes: true });
			for (const entry of sessionEntries) {
				if (entry.isFile() && entry.name.endsWith(".jsonl")) {
					files.push(join(projectPath, entry.name));
				}
			}
		} catch {
			// skip inaccessible project dirs
		}
	}

	return files;
}

async function parseSessionFile(
	filePath: string,
): Promise<{ buckets: TokenBuckets; models: Map<string, ModelUsage>; messageCount: number } | null> {
	let content: string;
	try {
		content = await readFile(filePath, "utf8");
	} catch {
		return null;
	}

	const lines = content.trim().split("\n");
	if (lines.length === 0) return null;

	const buckets = emptyBuckets();
	const models = new Map<string, ModelUsage>();
	let messageCount = 0;

	for (const line of lines) {
		let entry: any;
		try {
			entry = JSON.parse(line);
		} catch {
			continue;
		}

		if (entry.type !== "message" || entry.message?.role !== "assistant") continue;
		const usage = entry.message?.usage;
		if (!usage) continue;

		const b: TokenBuckets = {
			input: usage.input ?? 0,
			output: usage.output ?? 0,
			cacheRead: usage.cacheRead ?? 0,
			cacheWrite: usage.cacheWrite ?? 0,
			totalTokens: usage.totalTokens ?? 0,
			costTotal: usage.cost?.total ?? 0,
		};

		buckets.input += b.input;
		buckets.output += b.output;
		buckets.cacheRead += b.cacheRead;
		buckets.cacheWrite += b.cacheWrite;
		buckets.totalTokens += b.totalTokens;
		buckets.costTotal += b.costTotal;
		messageCount++;

		const provider = entry.message.provider ?? "unknown";
		const model = entry.message.model ?? "unknown";
		const key = `${provider}/${model}`;
		const existing = models.get(key);
		if (existing) {
			existing.tokens = addBuckets(existing.tokens, b);
			existing.messageCount++;
		} else {
			models.set(key, { provider, model, tokens: { ...b }, messageCount: 1 });
		}
	}

	if (messageCount === 0) return null;
	return { buckets, models, messageCount };
}

async function aggregateAllSessions(): Promise<AggregateResult> {
	const files = await discoverSessionFiles();
	const totals = emptyBuckets();
	const byModelMap = new Map<string, ModelUsage>();
	let sessionCount = 0;
	let messageCount = 0;

	const CONCURRENCY = 16;
	for (let i = 0; i < files.length; i += CONCURRENCY) {
		const batch = files.slice(i, i + CONCURRENCY);
		const results = await Promise.all(batch.map((f) => parseSessionFile(f)));

		for (const result of results) {
			if (!result) continue;
			sessionCount++;
			messageCount += result.messageCount;

			totals.input += result.buckets.input;
			totals.output += result.buckets.output;
			totals.cacheRead += result.buckets.cacheRead;
			totals.cacheWrite += result.buckets.cacheWrite;
			totals.totalTokens += result.buckets.totalTokens;
			totals.costTotal += result.buckets.costTotal;

			for (const [key, modelUsage] of result.models) {
				const existing = byModelMap.get(key);
				if (existing) {
					existing.tokens = addBuckets(existing.tokens, modelUsage.tokens);
					existing.messageCount += modelUsage.messageCount;
				} else {
					byModelMap.set(key, { ...modelUsage });
				}
			}
		}
	}

	const byModel = Array.from(byModelMap.values()).sort(
		(a, b) => b.tokens.costTotal - a.tokens.costTotal,
	);

	return { totals, byModel, sessionCount, messageCount };
}

function formatCost(cost: number): string {
	if (cost === 0) return "$0.00";
	if (cost < 0.01) return "<$0.01";
	if (cost >= 1000) return `$${(cost / 1000).toFixed(1)}K`;
	return `$${cost.toFixed(2)}`;
}

export default function tokenUsage(pi: ExtensionAPI) {
	let currentContext: ExtensionContext | undefined;
	let refreshTimer: ReturnType<typeof setInterval> | undefined;
	let inFlight = false;

	function statusText(ctx: ExtensionContext, kind: "total" | "unavailable", totalCost?: number): string {
		if (kind === "unavailable") return "token tracking unavailable";
		return `${ctx.ui.theme.fg("dim", "spend:")}${ctx.ui.theme.fg("accent", formatCost(totalCost ?? 0))}`;
	}

	function setStatusSafely(ctx: ExtensionContext | undefined, text: string | undefined): void {
		if (!ctx) return;
		try {
			if (!ctx.hasUI) return;
			ctx.ui.setStatus(STATUS_ID, text);
		} catch {
			// stale context after session switch/shutdown; ignore
		}
	}

	async function refresh(ctx: ExtensionContext): Promise<void> {
		if (inFlight) return;
		inFlight = true;
		try {
			const result = await aggregateAllSessions();
			setStatusSafely(ctx, statusText(ctx, "total", result.totals.costTotal));
		} catch {
			setStatusSafely(ctx, "token tracking unavailable");
		} finally {
			inFlight = false;
		}
	}

	pi.registerCommand("tokens", {
		description: "Display token usage and cost across all sessions",
		handler: async (_args, ctx) => {
			const result = await aggregateAllSessions();
			const { totals } = result;
			const lines = [
				`Token Usage: ${result.sessionCount} sessions, ${result.messageCount} messages`,
				`  Input: ${totals.input.toLocaleString()} · Output: ${totals.output.toLocaleString()}`,
				`  Cache Read: ${totals.cacheRead.toLocaleString()} · Cache Write: ${totals.cacheWrite.toLocaleString()}`,
				`  Total: ${totals.totalTokens.toLocaleString()} tokens · ${formatCost(totals.costTotal)}`,
			];
			for (const model of result.byModel) {
				lines.push(
					`  ${model.provider}/${model.model}: ${formatCost(model.tokens.costTotal)} (${model.messageCount} msgs)`,
				);
			}
			ctx.ui.notify(lines.join("\n"), "info");
		},
	});

	pi.on("session_start", (_event, ctx) => {
		currentContext = ctx;
		if (refreshTimer) clearInterval(refreshTimer);
		refreshTimer = setInterval(() => {
			if (currentContext) void refresh(currentContext);
		}, REFRESH_MS);
		refreshTimer.unref?.();
		void refresh(ctx);
	});

	pi.on("turn_end", (_event, ctx) => {
		currentContext = ctx;
		void refresh(ctx);
	});

	pi.on("session_shutdown", async (_event, ctx) => {
		currentContext = undefined;
		if (refreshTimer) {
			clearInterval(refreshTimer);
			refreshTimer = undefined;
		}
		setStatusSafely(ctx, undefined);
	});
}
