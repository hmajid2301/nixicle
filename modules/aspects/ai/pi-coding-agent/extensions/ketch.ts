import { spawn } from "node:child_process";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { StringEnum, Type } from "@mariozechner/pi-ai";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import {
	DEFAULT_MAX_BYTES,
	DEFAULT_MAX_LINES,
	formatSize,
	truncateHead,
	withFileMutationQueue,
} from "@mariozechner/pi-coding-agent";

type ToolResult = {
	content: Array<{ type: "text"; text: string }>;
	details: Record<string, unknown>;
};

const KETCH_TIMEOUT_MS = 60_000; // 60s default; override via KETCH_TIMEOUT env

function getTimeout(): number {
	const env = process.env.KETCH_TIMEOUT;
	if (env) {
		const n = Number(env);
		if (Number.isFinite(n) && n > 0) return n * 1000;
	}
	return KETCH_TIMEOUT_MS;
}

async function runKetch(
	args: string[],
	cwd: string,
	externalSignal?: AbortSignal,
): Promise<{ stdout: string; stderr: string; exitCode: number | null; signalCode: NodeJS.Signals | null }> {
	const ac = new AbortController();
	const timeout = setTimeout(() => ac.abort(), getTimeout());

	// Forward external abort to our controller
	const onExternalAbort = () => ac.abort();
	externalSignal?.addEventListener("abort", onExternalAbort, { once: true });

	try {
		return await new Promise((resolve, reject) => {
			if (ac.signal.aborted) {
				reject(new Error("ketch timed out"));
				return;
			}

			const child = spawn("ketch", args, {
				cwd,
				env: process.env,
				stdio: ["ignore", "pipe", "pipe"],
				signal: ac.signal,
			});

			let stdout = "";
			let stderr = "";

			child.stdout.on("data", (chunk) => {
				stdout += chunk.toString();
			});
			child.stderr.on("data", (chunk) => {
				stderr += chunk.toString();
			});

			child.on("error", (error: NodeJS.ErrnoException) => {
				if (error.code === "ENOENT") {
					reject(new Error("ketch binary not found on PATH. Install or expose ketch before using this extension."));
					return;
				}
				if (error.name === "AbortError") {
					reject(new Error(`ketch timed out after ${getTimeout() / 1000}s`));
					return;
				}
				reject(error);
			});

			child.on("close", (exitCode, signalCode) => {
				resolve({ stdout, stderr, exitCode, signalCode });
			});
		});
	} finally {
		clearTimeout(timeout);
		externalSignal?.removeEventListener("abort", onExternalAbort);
	}
}

async function formatOutput(
	text: string,
	prefix: Record<string, unknown>,
): Promise<ToolResult> {
	const truncation = truncateHead(text || "", {
		maxLines: DEFAULT_MAX_LINES,
		maxBytes: DEFAULT_MAX_BYTES,
	});

	const details: Record<string, unknown> = {
		...prefix,
		truncated: truncation.truncated,
	};

	let resultText = truncation.content || "(no output)";

	if (truncation.truncated) {
		const dir = await mkdtemp(join(tmpdir(), "pi-ketch-"));
		const fullOutputPath = join(dir, "output.txt");
		await withFileMutationQueue(fullOutputPath, async () => {
			await writeFile(fullOutputPath, text, "utf8");
		});
		details.fullOutputPath = fullOutputPath;
		details.truncation = truncation;
		resultText += `\n\n[Output truncated: showing ${truncation.outputLines} of ${truncation.totalLines} lines (${formatSize(truncation.outputBytes)} of ${formatSize(truncation.totalBytes)}). Full output saved to: ${fullOutputPath}]`;
	}

	return {
		content: [{ type: "text", text: resultText }],
		details,
	};
}

async function execTool(
	command: string,
	args: string[],
	cwd: string,
	signal: AbortSignal | undefined,
): Promise<ToolResult> {
	const result = await runKetch([command, ...args], cwd, signal);
	const combined = result.stdout.trim() || result.stderr.trim();
	if (result.exitCode === null) {
		throw new Error(combined || `Process killed by signal${result.signalCode ? ` ${result.signalCode}` : ""}`);
	}
	if (result.exitCode !== 0) {
		throw new Error(combined || `ketch ${command} failed with exit code ${result.exitCode}`);
	}
	return await formatOutput(combined, {
		command,
		args,
		exitCode: result.exitCode,
	});
}

export default function ketchExtension(pi: ExtensionAPI) {
	pi.on("before_agent_start", async () => {
		return {
			message: {
				role: "user",
				content: [{
					type: "text",
					text: `[KETCH RESEARCH PREFERENCE]
Use local ketch tools for external research: web pages, OSS code, and library docs.
- Web search: use ketch_search. Use scrape=true when you want full page content from results.
- Scrape URLs: use ketch_scrape for one or more URLs; it returns clean extracted content.
- Crawl sites: use ketch_crawl for broader discovery; use sitemap/background when useful and ketch_crawl_status to poll.
- Code search: use ketch_code for public OSS code examples.
- Library docs: use ketch_docs for version-aware library/framework docs.
- Structured output: prefer JSON-style workflows when structured output would help.
- The operator already configured search/code/docs backends and browser support; do not override backends unless you have a specific reason.
- JS-rendered pages are handled by ketch automatically.
Only use these tools when external information would materially help.`,
				}],
				display: false,
			},
		};
	});

	pi.registerTool({
		name: "ketch_search",
		label: "ketch web search",
		description: "Search the web with the local ketch CLI. Supports Brave, DuckDuckGo, or SearXNG via the operator's ketch config.",
		parameters: Type.Object({
			query: Type.String({ description: "Web search query" }),
			backend: Type.Optional(StringEnum(["brave", "ddg", "searxng"] as const, { description: "Optional web search backend override" })),
			limit: Type.Optional(Type.Number({ description: "Maximum results to return" })),
			scrape: Type.Optional(Type.Boolean({ description: "Fetch full content from each result" })),
		}),
		async execute(_toolCallId, params, signal, _onUpdate, ctx) {
			const args = [params.query];
			if (params.backend) args.push("--backend", params.backend);
			if (typeof params.limit === "number") args.push("--limit", String(params.limit));
			if (params.scrape) args.push("--scrape");
			return await execTool("search", args, ctx.cwd, signal);
		},
	});

	pi.registerTool({
		name: "ketch_code",
		label: "ketch code search",
		description: "Search open source code with the local ketch CLI using Sourcegraph or GitHub Code Search.",
		parameters: Type.Object({
			query: Type.String({ description: "Code search query" }),
			backend: Type.Optional(StringEnum(["sourcegraph", "github"] as const, { description: "Code search backend" })),
			lang: Type.Optional(Type.String({ description: "Optional language filter, e.g. go, ts, rust" })),
			limit: Type.Optional(Type.Number({ description: "Maximum results to return" })),
		}),
		async execute(_toolCallId, params, signal, _onUpdate, ctx) {
			const args = [params.query];
			if (params.backend) args.push("--backend", params.backend);
			if (params.lang) args.push("--lang", params.lang);
			if (typeof params.limit === "number") args.push("--limit", String(params.limit));
			return await execTool("code", args, ctx.cwd, signal);
		},
	});

	pi.registerTool({
		name: "ketch_docs",
		label: "ketch docs search",
		description: "Search library and framework docs with the local ketch CLI using Context7 or other configured docs backends.",
		parameters: Type.Object({
			query: Type.String({ description: "Docs search query" }),
			library: Type.Optional(Type.String({ description: "Optional library ID like /org/repo to skip resolution" })),
			resolve: Type.Optional(Type.Boolean({ description: "Resolve a library name instead of fetching docs" })),
			tokens: Type.Optional(Type.Number({ description: "Token budget for docs snippets" })),
			backend: Type.Optional(Type.String({ description: "Optional docs backend override" })),
		}),
		async execute(_toolCallId, params, signal, _onUpdate, ctx) {
			const args = [params.query];
			if (params.library) args.push("--library", params.library);
			if (params.resolve) args.push("--resolve");
			if (typeof params.tokens === "number") args.push("--tokens", String(params.tokens));
			if (params.backend) args.push("--backend", params.backend);
			return await execTool("docs", args, ctx.cwd, signal);
		},
	});

	pi.registerTool({
		name: "ketch_scrape",
		label: "ketch scrape",
		description: "Fetch one or more URLs with the local ketch CLI and return clean markdown extracted from the page.",
		parameters: Type.Object({
			urls: Type.Array(Type.String({ description: "URL to scrape" }), { minItems: 1, maxItems: 20 }),
			raw: Type.Optional(Type.Boolean({ description: "Return raw HTML instead of cleaned markdown" })),
			noCache: Type.Optional(Type.Boolean({ description: "Bypass ketch cache" })),
		}),
		async execute(_toolCallId, params, signal, _onUpdate, ctx) {
			let tempDir: string | undefined;
			try {
				tempDir = await mkdtemp(join(tmpdir(), "pi-ketch-scrape-"));
				const args = [...params.urls];
				if (params.raw) args.push("--raw");
				if (params.noCache) args.push("--no-cache");
				return await execTool("scrape", args, tempDir ?? ctx.cwd, signal);
			} finally {
				if (tempDir) {
					await rm(tempDir, { recursive: true, force: true });
				}
			}
		},
	});

	pi.registerTool({
		name: "ketch_crawl",
		label: "ketch crawl",
		description: "Crawl a site with the local ketch CLI using BFS or sitemap mode, optionally in the background.",
		parameters: Type.Object({
			url: Type.String({ description: "Seed URL or sitemap URL" }),
			depth: Type.Optional(Type.Number({ description: "Maximum BFS depth" })),
			concurrency: Type.Optional(Type.Number({ description: "Crawl worker count" })),
			sitemap: Type.Optional(Type.Boolean({ description: "Treat the URL as a sitemap" })),
			background: Type.Optional(Type.Boolean({ description: "Run in the background and return a crawl ID" })),
			noCache: Type.Optional(Type.Boolean({ description: "Bypass ketch cache" })),
		}),
		async execute(_toolCallId, params, signal, _onUpdate, ctx) {
			let tempDir: string | undefined;
			try {
				tempDir = await mkdtemp(join(tmpdir(), "pi-ketch-crawl-"));
				const args = [params.url];
				if (typeof params.depth === "number") args.push("--depth", String(params.depth));
				if (typeof params.concurrency === "number") args.push("--concurrency", String(params.concurrency));
				if (params.sitemap) args.push("--sitemap");
				if (params.background) args.push("--background");
				if (params.noCache) args.push("--no-cache");
				return await execTool("crawl", args, tempDir ?? ctx.cwd, signal);
			} finally {
				if (tempDir) {
					await rm(tempDir, { recursive: true, force: true });
				}
			}
		},
	});

	pi.registerTool({
		name: "ketch_crawl_status",
		label: "ketch crawl status",
		description: "Check status for all crawls or for a specific crawl ID using the local ketch CLI.",
		parameters: Type.Object({
			crawlId: Type.Optional(Type.String({ description: "Optional crawl ID to inspect" })),
		}),
		async execute(_toolCallId, params, signal, _onUpdate, ctx) {
			const args = ["status"];
			if (params.crawlId) args.push(params.crawlId);
			return await execTool("crawl", args, ctx.cwd, signal);
		},
	});

	pi.registerTool({
		name: "ketch_config",
		label: "ketch config",
		description: "Show effective local ketch configuration and available backends.",
		parameters: Type.Object({}),
		async execute(_toolCallId, _params, signal, _onUpdate, ctx) {
			return await execTool("config", [], ctx.cwd, signal);
		},
	});
}
