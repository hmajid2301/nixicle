import { existsSync } from "node:fs";
import { mkdtemp, writeFile } from "node:fs/promises";
import { dirname, isAbsolute, join, resolve } from "node:path";
import { tmpdir } from "node:os";
import { Type } from "@mariozechner/pi-ai";
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

function findIndexedProject(start: string): string | undefined {
	let dir = resolve(start);
	while (true) {
		if (existsSync(join(dir, ".codegraph"))) return dir;
		const parent = dirname(dir);
		if (parent === dir) return undefined;
		dir = parent;
	}
}

function resolveCwd(baseCwd: string, projectPath?: string): string {
	if (!projectPath?.trim()) return baseCwd;
	return isAbsolute(projectPath) ? projectPath : resolve(baseCwd, projectPath);
}

async function formatOutput(text: string, details: Record<string, unknown>): Promise<ToolResult> {
	const truncation = truncateHead(text || "", {
		maxLines: DEFAULT_MAX_LINES,
		maxBytes: DEFAULT_MAX_BYTES,
	});

	const outDetails: Record<string, unknown> = {
		...details,
		truncated: truncation.truncated,
	};

	let resultText = truncation.content || "(no output)";
	if (truncation.truncated) {
		const dir = await mkdtemp(join(tmpdir(), "pi-codegraph-"));
		const fullOutputPath = join(dir, "output.txt");
		await withFileMutationQueue(fullOutputPath, async () => {
			await writeFile(fullOutputPath, text, "utf8");
		});
		outDetails.fullOutputPath = fullOutputPath;
		outDetails.truncation = truncation;
		resultText += `\n\n[Output truncated: showing ${truncation.outputLines} of ${truncation.totalLines} lines (${formatSize(truncation.outputBytes)} of ${formatSize(truncation.totalBytes)}). Full output saved to: ${fullOutputPath}]`;
	}

	return {
		content: [{ type: "text", text: resultText }],
		details: outDetails,
	};
}

async function runCodegraph(
	pi: ExtensionAPI,
	args: string[],
	cwd: string,
	timeout: number,
	details: Record<string, unknown>,
): Promise<ToolResult> {
	const result = await pi.exec("codegraph", args, { cwd, timeout });
	const stdout = result.stdout?.trim() ?? "";
	const stderr = result.stderr?.trim() ?? "";
	const combined = stdout || stderr || "(no output)";
	if (result.killed) throw new Error(`codegraph timed out after ${Math.round(timeout / 1000)}s`);
	if (result.code !== 0) throw new Error(combined);
	return await formatOutput(combined, {
		...details,
		args,
		cwd,
		exitCode: result.code,
	});
}

export default function codegraphExtension(pi: ExtensionAPI) {
	pi.on("before_agent_start", async () => {
		const cwd = pi.cwd ?? process.cwd();
		const indexedProject = findIndexedProject(cwd);
		const text = indexedProject
			? `[CODEGRAPH PREFERENCE]\nA .codegraph index is available for this project at ${indexedProject}.\nFor codebase exploration and structural questions, prefer codegraph_explore before grep/find/broad file reading.\nUse codegraph_node for a specific symbol or file, and codegraph_impact before refactors.\nTreat code returned by codegraph as already-read context. Only fall back to grep/read when you need live file verification, coverage outside the indexed project, or codegraph indicates stale/missing coverage.`
			: `[CODEGRAPH PREFERENCE]\nThe local codegraph CLI is installed. If you want structural exploration for this repo, run codegraph_init first, then prefer codegraph_explore over grep/find for codebase understanding. Until indexed, use normal tools.`;
		return {
			message: {
				role: "user",
				content: [{ type: "text", text }],
				display: false,
			},
		};
	});

	pi.registerTool({
		name: "codegraph_explore",
		label: "codegraph explore",
		description: "Explore an indexed codebase with codegraph. Prefer this over grep/find for structural questions and codebase understanding.",
		parameters: Type.Object({
			query: Type.String({ description: "Exploration query, e.g. 'how does auth reach the database?'" }),
			projectPath: Type.Optional(Type.String({ description: "Project path to run codegraph in (defaults to current cwd)" })),
		}),
		async execute(_id, params) {
			const cwd = resolveCwd(pi.cwd ?? process.cwd(), params.projectPath);
			return await runCodegraph(pi, ["explore", params.query], cwd, 120_000, {
				command: "explore",
				query: params.query,
				indexedProject: findIndexedProject(cwd),
			});
		},
	});

	pi.registerTool({
		name: "codegraph_status",
		label: "codegraph status",
		description: "Show codegraph index status for the current project.",
		parameters: Type.Object({
			projectPath: Type.Optional(Type.String({ description: "Project path to run codegraph in (defaults to current cwd)" })),
		}),
		async execute(_id, params) {
			const cwd = resolveCwd(pi.cwd ?? process.cwd(), params.projectPath);
			return await runCodegraph(pi, ["status"], cwd, 30_000, {
				command: "status",
				indexedProject: findIndexedProject(cwd),
			});
		},
	});

	pi.registerTool({
		name: "codegraph_init",
		label: "codegraph init",
		description: "Initialize a codegraph index for the current project.",
		parameters: Type.Object({
			projectPath: Type.Optional(Type.String({ description: "Project path to initialize (defaults to current cwd)" })),
		}),
		async execute(_id, params) {
			const cwd = resolveCwd(pi.cwd ?? process.cwd(), params.projectPath);
			return await runCodegraph(pi, ["init"], cwd, 300_000, {
				command: "init",
			});
		},
	});

	pi.registerTool({
		name: "codegraph_node",
		label: "codegraph node",
		description: "Read one symbol or file through codegraph with structural context.",
		parameters: Type.Object({
			target: Type.String({ description: "Symbol or file path to inspect" }),
			projectPath: Type.Optional(Type.String({ description: "Project path to run codegraph in (defaults to current cwd)" })),
		}),
		async execute(_id, params) {
			const cwd = resolveCwd(pi.cwd ?? process.cwd(), params.projectPath);
			return await runCodegraph(pi, ["node", params.target], cwd, 60_000, {
				command: "node",
				target: params.target,
				indexedProject: findIndexedProject(cwd),
			});
		},
	});

	pi.registerTool({
		name: "codegraph_impact",
		label: "codegraph impact",
		description: "Analyze the blast radius of changing a symbol before refactoring.",
		parameters: Type.Object({
			symbol: Type.String({ description: "Symbol to analyze" }),
			depth: Type.Optional(Type.Number({ description: "Traversal depth" })),
			projectPath: Type.Optional(Type.String({ description: "Project path to run codegraph in (defaults to current cwd)" })),
		}),
		async execute(_id, params) {
			const cwd = resolveCwd(pi.cwd ?? process.cwd(), params.projectPath);
			const args = ["impact", params.symbol];
			if (typeof params.depth === "number") args.push("--depth", String(params.depth));
			return await runCodegraph(pi, args, cwd, 60_000, {
				command: "impact",
				symbol: params.symbol,
				depth: params.depth,
				indexedProject: findIndexedProject(cwd),
			});
		},
	});
}
