/**
 * Provider Usage & Quota Extension
 *
 * Shows remaining usage/quota in the footer for the provider actually in use:
 *
 * - openai-codex  -> ChatGPT Codex subscription rate limits (5h / weekly)
 * - opencode-go   -> OpenCode Zen plan usage (rolling / weekly / monthly)
 * - ollama / llama-swap / other local providers -> deliberately not polled:
 *   the local ollama server exposes no usage endpoint and ollama.com/api/usage
 *   requires an API key (the signed-in local identity is rejected), so there
 *   is nothing to fetch without extra credentials. Footer is simply cleared.
 *
 * Provides:
 * - Footer status showing remaining headroom per window (colour coded)
 * - /quotas command showing the detailed report for the active provider
 * - Warnings when a window is running low (at most one notification per
 *   turn: re-armed by the next user message, once the old warning has
 *   scrolled out of view)
 *
 * Polling and warnings are strictly scoped to quota providers: switching to a
 * local model stops polling, clears the footer, and never surfaces a Codex or
 * Zen error while a different provider is active.
 */

import { readFileSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";

const STATUS_ID = "provider-quota";
const REFRESH_MS = 60_000;
const CACHE_TTL_MS = 60_000;
const FETCH_TIMEOUT_MS = 15_000;
const WARN_PERCENT = 80;
const ERROR_PERCENT = 90;
const DEFAULT_ZEN_USAGE_URL = "https://opencode.ai/zen/go/v1/usage";

type QuotaProvider = "openai-codex" | "opencode-go";
type QuotaStatusUIMode = "regular" | "fullscreen" | undefined;

const PROVIDER_LABELS: Record<QuotaProvider, string> = {
	"openai-codex": "codex",
	"opencode-go": "zen",
};

interface UsageWindow {
	label: string;
	usedPercent: number;
	resetsAt: Date;
	windowSeconds: number;
	limited?: boolean;
}

interface ProviderUsage {
	provider: QuotaProvider;
	windows: UsageWindow[];
	credits?: { balance: number; approxLocalMessages?: number };
	spendCapReached?: boolean;
}

/**
 * `ctx.model` on a stale context throws in pi, so never read it directly.
 */
function safeModel(ctx: ExtensionContext): { provider?: string; baseUrl?: string } | undefined {
	try {
		return ctx.model;
	} catch {
		return undefined;
	}
}

/**
 * Providers that expose a remotely checkable quota (cf. pi-quotas).
 */
function quotaProviderOf(ctx: ExtensionContext): QuotaProvider | undefined {
	const provider = safeModel(ctx)?.provider;
	if (provider === "openai-codex" || provider === "opencode-go") return provider;
	return undefined;
}

function clampPercent(value: number): number {
	return Math.max(0, Math.min(100, value));
}

function shouldRenderQuotaStatus(
	{ uiMode, previousText, nextText }: { uiMode: QuotaStatusUIMode; previousText: string | undefined; nextText: string | undefined },
): boolean {
	if (uiMode !== "fullscreen") return false;
	return previousText !== nextText;
}

function agentDir(): string {
	return process.env.PI_CODING_AGENT_DIR ?? join(homedir(), ".pi", "agent");
}

function readStoredAuth(): Record<string, any> {
	try {
		return JSON.parse(readFileSync(join(agentDir(), "auth.json"), "utf8")) as Record<string, any>;
	} catch {
		return {};
	}
}

function codexAuth(): { accessToken?: string; accountId?: string } {
	const cred = readStoredAuth()["openai-codex"];
	return { accessToken: cred?.access, accountId: cred?.accountId };
}

function opencodeGoKey(): string | undefined {
	return readStoredAuth()["opencode-go"]?.key;
}

function parseDateish(value: unknown): Date {
	if (typeof value === "number") {
		const ms = value > 10 ** 11 ? value : value * 1000;
		return new Date(ms);
	}
	if (typeof value === "string") {
		const parsed = Date.parse(value);
		if (!Number.isNaN(parsed)) return new Date(parsed);
		return new Date(0);
	}
	return new Date(0);
}

function windowLabel(windowSeconds: number): string {
	if (windowSeconds % (24 * 60 * 60) === 0) return `${windowSeconds / (24 * 60 * 60)}d`;
	if (windowSeconds % (60 * 60) === 0) return `${windowSeconds / (60 * 60)}h`;
	if (windowSeconds % 60 === 0) return `${windowSeconds / 60}m`;
	return `${windowSeconds}s`;
}

function percentLeftToUsedPercent(limit: any): number {
	if (limit?.percent_left != null) return Math.max(0, 100 - Number(limit.percent_left));
	if (limit?.remaining_percent != null) return Math.max(0, 100 - Number(limit.remaining_percent));
	if (limit?.used_percent != null) return Number(limit.used_percent);
	return 0;
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
	if (usedPercent >= ERROR_PERCENT) return "error";
	if (usedPercent >= WARN_PERCENT) return "warning";
	return "success";
}

async function fetchJson(
	url: string,
	headers: Record<string, string>,
	signal?: AbortSignal,
): Promise<{ ok: true; data: any } | { ok: false; message: string }> {
	const signals = [AbortSignal.timeout(FETCH_TIMEOUT_MS)];
	if (signal) signals.push(signal);
	const combined = AbortSignal.any(signals);

	try {
		const res = await fetch(url, { headers, signal: combined });
		if (!res.ok) return { ok: false, message: `HTTP ${res.status}` };
		const text = await res.text();
		try {
			return { ok: true, data: JSON.parse(text) };
		} catch {
			return { ok: false, message: "Invalid JSON response" };
		}
	} catch (err) {
		return { ok: false, message: err instanceof Error ? err.message : "Unknown error" };
	}
}

// --- OpenAI Codex ----------------------------------------------------------

function parseCodexUsage(data: any): ProviderUsage {
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

	const windows: UsageWindow[] = [];

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

	return {
		provider: "openai-codex",
		windows,
		credits: creditsInfo,
		spendCapReached: !!data?.spend_control?.reached,
	};
}

async function fetchCodexUsage(signal?: AbortSignal): Promise<ProviderUsage | { error: string }> {
	const { accessToken, accountId } = codexAuth();
	if (!accessToken) return { error: "No Codex access token found" };
	if (!accountId) return { error: "No Codex account id found" };

	const result = await fetchJson(
		"https://chatgpt.com/backend-api/wham/usage",
		{
			Authorization: `Bearer ${accessToken}`,
			"ChatGPT-Account-Id": accountId,
			Accept: "application/json",
			Origin: "https://chatgpt.com",
			Referer: "https://chatgpt.com/",
			"User-Agent": "Mozilla/5.0",
		},
		signal,
	);
	if (!result.ok) return { error: result.message };
	return parseCodexUsage(result.data);
}

// --- OpenCode Go (Zen) -----------------------------------------------------

/**
 * Zen plan usage: GET {model base URL}/usage with the inference API key.
 * Returns per-window { status, percent, resetsAt } for rolling/weekly/monthly.
 */
function parseZenUsage(data: any): ProviderUsage | { error: string } {
	const usage = data?.usage;
	if (!usage || typeof usage !== "object" || Array.isArray(usage)) {
		return { error: "Zen usage response was not an object" };
	}

	// [payload key, footer label, window length]
	const definitions: Array<[string, string, number]> = [
		["rolling", "r", 5 * 60 * 60],
		["weekly", "w", 7 * 24 * 60 * 60],
		["monthly", "m", 30 * 24 * 60 * 60],
	];

	const windows: UsageWindow[] = [];
	for (const [key, label, windowSeconds] of definitions) {
		const raw = usage[key];
		if (!raw || typeof raw !== "object") continue;
		const status = typeof raw.status === "string" ? raw.status : "unknown";
		if (status !== "ok" && status !== "rate-limited") continue;
		const usedPercent = clampPercent(Number(raw.percent));
		if (!Number.isFinite(usedPercent)) continue;
		windows.push({
			label,
			usedPercent,
			resetsAt: parseDateish(raw.resetsAt),
			windowSeconds,
			limited: status === "rate-limited",
		});
	}

	if (windows.length === 0) return { error: "Zen usage endpoint returned no displayable windows" };
	return { provider: "opencode-go", windows };
}

async function fetchZenUsage(
	baseUrl: string | undefined,
	apiKey: string | undefined,
	signal?: AbortSignal,
): Promise<ProviderUsage | { error: string }> {
	if (!apiKey) return { error: "No OpenCode Go API key found" };

	const base = baseUrl?.trim().replace(/\/+$/, "");
	const url = base ? `${base}/usage` : DEFAULT_ZEN_USAGE_URL;

	const result = await fetchJson(
		url,
		{
			Authorization: `Bearer ${apiKey}`,
			Accept: "application/json",
			"User-Agent": "pi",
		},
		signal,
	);
	if (!result.ok) return { error: result.message };
	return parseZenUsage(result.data);
}

// --- Extension -------------------------------------------------------------

export default function providerQuota(pi: ExtensionAPI) {
	let currentContext: ExtensionContext | undefined;
	let refreshTimer: ReturnType<typeof setInterval> | undefined;
	let lastRenderedStatus: string | undefined;
	// At most one quota warning per turn: after notifying, stay quiet until the
	// next user message (turn_start) re-arms it. By then the previous warning
	// has scrolled out of view, so repeating is useful again.
	let turnWarned = false;
	// Bumped whenever the active session/provider changes so a stale async
	// fetch can never write into a replacement session.
	let generation = 0;
	// Short-lived per-provider cache: { [provider]: { at, usage } }.
	const cache = new Map<string, { at: number; usage: ProviderUsage }>();
	// In-flight fetch per provider: concurrent refreshes (timer tick, turn_end,
	// model_select) await the same promise instead of piling up requests.
	const inFlight = new Map<QuotaProvider, Promise<ProviderUsage | { error: string }>>();

	function providerLabel(provider: QuotaProvider | undefined): string {
		return provider ? PROVIDER_LABELS[provider] : "?";
	}

	function stopTimer(): void {
		if (refreshTimer) {
			clearInterval(refreshTimer);
			refreshTimer = undefined;
		}
	}

	function getQuotaStatusUIMode(ctx: ExtensionContext | undefined): QuotaStatusUIMode {
		if (!ctx || ctx.mode !== "tui") return undefined;
		const ui = ctx.ui as typeof ctx.ui & { mode?: QuotaStatusUIMode };
		return ui.mode;
	}

	function startTimer(): void {
		if (refreshTimer) return;
		refreshTimer = setInterval(() => {
			if (!currentContext) return;
			void refresh(currentContext).catch(() => undefined);
		}, REFRESH_MS);
		refreshTimer.unref?.();
	}

	/**
	 * setStatus guarded per pi docs: `ctx.hasUI` is false in print (`-p`) and
	 * JSON modes where there is no footer to write, and stale contexts can
	 * throw during teardown. Failures are non-fatal; a newer handler or the
	 * next refresh will rewrite the status anyway.
	 */
	function setStatusSafely(ctx: ExtensionContext | undefined, text: string | undefined): void {
		if (!ctx) return;
		try {
			if (!ctx.hasUI) return;
			if (!shouldRenderQuotaStatus({
				uiMode: getQuotaStatusUIMode(ctx),
				previousText: lastRenderedStatus,
				nextText: text,
			})) return;
			ctx.ui.setStatus(STATUS_ID, text);
			lastRenderedStatus = text;
		} catch {
			// stale context after session switch/shutdown; ignore
		}
	}

	function formatFooter(ctx: ExtensionContext, usage: ProviderUsage): string | undefined {
		if (usage.windows.length === 0) return undefined;
		const pieces = usage.windows.map((w) => {
			const remaining = Math.max(0, Math.round(100 - w.usedPercent));
			const marker = w.limited ? ctx.ui.theme.fg("error", "!") : "";
			return `${ctx.ui.theme.fg("dim", `${w.label}:`)}${ctx.ui.theme.fg(severity(w.usedPercent), `${remaining}%`)}${marker}`;
		});
		return `${ctx.ui.theme.fg("dim", providerLabel(usage.provider))} ${pieces.join(" ")}`;
	}

	function checkWarnings(ctx: ExtensionContext, usage: ProviderUsage): void {
		const risky = usage.windows.filter((w) => w.usedPercent >= WARN_PERCENT);
		if (risky.length === 0) {
			turnWarned = false;
			return;
		}
		// One warning per turn: the footer keeps showing current headroom,
		// the notification does not repeat while the user reads the response.
		if (turnWarned) return;
		turnWarned = true;
		const level = risky.some((w) => w.usedPercent >= ERROR_PERCENT) ? "error" : "warning";
		const lines = risky.map(
			(w) => `- ${w.label}: ${Math.round(w.usedPercent)}% used, resets in ${formatTimeRemaining(w.resetsAt)}`,
		);
		if (!ctx.hasUI) return;
		ctx.ui.notify(`${providerLabel(usage.provider)} quota warning:\n${lines.join("\n")}`, level);
	}

	/**
	 * Fetch usage for a provider, deduplicating concurrent callers. The
	 * result is cached here (not in refresh) so it survives generation
	 * bumps: a forced refresh that awaits a settling fetch still sees it.
	 */
	function fetchUsage(
		provider: QuotaProvider,
		ctx: ExtensionContext,
	): Promise<ProviderUsage | { error: string }> {
		const existing = inFlight.get(provider);
		if (existing) return existing;

		const promise = (async () => {
			try {
				const result =
					provider === "openai-codex"
						? await fetchCodexUsage()
						: await fetchZenUsage(safeModel(ctx)?.baseUrl, opencodeGoKey());
				if (!("error" in result)) cache.set(provider, { at: Date.now(), usage: result });
				return result;
			} finally {
				inFlight.delete(provider);
			}
		})();
		inFlight.set(provider, promise);
		return promise;
	}

	async function refresh(ctx: ExtensionContext, options?: { force?: boolean }): Promise<void> {
		const requestGeneration = generation;
		const provider = quotaProviderOf(ctx);

		// Local/no-quota provider (e.g. ollama, llama-swap): nothing to show.
		if (!provider) {
			stopTimer();
			turnWarned = false;
			cache.clear();
			setStatusSafely(ctx, undefined);
			return;
		}

		// No footer to render in print/JSON modes; don't poll in the background.
		if (!ctx.hasUI) {
			stopTimer();
			return;
		}

		const cached = cache.get(provider);
		if (!options?.force && cached && Date.now() - cached.at < CACHE_TTL_MS) {
			setStatusSafely(ctx, formatFooter(ctx, cached.usage));
			// Re-armed by turn_start: the cached window is recent enough to
			// decide whether this turn still deserves its one warning.
			checkWarnings(ctx, cached.usage);
			return;
		}

		try {
			const result = await fetchUsage(provider, ctx);
			// The session or model changed while fetching: don't write stale UI.
			// The cache entry is still valid and a later refresh will use it.
			if (requestGeneration !== generation || currentContext !== ctx) return;
			if ("error" in result) {
				setStatusSafely(ctx, ctx.ui.theme.fg("warning", "usage unavailable"));
				return;
			}
			setStatusSafely(ctx, formatFooter(ctx, result));
			checkWarnings(ctx, result);
		} catch {
			if (requestGeneration === generation && currentContext === ctx) {
				setStatusSafely(ctx, ctx.ui.theme.fg("warning", "usage unavailable"));
			}
		}
	}

	pi.registerCommand("quotas", {
		description: "Display remaining usage/quota for the active provider",
		handler: async (_args, ctx) => {
			const provider = quotaProviderOf(ctx);
			if (!provider) {
				if (ctx.hasUI) {
					ctx.ui.notify(`No quota source for provider "${safeModel(ctx)?.provider ?? "unknown"}"`, "info");
				}
				return;
			}
			const result = await fetchUsage(provider, ctx);
			if (!ctx.hasUI) return;
			if ("error" in result) {
				ctx.ui.notify(`${providerLabel(provider)} usage: ${result.error}`, "warning");
				return;
			}
			const lines = result.windows.map(
				(w) =>
					`${w.label}: ${Math.round(w.usedPercent)}% used (${Math.max(0, Math.round(100 - w.usedPercent))}% left), resets in ${formatTimeRemaining(w.resetsAt)}${w.limited ? " [rate-limited]" : ""}`,
			);
			if (result.credits) {
				lines.push(
					`Credits: $${result.credits.balance.toFixed(2)}${result.credits.approxLocalMessages ? ` (~${result.credits.approxLocalMessages} local msgs)` : ""}`,
				);
			}
			if (result.spendCapReached) lines.push("Spend cap: REACHED");
			ctx.ui.notify([providerLabel(provider), ...lines].join("\n") || "No quota data", "info");
		},
	});

	pi.on("session_start", (_event, ctx) => {
		currentContext = ctx;
		generation++;
		turnWarned = false;
		if (!quotaProviderOf(ctx)) {
			stopTimer();
			cache.clear();
			setStatusSafely(ctx, undefined);
			return;
		}
		lastRenderedStatus = "__reset__";
		startTimer();
		void refresh(ctx).catch(() => undefined);
	});

	pi.on("turn_start", (_event, ctx) => {
		// New user message: the previous warning (if any) has scrolled out of
		// view, so allow one new warning during this turn.
		turnWarned = false;
		currentContext = ctx;
	});

	pi.on("turn_end", (_event, ctx) => {
		currentContext = ctx;
		const provider = quotaProviderOf(ctx);
		if (!provider) return;
		void refresh(ctx).catch(() => undefined);
	});

	pi.on("model_select", (_event, ctx) => {
		currentContext = ctx;
		generation++;
		turnWarned = false;
		if (!quotaProviderOf(ctx)) {
			// Left a quota provider: stop polling, clear status, re-arm later.
			stopTimer();
			cache.clear();
			setStatusSafely(ctx, undefined);
			return;
		}
		lastRenderedStatus = "__reset__";
		startTimer();
		void refresh(ctx, { force: true }).catch(() => undefined);
	});

	pi.on("session_shutdown", (_event, ctx) => {
		currentContext = undefined;
		generation++;
		stopTimer();
		turnWarned = false;
		cache.clear();
		inFlight.clear();
		setStatusSafely(ctx, undefined);
		lastRenderedStatus = undefined;
	});
}