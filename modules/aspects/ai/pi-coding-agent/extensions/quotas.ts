/**
 * Codex Quota Extension
 *
 * Tracks OpenAI Codex quota usage. Provides:
 * - /quotas command to display remaining quota
 * - Footer status showing quota usage for the active provider
 * - Warnings when approaching quota limits
 */

import { readFileSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";

const STATUS_ID = "codex-quota";
const REFRESH_MS = 60_000;
const FETCH_TIMEOUT_MS = 15_000;

interface CodexWindow {
	label: string;
	usedPercent: number;
	resetsAt: Date;
	windowSeconds: number;
}

interface CodexQuota {
	windows: CodexWindow[];
	credits?: { balance: number; approxLocalMessages?: number };
	spendCapReached?: boolean;
}

function getCodexAuth(): { accessToken?: string; accountId?: string } {
	try {
		const authPath = join(homedir(), ".pi", "agent", "auth.json");
		const data = JSON.parse(readFileSync(authPath, "utf8")) as Record<string, any>;
		const cred = data["openai-codex"];
		return { accessToken: cred?.access, accountId: cred?.accountId };
	} catch {
		return {};
	}
}

function parseDateish(value: unknown): Date {
	if (typeof value === "number") {
		const ms = value > 10 ** 11 ? value : value * 1000;
		return new Date(ms);
	}
	if (typeof value === "string") return new Date(value);
	return new Date(0);
}

function percentLeftToUsedPercent(limit: any): number {
	if (limit?.percent_left != null) return Math.max(0, 100 - Number(limit.percent_left));
	if (limit?.remaining_percent != null) return Math.max(0, 100 - Number(limit.remaining_percent));
	if (limit?.used_percent != null) return Number(limit.used_percent);
	return 0;
}

function windowLabel(windowSeconds: number): string {
	if (windowSeconds % (24 * 60 * 60) === 0) return `${windowSeconds / (24 * 60 * 60)}d`;
	if (windowSeconds % (60 * 60) === 0) return `${windowSeconds / (60 * 60)}h`;
	if (windowSeconds % 60 === 0) return `${windowSeconds / 60}m`;
	return `${windowSeconds}s`;
}

function parseCodexUsage(data: any): CodexQuota {
	const rateLimit = data?.rate_limit ?? data?.rate_limits ?? {};
	const primary =
		rateLimit.primary_window ??
		rateLimit.primary ??
		rateLimit.five_hour_limit ??
		rateLimit.five_hour;
	const secondary =
		rateLimit.secondary_window ??
		rateLimit.secondary ??
		rateLimit.weekly_limit ??
		rateLimit.weekly;

	const windows: CodexWindow[] = [];

	if (primary) {
		const windowSeconds = Number(primary.limit_window_seconds ?? 5 * 60 * 60) || 5 * 60 * 60;
		windows.push({
			label: windowLabel(windowSeconds),
			usedPercent: percentLeftToUsedPercent(primary),
			resetsAt: parseDateish(primary.reset_at ?? primary.reset_time_ms),
			windowSeconds,
		});
	}

	if (secondary) {
		const windowSeconds = Number(secondary.limit_window_seconds ?? 7 * 24 * 60 * 60) || 7 * 24 * 60 * 60;
		windows.push({
			label: windowLabel(windowSeconds),
			usedPercent: percentLeftToUsedPercent(secondary),
			resetsAt: parseDateish(secondary.reset_at ?? secondary.reset_time_ms),
			windowSeconds,
		});
	}

	const credits = data?.credits;
	const creditsInfo =
		credits?.has_credits && credits.balance != null
			? { balance: Number(credits.balance), approxLocalMessages: credits.approx_local_messages }
			: undefined;

	return { windows, credits: creditsInfo, spendCapReached: !!data?.spend_control?.reached };
}

async function fetchCodexQuota(signal?: AbortSignal): Promise<CodexQuota | { error: string }> {
	const { accessToken, accountId } = getCodexAuth();
	if (!accessToken) return { error: "No Codex access token found" };
	if (!accountId) return { error: "No Codex account id found" };

	const signals = [AbortSignal.timeout(FETCH_TIMEOUT_MS)];
	if (signal) signals.push(signal);
	const combined = AbortSignal.any(signals);

	try {
		const res = await fetch("https://chatgpt.com/backend-api/wham/usage", {
			headers: {
				Authorization: `Bearer ${accessToken}`,
				"ChatGPT-Account-Id": accountId,
				Accept: "application/json",
				Origin: "https://chatgpt.com",
				Referer: "https://chatgpt.com/",
				"User-Agent": "Mozilla/5.0",
			},
			signal: combined,
		});
		if (!res.ok) return { error: `HTTP ${res.status}` };
		return parseCodexUsage(await res.json());
	} catch (err) {
		return { error: err instanceof Error ? err.message : "Unknown error" };
	}
}

function formatTimeRemaining(date: Date): string {
	const ms = date.getTime() - Date.now();
	if (ms <= 0) return "now";
	const totalMins = Math.ceil(ms / (1000 * 60));
	const totalHours = Math.floor(totalMins / 60);
	const days = Math.floor(totalHours / 24);
	const hours = totalHours % 24;
	if (days >= 1) return `${days}d${hours}h`;
	if (hours >= 1) return `${hours}h`;
	return `${totalMins}m`;
}

function severity(usedPercent: number): "success" | "warning" | "error" {
	if (usedPercent >= 90) return "error";
	if (usedPercent >= 80) return "warning";
	return "success";
}

function formatQuotaLine(theme: any, w: CodexWindow): string {
	const color = severity(w.usedPercent);
	const remaining = Math.max(0, Math.round(100 - w.usedPercent));
	return `${theme.fg("dim", `${w.label}:`)}${theme.fg(color, `${remaining}% left`)}`;
}

export default function codexQuota(pi: ExtensionAPI) {
	let currentContext: ExtensionContext | undefined;
	let refreshTimer: ReturnType<typeof setInterval> | undefined;
	let inFlight = false;

	function formatQuotaStatus(ctx: ExtensionContext, quota: CodexQuota): string | undefined {
		if (quota.windows.length === 0) return undefined;
		return quota.windows.map((w) => formatQuotaLine(ctx.ui.theme, w)).join(" ");
	}

	function checkWarnings(ctx: ExtensionContext, quota: CodexQuota): void {
		const risky = quota.windows.filter((w) => w.usedPercent >= 80);
		if (risky.length === 0) return;
		const lines = risky.map(
			(w) => `- ${w.label}: ${Math.round(w.usedPercent)}% used, resets in ${formatTimeRemaining(w.resetsAt)}`,
		);
		const level = risky.some((w) => w.usedPercent >= 90) ? "error" : "warning";
		ctx.ui.notify(`Codex quota warning:\n${lines.join("\n")}`, level);
	}

	async function refresh(ctx: ExtensionContext): Promise<void> {
		if (inFlight) return;
		inFlight = true;
		try {
			const result = await fetchCodexQuota();
			if ("error" in result) {
				ctx.ui.setStatus(STATUS_ID, ctx.ui.theme.fg("warning", "quota unavailable"));
				return;
			}
			ctx.ui.setStatus(STATUS_ID, formatQuotaStatus(ctx, result));
			checkWarnings(ctx, result);
		} finally {
			inFlight = false;
		}
	}

	pi.registerCommand("quotas", {
		description: "Display remaining OpenAI Codex quota",
		handler: async (_args, ctx) => {
			const result = await fetchCodexQuota();
			if ("error" in result) {
				ctx.ui.notify(`Codex quota: ${result.error}`, "warning");
				return;
			}
			const lines = result.windows.map(
				(w) =>
					`${w.label}: ${Math.round(w.usedPercent)}% used (${Math.round(100 - w.usedPercent)}% left), resets in ${formatTimeRemaining(w.resetsAt)}`,
			);
			if (result.credits) {
				lines.push(
					`Credits: $${result.credits.balance.toFixed(2)}${result.credits.approxLocalMessages ? ` (~${result.credits.approxLocalMessages} local msgs)` : ""}`,
				);
			}
			if (result.spendCapReached) lines.push("Spend cap: REACHED");
			ctx.ui.notify(lines.join("\n") || "No quota data", "info");
		},
	});

	pi.on("session_start", (_event, ctx) => {
		currentContext = ctx;
		if (ctx.model?.provider !== "openai-codex") {
			ctx.ui.setStatus(STATUS_ID, undefined);
			return;
		}
		if (refreshTimer) clearInterval(refreshTimer);
		refreshTimer = setInterval(() => {
			if (currentContext) void refresh(currentContext);
		}, REFRESH_MS);
		refreshTimer.unref?.();
		void refresh(ctx);
	});

	pi.on("turn_end", (_event, ctx) => {
		currentContext = ctx;
		if (ctx.model?.provider === "openai-codex") void refresh(ctx);
	});

	pi.on("model_select", (_event, ctx) => {
		currentContext = ctx;
		if (ctx.model?.provider !== "openai-codex") {
			ctx.ui.setStatus(STATUS_ID, undefined);
			return;
		}
		void refresh(ctx);
	});

	pi.on("session_shutdown", async (_event, ctx) => {
		currentContext = undefined;
		if (refreshTimer) {
			clearInterval(refreshTimer);
			refreshTimer = undefined;
		}
		ctx.ui.setStatus(STATUS_ID, undefined);
	});
}
