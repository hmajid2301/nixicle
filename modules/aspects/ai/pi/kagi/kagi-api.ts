/**
 * Kagi API client — search, summarize, and FastGPT.
 * Uses the official Kagi API (https://kagi.com/api) with a bot token.
 */

const KAGI_SEARCH_URL = "https://kagi.com/api/v0/search";
const KAGI_SUMMARIZE_URL = "https://kagi.com/api/v0/summarize";
const KAGI_FASTGPT_URL = "https://kagi.com/api/v0/fastgpt";

// ─── Types ──────────────────────────────────────────────────────────────────

export interface KagiSearchResult {
	title: string;
	url: string;
	snippet: string;
}

export interface KagiSearchSuccess {
	ok: true;
	results: KagiSearchResult[];
}

export interface KagiSearchError {
	ok: false;
	error: string;
}

export type KagiSearchResponse = KagiSearchSuccess | KagiSearchError;

export interface KagiSummarizeSuccess {
	ok: true;
	output: string;
	tokens: number;
}

export interface KagiSummarizeError {
	ok: false;
	error: string;
}

export type KagiSummarizeResponse = KagiSummarizeSuccess | KagiSummarizeError;

export interface KagiFastGPTSuccess {
	ok: true;
	output: string;
	references: { title: string; snippet: string; url: string }[];
}

export interface KagiFastGPTError {
	ok: false;
	error: string;
}

export type KagiFastGPTResponse = KagiFastGPTSuccess | KagiFastGPTError;

// ─── Internal API types ────────────────────────────────────────────────────

interface KagiApiSearchResult {
	t: number; // 0 = search result
	title?: string;
	url?: string;
	snippet?: string;
}

interface KagiApiSearchResponse {
	meta?: { id?: string; ms?: number };
	data?: KagiApiSearchResult[];
	error?: Array<{ code: number; msg: string }>;
}

interface KagiApiSummarizeResponse {
	meta?: { id?: string; ms?: number };
	data?: { output?: string; tokens?: number };
	error?: Array<{ code: number; msg: string }>;
}

interface KagiApiFastGPTResponse {
	meta?: { id?: string; ms?: number };
	data?: {
		output?: string;
		references?: Array<{ title: string; snippet: string; url: string }>;
	};
	error?: Array<{ code: number; msg: string }>;
}

// ─── API Key resolution ─────────────────────────────────────────────────────

import * as nodeFs from "node:fs";
import * as nodePath from "node:path";
import { execSync } from "node:child_process";

let _cachedApiKey: string | undefined;
let _cachedKeySource: string | undefined;

// ── Shell command credential resolution ───────────────────────────────────
// Supports "!command" syntax: "!sops -d secrets.yaml" runs the command
// and uses the trimmed stdout as the API key. Cached for session lifetime.
const COMMAND_TIMEOUT_MS = 5_000;
const commandValueCache = new Map<string, { value?: string; error?: string }>();

function resolveShellCommand(cmd: string): string | undefined {
	const cached = commandValueCache.get(cmd);
	if (cached) {
		if (cached.error) return undefined;
		return cached.value;
	}
	try {
		const output = execSync(cmd, {
			encoding: "utf-8",
			stdio: ["ignore", "pipe", "pipe"],
			timeout: COMMAND_TIMEOUT_MS,
		}).trim();
		const value = output.length > 0 ? output : undefined;
		commandValueCache.set(cmd, { value });
		return value;
	} catch (err) {
		commandValueCache.set(cmd, { error: (err as Error).message });
		return undefined;
	}
}

/**
 * Resolve Kagi API key from (in order):
 * 1. KAGI_API_KEY env var (direct key, "!command" for shell, or "ENV_VAR" for lookup)
 * 2. KAGI_API_KEY_FILE env var (path to file containing key, e.g. sops secret)
 * 3. ~/.config/pi/kagi-api-key file
 */
export function getApiKey(): string | undefined {
	if (_cachedApiKey) return _cachedApiKey;
	_cachedKeySource = undefined;

	// 1. Direct env var (supports "!command" shell resolution)
	const envKey = process.env.KAGI_API_KEY;
	if (envKey) {
		let resolved: string | undefined;
		if (envKey.startsWith("!")) {
			resolved = resolveShellCommand(envKey.slice(1));
			_cachedKeySource = `shell:${envKey.slice(1, 40)}${envKey.length > 40 ? "..." : ""}`;
		} else if (/^[A-Z][A-Z0-9_]*$/.test(envKey)) {
			// Looks like an env var name — try to resolve it
			resolved = process.env[envKey];
			_cachedKeySource = resolved ? `env:${envKey}` : `env:${envKey} (unset)`;
		} else {
			resolved = envKey;
			_cachedKeySource = "env:KAGI_API_KEY (literal)";
		}
		if (resolved) {
			_cachedApiKey = resolved;
			return resolved;
		}
	}

	// 2. File from env var (sops secret path)
	const keyFilePath = process.env.KAGI_API_KEY_FILE;
	if (keyFilePath) {
		try {
			const key = nodeFs.readFileSync(keyFilePath, "utf-8").trim();
			if (key) {
				_cachedApiKey = key;
				_cachedKeySource = `file:${keyFilePath}`;
				return key;
			}
		} catch {
			// file not readable
		}
	}

	// 3. Default file location
	const defaultKeyFile = nodePath.join(
		process.env.XDG_CONFIG_HOME ?? nodePath.join(process.env.HOME ?? "/tmp", ".config"),
		"pi",
		"kagi-api-key",
	);
	try {
		const key = nodeFs.readFileSync(defaultKeyFile, "utf-8").trim();
		if (key) {
			_cachedApiKey = key;
			_cachedKeySource = `file:${defaultKeyFile}`;
			return key;
		}
	} catch {
		// file doesn't exist
	}

	return undefined;
}

/** Get the source description of the resolved API key (for status display). */
export function getKeySource(): string {
	return _cachedKeySource ?? "not configured";
}

/** Check if API key is available without triggering resolution side effects. */
export function isConfigured(): boolean {
	return !!getApiKey();
}

/** Invalidate cached key so next call re-resolves (e.g. after key rotation). */
export function clearKeyCache(): void {
	_cachedApiKey = undefined;
	_cachedKeySource = undefined;
}

// ─── Helpers ────────────────────────────────────────────────────────────────

/** Sanitize API error text — strip potential secrets (tokens, keys). */
function sanitizeError(status: number, raw: string): string {
	const safe = raw
		.replace(/(bearer|token|authorization)\s+[\w.\/-]{8,}/gi, "$1 [redacted]")
		.replace(/(api[-_]?key|secret|password)["']?\s*[:=]\s*["']?[\w.\/-]{8,}/gi, "[redacted]")
		.replace(/"(?:api[-_]?key|apiKey|token|secret|password)"\s*:\s*"[^"']{8,}"/gi, '"[redacted]"')
		.slice(0, 300);
	return `Kagi API error (${status}): ${safe}`;
}

function parseErrorResponse(status: number, raw: string): string {
	let message = `Kagi API returned HTTP ${status}`;
	try {
		const body = JSON.parse(raw) as { error?: Array<{ msg: string }> };
		if (body.error?.length) {
			message += `: ${body.error.map((e) => e.msg).join(", ")}`;
		}
	} catch {
		// use status alone — include sanitized raw text
		if (raw.length > 0) message += ` — ${sanitizeError(status, raw)}`;
	}
	return message;
}

// ── Rate limiting ──────────────────────────────────────────────────────────

const RATE_LIMIT_MS = 1_000; // 1s cooldown between Kagi API calls
let lastApiCall = 0;

async function waitForRateLimit(): Promise<void> {
	const now = Date.now();
	const wait = lastApiCall + RATE_LIMIT_MS - now;
	if (wait > 0) await new Promise((r) => setTimeout(r, wait));
	lastApiCall = Date.now();
}

async function kagiFetch(url: string, apiKey: string, init?: RequestInit): Promise<Response> {
	await waitForRateLimit();
	return fetch(url, {
		...init,
		headers: {
			Authorization: `Bot ${apiKey}`,
			"Content-Type": "application/json",
			...init?.headers,
		},
	});
}

// ─── Search ─────────────────────────────────────────────────────────────────

export async function kagiSearch(
	queries: string[],
	apiKey: string,
	signal?: AbortSignal,
): Promise<KagiSearchResponse> {
	const allResults: KagiSearchResult[] = [];

	for (const query of queries) {
		const url = new URL(KAGI_SEARCH_URL);
		url.searchParams.set("q", query);

		let response: Response;
		try {
			response = await kagiFetch(url.toString(), apiKey, { signal });
		} catch (err: unknown) {
			if ((err as Error).name === "AbortError") {
				return { ok: false, error: "Search cancelled" };
			}
			const message = err instanceof Error ? err.message : String(err);
			return { ok: false, error: `Network error searching for "${query}": ${message}` };
		}

		if (!response.ok) {
			return { ok: false, error: parseErrorResponse(response.status, await response.text()) };
		}

		let body: KagiApiSearchResponse;
		try {
			body = (await response.json()) as KagiApiSearchResponse;
		} catch {
			return { ok: false, error: `Failed to parse Kagi API response for "${query}"` };
		}

		if (body.error?.length) {
			return { ok: false, error: `Kagi API error: ${body.error.map((e) => e.msg).join(", ")}` };
		}

		if (body.data) {
			for (const item of body.data) {
				if (item.t === 0 && item.url && item.title) {
					allResults.push({
						title: item.title,
						url: item.url,
						snippet: item.snippet ?? "",
					});
				}
			}
		}
	}

	return { ok: true, results: allResults };
}

// ─── Summarize ──────────────────────────────────────────────────────────────

export async function kagiSummarize(
	url: string,
	apiKey: string,
	options?: {
		summaryType?: "summary" | "takeaway";
		engine?: "cecil" | "agnes";
		targetLanguage?: string;
	},
	signal?: AbortSignal,
): Promise<KagiSummarizeResponse> {
	const body: Record<string, string> = { url };
	if (options?.summaryType) body.summary_type = options.summaryType;
	if (options?.engine) body.engine = options.engine;
	if (options?.targetLanguage) body.target_language = options.targetLanguage;

	let response: Response;
	try {
		response = await kagiFetch(KAGI_SUMMARIZE_URL, apiKey, {
			method: "POST",
			body: JSON.stringify(body),
			signal,
		});
	} catch (err: unknown) {
		if ((err as Error).name === "AbortError") {
			return { ok: false, error: "Summarize cancelled" };
		}
		const message = err instanceof Error ? err.message : String(err);
		return { ok: false, error: `Network error summarizing "${url}": ${message}` };
	}

	if (!response.ok) {
		return { ok: false, error: parseErrorResponse(response.status, await response.text()) };
	}

	let parsed: KagiApiSummarizeResponse;
	try {
		parsed = (await response.json()) as KagiApiSummarizeResponse;
	} catch {
		return { ok: false, error: `Failed to parse Kagi API response for "${url}"` };
	}

	if (parsed.error?.length) {
		return { ok: false, error: `Kagi API error: ${parsed.error.map((e) => e.msg).join(", ")}` };
	}

	if (!parsed.data?.output) {
		return { ok: false, error: `Kagi API returned no summary for "${url}"` };
	}

	return { ok: true, output: parsed.data.output, tokens: parsed.data.tokens ?? 0 };
}

// ─── FastGPT ────────────────────────────────────────────────────────────────

export async function kagiFastGPT(
	query: string,
	apiKey: string,
	signal?: AbortSignal,
): Promise<KagiFastGPTResponse> {
	const url = new URL(KAGI_FASTGPT_URL);
	url.searchParams.set("query", query);

	let response: Response;
	try {
		response = await kagiFetch(url.toString(), apiKey, { signal });
	} catch (err: unknown) {
		if ((err as Error).name === "AbortError") {
			return { ok: false, error: "FastGPT cancelled" };
		}
		const message = err instanceof Error ? err.message : String(err);
		return { ok: false, error: `Network error querying FastGPT: ${message}` };
	}

	if (!response.ok) {
		return { ok: false, error: parseErrorResponse(response.status, await response.text()) };
	}

	let parsed: KagiApiFastGPTResponse;
	try {
		parsed = (await response.json()) as KagiApiFastGPTResponse;
	} catch {
		return { ok: false, error: "Failed to parse Kagi FastGPT response" };
	}

	if (parsed.error?.length) {
		return { ok: false, error: `Kagi API error: ${parsed.error.map((e) => e.msg).join(", ")}` };
	}

	if (!parsed.data?.output) {
		return { ok: false, error: "Kagi FastGPT returned no output" };
	}

	return {
		ok: true,
		output: parsed.data.output,
		references: parsed.data.references ?? [],
	};
}
