/**
 * pi-kagi — Kagi web search, summarize, and FastGPT tools for pi.
 *
 * Set KAGI_API_KEY in your environment to enable.
 * Get a key at: https://kagi.com/settings?p=api
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Text } from "@mariozechner/pi-tui";
import {
	DEFAULT_MAX_BYTES,
	DEFAULT_MAX_LINES,
	formatSize,
	truncateHead,
	type TruncationResult,
} from "@mariozechner/pi-coding-agent";
import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { Type } from "typebox";
import {
	kagiSearch,
	kagiSummarize,
	kagiFastGPT,
	getApiKey,
	getKeySource,
	isConfigured,
	clearKeyCache,
	type KagiSearchResult,
} from "./kagi-api.ts";

// ─── Shared ─────────────────────────────────────────────────────────────────

function missingKeyError(tool: string) {
	return {
		content: [
			{
				type: "text" as const,
				text: `Kagi API key not configured. Set one of:\n  • KAGI_API_KEY env var\n  • KAGI_API_KEY_FILE env var (path to key file)\n  • ~/.config/pi/kagi-api-key file\nGet a key at https://kagi.com/settings?p=api`,
			},
		],
		details: { error: "missing_api_key" },
		isError: true,
	};
}

function truncateOutput(output: string): {
	text: string;
	truncation?: TruncationResult;
	fullOutputPath?: string;
} {
	const truncation = truncateHead(output, {
		maxLines: DEFAULT_MAX_LINES,
		maxBytes: DEFAULT_MAX_BYTES,
	});

	let text = truncation.content;
	let fullOutputPath: string | undefined;

	if (truncation.truncated) {
		const tempDir = mkdtempSync(join(tmpdir(), "pi-kagi-"));
		const tempFile = join(tempDir, "output.txt");
		writeFileSync(tempFile, output);

		text += `\n\n[Output truncated: showing ${truncation.outputLines} of ${truncation.totalLines} lines`;
		text += ` (${formatSize(truncation.outputBytes)} of ${formatSize(truncation.totalBytes)}).`;
		text += ` Full output saved to: ${tempFile}]`;

		fullOutputPath = tempFile;
	}

	return { text, truncation: truncation.truncated ? truncation : undefined, fullOutputPath };
}

// ─── Web Search ─────────────────────────────────────────────────────────────

const WEB_SEARCH_DESCRIPTION = `Search the web for real-time information using one or more queries via Kagi. Returns ranked results with titles, URLs, and snippets.

When to use:
- Looking up documentation, APIs, libraries, or error messages
- Answering questions about recent events or data beyond your training cutoff
- Verifying assumptions or checking updated best practices

Tips:
- Write concise, keyword-focused queries — include the current year for time-sensitive topics
- Use multiple queries to cover different angles of a broad question
- Prefer specific technical terms over natural language for code/docs searches

After using search results, include a "Sources" section with markdown links.`;

const WebSearchParams = Type.Object({
	queries: Type.Array(Type.String({ description: "A search query" }), {
		description: "One or more concise, keyword-focused search queries",
	}),
});

interface WebSearchDetails {
	queries: string[];
	resultCount: number;
	results?: KagiSearchResult[];
	truncation?: TruncationResult;
	fullOutputPath?: string;
	error?: string;
}

function formatSearchResults(results: KagiSearchResult[]): string {
	return results
		.map(
			(r, i) =>
				`${i + 1}. ${r.title}\n   ${r.url}${r.snippet ? `\n   ${r.snippet}` : ""}`,
		)
		.join("\n\n");
}

function createWebSearchTool() {
	return {
		name: "kagi_search",
		label: "Kagi Search",
		description: WEB_SEARCH_DESCRIPTION,
		parameters: WebSearchParams,

		async execute(
			_toolCallId: string,
			params: { queries: string[] },
			signal: AbortSignal | undefined,
			_onUpdate: any,
			_ctx: any,
		) {
			const apiKey = getApiKey();
			if (!apiKey) return missingKeyError("kagi_search");

			const response = await kagiSearch(params.queries, apiKey, signal);

			if (!response.ok) {
				return {
					content: [{ type: "text" as const, text: response.error }],
					details: { queries: params.queries, resultCount: 0, error: response.error } as WebSearchDetails,
					isError: true,
				};
			}

			if (response.results.length === 0) {
				return {
					content: [{ type: "text" as const, text: "No results found." }],
					details: { queries: params.queries, resultCount: 0 } as WebSearchDetails,
				};
			}

			const output = formatSearchResults(response.results);
			const { text, truncation, fullOutputPath } = truncateOutput(output);

			return {
				content: [{ type: "text" as const, text }],
				details: {
					queries: params.queries,
					resultCount: response.results.length,
					results: response.results,
					truncation,
					fullOutputPath,
				} as WebSearchDetails,
			};
		},

		renderCall(args: { queries: string[] }, theme: any) {
			let text = theme.fg("toolTitle", theme.bold("kagi_search "));
			text += theme.fg("accent", args.queries.map((q: string) => `"${q}"`).join(", "));
			return new Text(text, 0, 0);
		},

		renderResult(result: any, { expanded, isPartial }: { expanded: boolean; isPartial: boolean }, theme: any) {
			const details = result.details as WebSearchDetails | undefined;

			if (isPartial) return new Text(theme.fg("warning", "Searching..."), 0, 0);
			if (details?.error) return new Text(theme.fg("error", `Error: ${details.error}`), 0, 0);
			if (!details || details.resultCount === 0) return new Text(theme.fg("dim", "No results found"), 0, 0);

			let text = theme.fg("success", `${details.resultCount} results`);
			if (details.truncation?.truncated) text += theme.fg("warning", " (truncated)");

			if (expanded && details.results) {
				for (const r of details.results.slice(0, 10)) {
					text += `\n  ${theme.fg("accent", r.title)}`;
					text += `\n  ${theme.fg("dim", r.url)}`;
					if (r.snippet) text += `\n  ${theme.fg("muted", r.snippet)}`;
				}
				if (details.results.length > 10) {
					text += `\n  ${theme.fg("muted", `... and ${details.results.length - 10} more`)}`;
				}
				if (details.fullOutputPath) {
					text += `\n  ${theme.fg("dim", `Full output: ${details.fullOutputPath}`)}`;
				}
			}

			return new Text(text, 0, 0);
		},
	};
}

// ─── Summarize ──────────────────────────────────────────────────────────────

const SUMMARIZE_DESCRIPTION = `Summarize content from a URL using Kagi's Universal Summarizer. Works with web pages, PDFs, videos, podcasts, and more.

When to use:
- Digesting long documentation, release notes, or changelogs
- Getting key points from a video/podcast transcript
- Summarizing a PDF or technical paper`;

const SummarizeParams = Type.Object({
	url: Type.String({ description: "URL to summarize" }),
	summary_type: Type.Optional(
		Type.Union([Type.Literal("summary"), Type.Literal("takeaway")], {
			description: '"summary" for paragraph prose (default), "takeaway" for bullet points',
		}),
	),
	engine: Type.Optional(
		Type.Union([Type.Literal("cecil"), Type.Literal("agnes")], {
			description: '"cecil" (default, fast general-purpose) or "agnes" (formal, technical, analytical)',
		}),
	),
	target_language: Type.Optional(
		Type.String({
			description: 'Language code for output (e.g., "EN", "DE", "JA"). Defaults to document language.',
		}),
	),
});

interface SummarizeDetails {
	url: string;
	summaryType: string;
	engine: string;
	tokens: number;
	truncation?: TruncationResult;
	fullOutputPath?: string;
	error?: string;
}

function createSummarizeTool() {
	return {
		name: "summarize",
		label: "Summarize",
		description: SUMMARIZE_DESCRIPTION,
		parameters: SummarizeParams,

		async execute(
			_toolCallId: string,
			params: { url: string; summary_type?: "summary" | "takeaway"; engine?: "cecil" | "agnes"; target_language?: string },
			signal: AbortSignal | undefined,
			_onUpdate: any,
			_ctx: any,
		) {
			const apiKey = getApiKey();
			if (!apiKey) return missingKeyError("summarize");

			const summaryType = params.summary_type ?? "summary";
			const engine = params.engine ?? "cecil";

			const response = await kagiSummarize(params.url, apiKey, {
				summaryType,
				engine,
				targetLanguage: params.target_language,
			}, signal);

			if (!response.ok) {
				return {
					content: [{ type: "text" as const, text: response.error }],
					details: { url: params.url, summaryType, engine, tokens: 0, error: response.error } as SummarizeDetails,
					isError: true,
				};
			}

			const { text, truncation, fullOutputPath } = truncateOutput(response.output);

			return {
				content: [{ type: "text" as const, text }],
				details: {
					url: params.url,
					summaryType,
					engine,
					tokens: response.tokens,
					truncation,
					fullOutputPath,
				} as SummarizeDetails,
			};
		},

		renderCall(args: { url: string }, theme: any) {
			const display = args.url.length > 60 ? args.url.slice(0, 57) + "..." : args.url;
			let text = theme.fg("toolTitle", theme.bold("summarize "));
			text += theme.fg("accent", display);
			return new Text(text, 0, 0);
		},

		renderResult(result: any, { expanded, isPartial }: { expanded: boolean; isPartial: boolean }, theme: any) {
			const details = result.details as SummarizeDetails | undefined;

			if (isPartial) return new Text(theme.fg("warning", "Summarizing..."), 0, 0);
			if (details?.error) return new Text(theme.fg("error", `Error: ${details.error}`), 0, 0);

			let text = theme.fg("success", `${details?.tokens ?? 0} tokens`);
			if (details?.truncation?.truncated) text += theme.fg("warning", " (truncated)");

			if (expanded) {
				const textContent = result.content.find((c: any) => c.type === "text")?.text || "";
				const preview = textContent.length > 400 ? textContent.slice(0, 400) + "..." : textContent;
				text += "\n" + theme.fg("dim", preview);
			}

			return new Text(text, 0, 0);
		},
	};
}

// ─── FastGPT ────────────────────────────────────────────────────────────────

const FASTGPT_DESCRIPTION = `Get an AI-generated answer to a question using Kagi's FastGPT. Returns a concise answer with source references.

When to use:
- Quick factual questions that need a direct answer
- Getting an AI-summarized answer with citations
- When you want a synthesized answer rather than raw search results`;

const FastGPTParams = Type.Object({
	query: Type.String({ description: "Question or query to answer" }),
});

interface FastGPTDetails {
	query: string;
	referenceCount: number;
	references?: Array<{ title: string; snippet: string; url: string }>;
	truncation?: TruncationResult;
	fullOutputPath?: string;
	error?: string;
}

function createFastGPTTool() {
	return {
		name: "fastgpt",
		label: "FastGPT",
		description: FASTGPT_DESCRIPTION,
		parameters: FastGPTParams,

		async execute(
			_toolCallId: string,
			params: { query: string },
			signal: AbortSignal | undefined,
			_onUpdate: any,
			_ctx: any,
		) {
			const apiKey = getApiKey();
			if (!apiKey) return missingKeyError("fastgpt");

			const response = await kagiFastGPT(params.query, apiKey, signal);

			if (!response.ok) {
				return {
					content: [{ type: "text" as const, text: response.error }],
					details: { query: params.query, referenceCount: 0, error: response.error } as FastGPTDetails,
					isError: true,
				};
			}

			let output = response.output;
			if (response.references.length > 0) {
				output += "\n\n### References\n";
				for (const ref of response.references) {
					output += `- [${ref.title}](${ref.url})`;
					if (ref.snippet) output += ` — ${ref.snippet}`;
					output += "\n";
				}
			}

			const { text, truncation, fullOutputPath } = truncateOutput(output);

			return {
				content: [{ type: "text" as const, text }],
				details: {
					query: params.query,
					referenceCount: response.references.length,
					references: response.references,
					truncation,
					fullOutputPath,
				} as FastGPTDetails,
			};
		},

		renderCall(args: { query: string }, theme: any) {
			const display = args.query.length > 50 ? args.query.slice(0, 47) + "..." : args.query;
			let text = theme.fg("toolTitle", theme.bold("fastgpt "));
			text += theme.fg("accent", `"${display}"`);
			return new Text(text, 0, 0);
		},

		renderResult(result: any, { expanded, isPartial }: { expanded: boolean; isPartial: boolean }, theme: any) {
			const details = result.details as FastGPTDetails | undefined;

			if (isPartial) return new Text(theme.fg("warning", "Thinking..."), 0, 0);
			if (details?.error) return new Text(theme.fg("error", `Error: ${details.error}`), 0, 0);

			let text = theme.fg("success", `${details?.referenceCount ?? 0} references`);
			if (details?.truncation?.truncated) text += theme.fg("warning", " (truncated)");

			if (expanded) {
				const textContent = result.content.find((c: any) => c.type === "text")?.text || "";
				const preview = textContent.length > 400 ? textContent.slice(0, 400) + "..." : textContent;
				text += "\n" + theme.fg("dim", preview);
			}

			return new Text(text, 0, 0);
		},
	};
}

// ─── Extension entrypoint ───────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
	pi.registerTool(createWebSearchTool());
	pi.registerTool(createSummarizeTool());
	pi.registerTool(createFastGPTTool());

	// ── Commands ────────────────────────────────────────────────────────────

	pi.registerCommand("kagi-status", {
		description: "Show Kagi API key configuration and status",
		handler: async (_args, ctx) => {
			const key = getApiKey();
			const source = getKeySource();
			const configured = !!key;

			const lines: string[] = [
				"## Kagi Extension Status",
				"",
				`API Key: ${configured ? "✓ configured" : "✗ not configured"}`,
				`Source:  ${source}`,
				"",
				"Tools:",
				`  • kagi_search  — Web search via Kagi ${configured ? "✓" : "✗"}`,
				`  • summarize    — URL summarizer ${configured ? "✓" : "✗"}`,
				`  • fastgpt      — AI answers with citations ${configured ? "✓" : "✗"}`,
			];

			if (!configured) {
				lines.push("");
				lines.push("Configure via one of:");
				lines.push("  • KAGI_API_KEY=your_key          (direct key)");
				lines.push("  • KAGI_API_KEY=!sops -d file     (shell command)");
				lines.push("  • KAGI_API_KEY=MY_ENV_VAR        (env var lookup)");
				lines.push("  • KAGI_API_KEY_FILE=/path/to/key (file path)");
				lines.push("  • ~/.config/pi/kagi-api-key      (default file)");
				lines.push("");
				lines.push("Get a key at https://kagi.com/settings?p=api");
			}

			ctx.ui.notify(lines.join("\n"), configured ? "success" : "warning");
		},
	});

	pi.registerCommand("kagi-reload", {
		description: "Re-resolve the Kagi API key (use after key rotation)",
		handler: async (_args, ctx) => {
			clearKeyCache();
			const configured = isConfigured();
			ctx.ui.notify(
				configured
					? `Kagi API key reloaded from: ${getKeySource()}`
					: "Kagi API key not found after reload",
				configured ? "success" : "error",
			);
		},
	});

	// ── Session start ───────────────────────────────────────────────────────

	pi.on("session_start", async (_event, ctx) => {
		if (!getApiKey()) {
			ctx.ui.notify(
				"Kagi tools disabled. Set KAGI_API_KEY, KAGI_API_KEY_FILE, or ~/.config/pi/kagi-api-key",
				"warning",
			);
		}
		try {
			ctx.ui.setStatus("kagi", `kagi: ${isConfigured() ? "✓" : "✗"}`);
		} catch {}
	});
}
