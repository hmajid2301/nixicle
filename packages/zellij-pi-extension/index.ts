/**
 * Zellij Pi Extension
 *
 * Full zellij integration: pane dumping, splits, tabs, floating panes,
 * pane highlighting, LLM-powered git worktree handoff, and zoxide navigation.
 *
 * Tools:
 *   zellij_list_sessions, zellij_list_tabs, zellij_list_panes,
 *   zellij_dump_pane, zellij_current_tab, zellij_new_pane
 *
 * Commands:
 *   /zv           — new right pane with fresh pi
 *   /zj           — new lower pane with fresh pi
 *   /zt           — new tab with fresh pi
 *   /zo <cmd>     — run shell command in right pane
 *   /zoh <cmd>    — run shell command in lower pane
 *   /zz <query>   — zoxide jump + pi in right pane
 *   /zzh <query>  — zoxide jump + pi in lower pane
 *   /zcv [note]   — continue task in right split (LLM handoff, optional worktree)
 *   /zch [note]   — continue task in lower split (LLM handoff, optional worktree)
 *   /zcv -c <branch> [--from <ref>] [note] — continue in new worktree
 *   /zellij       — session overview
 *
 * Pane Highlighting (settings.json):
 *   "zellij": { "paneHighlight": { "enabled": true, "doneBg": "#17352a" } }
 *
 * Floating Shortcuts (settings.json):
 *   "zellij": { "commands": { "zh": "hx", "zg": "lazygit" } }
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { serializeConversation } from "@mariozechner/pi-coding-agent";
import { Type, StringEnum, complete, convertToLlm } from "@mariozechner/pi-ai";
import { existsSync, readFileSync, mkdirSync } from "node:fs";
import { homedir } from "node:os";
import { join, dirname, basename, isAbsolute, resolve } from "node:path";
import { execFileSync } from "node:child_process";

// ── Constants ─────────────────────────────────────────────────────────────────

const ZELLIJ_TIMEOUT = 10_000;
const SETTINGS_PATH = join(homedir(), ".pi", "agent", "settings.json");

const HANDOFF_SYSTEM_PROMPT = `You are a context transfer assistant. Given a conversation history, git status, and the user's goal for a new session, generate a focused prompt that:

1. Summarizes relevant context from the conversation (decisions made, approaches taken, key findings)
2. Lists any relevant files that were discussed or modified
3. Clearly states the next task based on the user's goal
4. Is self-contained — the new session should be able to proceed without the old conversation
5. Includes any relevant git status information (modified/new files)

Format your response as a prompt the user can send to start the new session. Be concise but include all necessary context. Do not include any preamble like "Here's the prompt" — just output the prompt itself.

Example output format:
## Context
We've been working on X. Key decisions:
- Decision 1
- Decision 2

Files involved:
- path/to/file1.ts
- path/to/file2.ts

## Task
[Clear description of what to do next based on user's goal]`;

// ── Types ─────────────────────────────────────────────────────────────────────

type SplitDir = "right" | "down";
type PaneResult = { ok: true; paneId?: string } | { ok: false; error: string };

interface HighlightConfig {
	enabled: boolean;
	doneBg: string;
	doneFg?: string;
	workingBg?: string;
	workingFg?: string;
}

interface FloatingCmd {
	run: string;
	acceptArgs: boolean;
	description: string;
}

type ContinueRequest =
	| { mode: "handoff"; note?: string }
	| { mode: "worktree"; branch: string; fromRef?: string; note?: string };

// ── Helpers ────────────────────────────────────────────────────────────────────

function isInsideZellij(): boolean {
	return Boolean(process.env.ZELLIJ || process.env.ZELLIJ_SESSION_NAME || process.env.ZELLIJ_PANE_ID);
}

function normalizePaneId(v: string): string | undefined {
	const t = v.trim();
	if (/^(?:terminal|plugin)_\d+$/.test(t)) return t;
	if (/^\d+$/.test(t)) return `terminal_${t}`;
	return undefined;
}

function getLastLine(s: string): string | undefined {
	const lines = s.split(/\r?\n/).map((l) => l.trim()).filter(Boolean);
	return lines.length > 0 ? lines[lines.length - 1] : undefined;
}

function shellEscape(v: string): string {
	return `'${v.replace(/'/g, `'\\''`)}'`;
}

async function execZellij(pi: ExtensionAPI, args: string[]): Promise<{ ok: boolean; stdout: string; stderr: string; error?: string }> {
	const result = await pi.exec("zellij", args, { timeout: ZELLIJ_TIMEOUT });
	if (result.killed) return { ok: false, stdout: result.stdout, stderr: result.stderr, error: "zellij timed out" };
	if (result.code !== 0) return { ok: false, stdout: result.stdout, stderr: result.stderr, error: result.stderr.trim() || `zellij exited ${result.code}` };
	return { ok: true, stdout: result.stdout, stderr: result.stderr };
}

async function runZellij(pi: ExtensionAPI, args: string[], session?: string): Promise<string> {
	const env: Record<string, string> = {};
	if (session) env.ZELLIJ_SESSION_NAME = session;
	const result = await pi.exec("zellij", args, { env, timeout: ZELLIJ_TIMEOUT });
	if (result.code !== 0 && !result.killed) throw new Error(result.stderr || result.stdout);
	return result.stdout;
}

async function openSplit(pi: ExtensionAPI, dir: SplitDir, cmd: string): Promise<PaneResult> {
	if (!isInsideZellij()) return { ok: false, error: "Not inside a zellij session" };
	const r = await execZellij(pi, ["run", "--direction", dir, "--", "sh", "-lc", cmd]);
	if (!r.ok) return r;
	return { ok: true, paneId: normalizePaneId(getLastLine(r.stdout) ?? "") };
}

async function openFloating(pi: ExtensionAPI, cmd: string, name?: string): Promise<PaneResult> {
	if (!isInsideZellij()) return { ok: false, error: "Not inside a zellij session" };
	const args = ["run", "--floating", "--width", "90%", "--height", "90%", "-x", "5%", "-y", "5%"];
	if (name) args.push("--name", name);
	args.push("--", "sh", "-lc", cmd);
	const r = await execZellij(pi, args);
	if (!r.ok) return r;
	return { ok: true, paneId: normalizePaneId(getLastLine(r.stdout) ?? "") };
}

function buildPiCmd(cwd: string, opts?: { sessionFile?: string; prompt?: string }): string {
	const parts = ["cd", shellEscape(cwd), "&&", "exec", "pi"];
	if (opts?.sessionFile) parts.push("--session", shellEscape(opts.sessionFile));
	if (opts?.prompt?.trim()) parts.push(shellEscape(opts.prompt.trim()));
	return parts.join(" ");
}

function buildShellCmd(cwd: string, cmd: string): string {
	return ["cd", shellEscape(cwd), "&&", "exec", "sh", "-lc", shellEscape(cmd)].join(" ");
}

// ── Settings ──────────────────────────────────────────────────────────────────

function readSettings(): Record<string, unknown> {
	try { return JSON.parse(readFileSync(SETTINGS_PATH, "utf-8")); } catch { return {}; }
}

function loadHighlightConfig(): HighlightConfig {
	const s = readSettings();
	const z = (s["zellij"] ?? s["pi-zellij"] ?? s["pi-zv"]) as Record<string, unknown> | undefined;
	const ph = z?.["paneHighlight"] as Record<string, unknown> | undefined;
	if (!ph || typeof ph !== "object") return { enabled: false, doneBg: "#17352a" };
	return {
		enabled: ph.enabled === true,
		doneBg: (typeof ph.doneBg === "string" ? ph.doneBg : "#17352a"),
		doneFg: typeof ph.doneFg === "string" ? ph.doneFg : undefined,
		workingBg: typeof ph.workingBg === "string" ? ph.workingBg : undefined,
		workingFg: typeof ph.workingFg === "string" ? ph.workingFg : undefined,
	};
}

function loadFloatingCommands(): Map<string, FloatingCmd> {
	const result = new Map<string, FloatingCmd>();
	const s = readSettings();
	const z = (s["zellij"] ?? s["pi-zellij"] ?? s["pi-zv"]) as Record<string, unknown> | undefined;
	const cmds = z?.["commands"] as Record<string, unknown> | undefined;
	if (!cmds || typeof cmds !== "object") return result;
	const reserved = new Set(["zv","zj","zt","zo","zoh","zz","zzh","zcv","zch","zellij","help","quit","reload","settings","model","login","logout","review","compact","new","resume","session","tree","fork","name","export","share","copy","hotkeys","changelog","exit"]);
	for (const [name, val] of Object.entries(cmds)) {
		if (reserved.has(name) || !/^[a-z0-9][a-z0-9-]*$/i.test(name)) continue;
		if (typeof val === "string") {
			const run = val.trim();
			if (run) result.set(name, { run, acceptArgs: false, description: `Open ${run} in floating pane` });
		} else if (val && typeof val === "object" && !Array.isArray(val)) {
			const c = val as { run?: string; acceptArgs?: boolean; description?: string; disabled?: boolean };
			if (c.disabled) { result.delete(name); continue; }
			const run = (typeof c.run === "string" ? c.run.trim() : "");
			if (!run) continue;
			result.set(name, { run, acceptArgs: c.acceptArgs === true, description: c.description?.trim() || `Open ${run} in floating pane` });
		}
	}
	return result;
}

// ── Git ────────────────────────────────────────────────────────────────────────

async function getGitRoot(pi: ExtensionAPI, cwd: string): Promise<string | undefined> {
	try {
		const r = await pi.exec("git", ["rev-parse", "--show-toplevel"], { cwd, timeout: 5000 });
		return r.code === 0 ? r.stdout.trim() : undefined;
	} catch { return undefined; }
}

async function getGitBranch(pi: ExtensionAPI, cwd: string): Promise<string | undefined> {
	try {
		const r = await pi.exec("git", ["branch", "--show-current"], { cwd, timeout: 5000 });
		return r.code === 0 ? r.stdout.trim() || undefined : undefined;
	} catch { return undefined; }
}

async function getGitStatus(pi: ExtensionAPI, cwd: string, maxLines = 20): Promise<{ modified: string[]; newFiles: string[] } | undefined> {
	try {
		const r = await pi.exec("git", ["status", "--short", "--untracked-files=all"], { cwd, timeout: 5000 });
		if (r.code !== 0) return undefined;
		const lines = r.stdout.split("\n").map((l) => l.trimEnd()).filter((l) => l.trim()).slice(0, maxLines);
		const modified: string[] = [];
		const newFiles: string[] = [];
		for (const line of lines) {
			const code = line.slice(0, 2);
			const file = line.slice(3).trim();
			if (!file || file.startsWith(".pi/") || file.startsWith(".agents") || file.startsWith("node_modules")) continue;
			if (code === "??") newFiles.push(file);
			else if (/[MADRC]/.test(code)) modified.push(file);
		}
		return { modified, newFiles };
	} catch { return undefined; }
}

async function branchExists(pi: ExtensionAPI, repoRoot: string, branch: string): Promise<boolean> {
	const r = await pi.exec("git", ["show-ref", "--verify", "--", `refs/heads/${branch}`], { cwd: repoRoot, timeout: 5000 });
	return !r.killed && r.code === 0;
}

async function createWorktree(pi: ExtensionAPI, repoRoot: string, branch: string, fromRef?: string): Promise<{ ok: true; path: string } | { ok: false; error: string }> {
	const worktreeRoot = join(dirname(repoRoot), `${basename(repoRoot)}-worktrees`);
	const slug = branch.replace(/[^A-Za-z0-9._-]+/g, "-").replace(/-+/g, "-").replace(/^-|-$/g, "") || "worktree";
	const targetPath = join(worktreeRoot, slug);
	if (existsSync(targetPath)) return { ok: false, error: `Worktree path exists: ${targetPath}` };
	mkdirSync(worktreeRoot, { recursive: true });
	const args = ["worktree", "add", "-b", branch, targetPath];
	if (fromRef?.trim()) args.push(fromRef.trim());
	const r = await pi.exec("git", args, { cwd: repoRoot, timeout: 30000 });
	if (r.code !== 0) return { ok: false, error: r.stderr.trim() || "Failed to create worktree" };
	return { ok: true, path: targetPath };
}

// ── Continue / Handoff ────────────────────────────────────────────────────────

function parseContinueArgs(args: string): { ok: true; request: ContinueRequest } | { ok: false; error: string } {
	const trimmed = args.trim();
	if (!trimmed) return { ok: true, request: { mode: "handoff" } };
	const tokens = trimmed.split(/\s+/);
	const [first, ...rest] = tokens;
	if (first === "-c" || first === "--create") {
		if (!rest.length) return { ok: false, error: "-c requires a branch name" };
		const [branch, ...remaining] = rest;
		let fromRef: string | undefined;
		const noteParts: string[] = [];
		for (let i = 0; i < remaining.length; i++) {
			if (remaining[i] === "--from" || remaining[i] === "-f") {
				if (!remaining[i + 1]) return { ok: false, error: "--from requires a ref" };
				fromRef = remaining[++i];
			} else noteParts.push(remaining[i]);
		}
		return { ok: true, request: { mode: "worktree", branch, fromRef, note: noteParts.join(" ").trim() || undefined } };
	}
	if (first.startsWith("-")) return { ok: false, error: `Unknown flag: ${first}` };
	return { ok: true, request: { mode: "handoff", note: trimmed } };
}

// --- LLM-powered handoff (from our handoff.ts) ---

function extractConversationText(ctx: any): string | undefined {
	const branch = ctx.sessionManager?.getBranch?.();
	if (!branch || !Array.isArray(branch) || branch.length === 0) return undefined;
	const messages = branch
		.filter((e: any) => e?.type === "message" && e.message?.role)
		.map((e: any) => e.message);
	if (messages.length === 0) return undefined;
	try {
		const llmMessages = convertToLlm(messages);
		return serializeConversation(llmMessages);
	} catch { return undefined; }
}

async function generateHandoffPrompt(ctx: any, goal: string, gitStatus?: { modified: string[]; newFiles: string[] }, targetBranch?: string, worktreePath?: string): Promise<string | undefined> {
	if (!ctx.model) return undefined;

	const conversationText = extractConversationText(ctx);
	if (!conversationText) return undefined;

	let userContent = `## Conversation History\n\n${conversationText}`;

	// Add git status context
	if (gitStatus && (gitStatus.modified.length > 0 || gitStatus.newFiles.length > 0)) {
		const statusLines: string[] = ["## Git Status"];
		if (gitStatus.modified.length > 0) {
			statusLines.push("Modified files:");
			for (const f of gitStatus.modified) statusLines.push(`  - ${f}`);
		}
		if (gitStatus.newFiles.length > 0) {
			statusLines.push("New files:");
			for (const f of gitStatus.newFiles) statusLines.push(`  - ${f}`);
		}
		userContent += "\n\n" + statusLines.join("\n");
	}

	// Add target context
	if (targetBranch || worktreePath) {
		const targetLines: string[] = ["## Target"];
		if (targetBranch) targetLines.push(`- Branch: ${targetBranch}`);
		if (worktreePath) targetLines.push(`- Worktree: ${worktreePath}`);
		userContent += "\n\n" + targetLines.join("\n");
	}

	userContent += `\n\n## Goal for New Session\n\n${goal}`;

	try {
		const apiKey = await ctx.modelRegistry.getApiKey(ctx.model);
		const response = await complete(
			ctx.model,
			{
				systemPrompt: HANDOFF_SYSTEM_PROMPT,
				messages: [{
					role: "user" as const,
					content: [{ type: "text" as const, text: userContent }],
					timestamp: Date.now(),
				}],
			},
			{ apiKey },
		);

		if (response.stopReason === "aborted") return undefined;

		return response.content
			.filter((c: any): c is { type: "text"; text: string } => c.type === "text")
			.map((c: any) => c.text)
			.join("\n").trim() || undefined;
	} catch (err) {
		console.error("Handoff LLM generation failed:", err);
		return undefined;
	}
}

// Fallback dumb template if LLM fails
function buildFallbackSummary(ctx: any, note?: string, gitStatus?: { modified: string[]; newFiles: string[] }, targetBranch?: string, worktreePath?: string): string {
	const lines = ["Handoff context from another Pi pane:"];
	lines.push(`- Source cwd: ${ctx.cwd}`);
	const sessionName = ctx.sessionManager?.getSessionName?.();
	if (sessionName) lines.push(`- Session: ${sessionName}`);
	const branch = ctx.sessionManager?.getSessionName?.();
	if (branch) lines.push(`- Branch: ${branch}`);
	if (targetBranch) lines.push(`- Target branch: ${targetBranch}`);
	if (worktreePath) lines.push(`- Target worktree: ${worktreePath}`);
	if (note) lines.push(`- Focus: ${note}`);
	if (gitStatus) {
		if (gitStatus.modified.length > 0) {
			lines.push("- Modified files:");
			for (const f of gitStatus.modified) lines.push(`  ${f}`);
		}
		if (gitStatus.newFiles.length > 0) {
			lines.push("- New files:");
			for (const f of gitStatus.newFiles) lines.push(`  ${f}`);
		}
	}
	return lines.join("\n");
}

// ── Zoxide ────────────────────────────────────────────────────────────────────

function resolveZoxideDir(query: string, baseDir: string): string | undefined {
	if (!query.trim()) return undefined;
	const expanded = query.startsWith("~/") ? join(homedir(), query.slice(2)) : query;
	const resolved = isAbsolute(expanded) ? expanded : resolve(baseDir, expanded);
	if (existsSync(resolved)) return resolved;
	try {
		return execFileSync("zoxide", ["query", ...query.trim().split(/\s+/)], { encoding: "utf-8", timeout: 5000 }).trim() || undefined;
	} catch { return undefined; }
}

// ── Extension ─────────────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {

	// ═══════════════════════════════════════════════════════════════════════════
	// TOOLS
	// ═══════════════════════════════════════════════════════════════════════════

	pi.registerTool({
		name: "zellij_list_sessions",
		label: "Zellij Sessions",
		description: "List all active Zellij sessions",
		parameters: Type.Object({}),
		async execute() {
			const output = await runZellij(pi, ["list-sessions"]);
			return { content: [{ type: "text" as const, text: output || "No active sessions." }], details: {} };
		},
	});

	pi.registerTool({
		name: "zellij_list_tabs",
		label: "Zellij Tabs",
		description: "List all tabs in a Zellij session",
		parameters: Type.Object({
			session: Type.Optional(Type.String({ description: "Session name (current if omitted)" })),
		}),
		async execute(_, params) {
			const output = await runZellij(pi, ["action", "list-tabs", "-j"], params.session);
			return { content: [{ type: "text" as const, text: output }], details: { output: JSON.parse(output) } };
		},
	});

	pi.registerTool({
		name: "zellij_list_panes",
		label: "Zellij Panes",
		description: "List all panes with detailed info (JSON)",
		parameters: Type.Object({
			session: Type.Optional(Type.String({ description: "Session name" })),
			tab: Type.Optional(Type.String({ description: "Tab name or ID to filter" })),
		}),
		async execute(_, params) {
			const output = await runZellij(pi, ["action", "list-panes", "-j", "-a", "-c", "-g", "-s", "-t"], params.session);
			let panes = JSON.parse(output);
			if (params.tab) panes = panes.filter((p: any) => p.tab_name === params.tab || String(p.tab_id) === params.tab);
			const summary = panes.map((p: any) => ({ id: p.id, title: p.title, tab: p.tab_name, cwd: p.pane_cwd, focused: p.is_focused, floating: p.is_floating }));
			return { content: [{ type: "text" as const, text: JSON.stringify(summary, null, 2) }], details: { panes: summary } };
		},
	});

	pi.registerTool({
		name: "zellij_dump_pane",
		label: "Zellij Dump",
		description: "Dump content (viewport + scrollback) of a specific pane",
		parameters: Type.Object({
			pane_id: Type.String({ description: "Pane ID (e.g. 'terminal_1' or '1')" }),
			session: Type.Optional(Type.String({ description: "Session name" })),
			include_scrollback: Type.Optional(Type.Boolean({ description: "Include scrollback (default true)", default: true })),
		}),
		async execute(_, params) {
			const args = ["action", "dump-screen", "-p", params.pane_id];
			if (params.include_scrollback !== false) args.push("-f");
			const output = await runZellij(pi, args, params.session);
			const maxLen = 50_000;
			const truncated = output.length > maxLen ? output.slice(0, maxLen) + "\n... (truncated)" : output;
			return { content: [{ type: "text" as const, text: truncated }], details: { pane_id: params.pane_id, length: output.length, truncated: output.length > maxLen } };
		},
	});

	pi.registerTool({
		name: "zellij_current_tab",
		label: "Zellij Current Tab",
		description: "Get info about the currently active tab",
		parameters: Type.Object({
			session: Type.Optional(Type.String({ description: "Session name" })),
		}),
		async execute(_, params) {
			const output = await runZellij(pi, ["action", "current-tab-info", "-j"], params.session);
			return { content: [{ type: "text" as const, text: output }], details: { info: JSON.parse(output) } };
		},
	});

	pi.registerTool({
		name: "zellij_new_pane",
		label: "Zellij New Pane",
		description: "Open a new pane with an optional command",
		parameters: Type.Object({
			command: Type.Optional(Type.String({ description: "Command to run" })),
			direction: Type.Optional(StringEnum(["right", "down"] as const, { description: "Direction" })),
			session: Type.Optional(Type.String({ description: "Session name" })),
			cwd: Type.Optional(Type.String({ description: "Working directory" })),
		}),
		async execute(_, params) {
			const args = ["action", "new-pane"];
			if (params.direction) args.push("--direction", params.direction);
			if (params.cwd) args.push("--cwd", params.cwd);
			if (params.command) args.push("--", "bash", "-c", params.command);
			const output = await runZellij(pi, args, params.session);
			return { content: [{ type: "text" as const, text: output || "New pane created." }], details: {} };
		},
	});

	// ═══════════════════════════════════════════════════════════════════════════
	// COMMANDS
	// ═══════════════════════════════════════════════════════════════════════════

	function registerSplitCmd(name: string, dir: SplitDir, desc: string) {
		pi.registerCommand(name, {
			description: desc,
			handler: async (args, ctx) => {
				const prompt = args.trim();
				const cmd = buildPiCmd(ctx.cwd, prompt ? { prompt } : undefined);
				const r = await openSplit(pi, dir, cmd);
				if (r.ok) ctx.ui.notify(`Opened ${dir} pane${r.paneId ? ` (${r.paneId})` : ""}`, "info");
				else ctx.ui.notify(`Split failed: ${r.error}`, "error");
			},
		});
	}

	function registerTabCmd(name: string, desc: string) {
		pi.registerCommand(name, {
			description: desc,
			handler: async (args, ctx) => {
				if (!isInsideZellij()) { ctx.ui.notify("Not inside zellij", "error"); return; }
				const prompt = args.trim();
				const cmd = buildPiCmd(ctx.cwd, prompt ? { prompt } : undefined);
				const r = await execZellij(pi, ["action", "new-tab", "--cwd", ctx.cwd, "--", "sh", "-lc", cmd]);
				if (!r.ok) {
					await execZellij(pi, ["action", "new-tab", "--cwd", ctx.cwd]);
					await execZellij(pi, ["action", "write-chars", cmd]);
					await execZellij(pi, ["action", "write", "10"]);
				}
				ctx.ui.notify("Opened new tab", "info");
			},
		});
	}

	function registerShellCmd(name: string, dir: SplitDir, desc: string) {
		pi.registerCommand(name, {
			description: desc,
			handler: async (args, ctx) => {
				const command = args.trim();
				if (!command) { ctx.ui.notify(`Usage: /${name} <command>`, "warning"); return; }
				const r = await openSplit(pi, dir, buildShellCmd(ctx.cwd, command));
				if (r.ok) ctx.ui.notify(`Opened ${dir} pane${r.paneId ? ` (${r.paneId})` : ""}`, "info");
				else ctx.ui.notify(`Failed: ${r.error}`, "error");
			},
		});
	}

	function registerZoxideCmd(name: string, dir: SplitDir, desc: string) {
		pi.registerCommand(name, {
			description: desc,
			handler: async (args, ctx) => {
				const query = args.trim();
				if (!query) { ctx.ui.notify(`Usage: /${name} <query>`, "warning"); return; }
				const target = resolveZoxideDir(query, ctx.cwd);
				if (!target) { ctx.ui.notify(`zoxide: no match for "${query}"`, "error"); return; }
				const r = await openSplit(pi, dir, buildPiCmd(target));
				if (r.ok) ctx.ui.notify(`Opened ${dir} pane in ${target}${r.paneId ? ` (${r.paneId})` : ""}`, "info");
				else ctx.ui.notify(`Failed: ${r.error}`, "error");
			},
		});
	}

	// ── Continue with LLM-powered handoff ───────────────────────────────────

	function registerContinueCmd(name: string, dir: SplitDir, desc: string) {
		pi.registerCommand(name, {
			description: desc,
			handler: async (args, ctx) => {
				const parsed = parseContinueArgs(args);
				if (!parsed.ok) { ctx.ui.notify(parsed.error, "warning"); return; }
				const req = parsed.request;

				let targetCwd = ctx.cwd;
				let targetBranch: string | undefined;
				let worktreePath: string | undefined;

				// Create worktree if requested
				if (req.mode === "worktree") {
					const repoRoot = await getGitRoot(pi, ctx.cwd);
					if (!repoRoot) { ctx.ui.notify("Not in a git repo", "error"); return; }
					if (await branchExists(pi, repoRoot, req.branch)) { ctx.ui.notify(`Branch already exists: ${req.branch}`, "error"); return; }
					const wt = await createWorktree(pi, repoRoot, req.branch, req.fromRef);
					if (!wt.ok) { ctx.ui.notify(wt.error, "error"); return; }
					targetCwd = wt.path;
					targetBranch = req.branch;
					worktreePath = wt.path;
				}

				// Collect git status as context
				const gitStatus = await getGitStatus(pi, ctx.cwd);

				// Goal for the LLM
				const goal = req.note
					? `Continue the current task. Focus on: ${req.note}`
					: "Continue the current task from where we left off";

				// Notify user that we're generating handoff
				ctx.ui.notify("Generating handoff context...", "info");

				// Try LLM-powered handoff first, fall back to dumb template
				let prompt: string;
				const llmPrompt = await generateHandoffPrompt(ctx, goal, gitStatus, targetBranch, worktreePath);

				if (llmPrompt) {
					prompt = llmPrompt;
				} else {
					// Fallback: use dumb template
					const summary = buildFallbackSummary(ctx, req.note, gitStatus, targetBranch, worktreePath);
					prompt = req.note
						? `Continue the current task from this new pane. Focus on: ${req.note}.\n\n${summary}`
						: `Continue the current task from this new pane.\n\n${summary}`;
				}

				// Try to fork the session for inherited context
				let sessionFile: string | undefined;
				try {
					const sm = ctx.sessionManager;
					const currentFile = sm?.getSessionFile?.();
					const leafId = sm?.getLeafId?.();
					if (currentFile && leafId) {
						const SessionManager = (sm as any).constructor as any;
						const current = SessionManager.open(currentFile, sm.getSessionDir());
						const forked = current.createBranchedSession(leafId);
						if (forked) {
							sessionFile = forked;
							// If LLM generated the prompt, we don't need to append
							// the summary to the forked session (it's already in the prompt).
							// If fallback, append the summary.
							if (!llmPrompt) {
								const branched = SessionManager.open(forked, sm.getSessionDir());
								branched.appendMessage({ role: "user", content: buildFallbackSummary(ctx, req.note, gitStatus, targetBranch, worktreePath), timestamp: Date.now() });
							}
						}
					}
				} catch {}

				const cmd = buildPiCmd(targetCwd, { sessionFile, prompt });
				const r = await openSplit(pi, dir, cmd);
				if (r.ok) {
					const where = targetBranch ? ` (worktree: ${targetBranch})` : "";
					const method = llmPrompt ? " (LLM handoff)" : " (template handoff)";
					ctx.ui.notify(`Continuing in ${dir} pane${where}${method}${r.paneId ? ` (${r.paneId})` : ""}`, "info");
				} else {
					ctx.ui.notify(`Failed: ${r.error}`, "error");
				}
			},
		});
	}

	// Register all commands
	registerSplitCmd("zv", "right", "Open a new right pane with a fresh pi session");
	registerSplitCmd("zj", "down", "Open a new lower pane with a fresh pi session");
	registerTabCmd("zt", "Open a new tab with a fresh pi session");
	registerShellCmd("zo", "right", "Run a shell command in a new right pane");
	registerShellCmd("zoh", "down", "Run a shell command in a new lower pane");
	registerZoxideCmd("zz", "right", "Open pi in a zoxide directory (right pane)");
	registerZoxideCmd("zzh", "down", "Open pi in a zoxide directory (lower pane)");
	registerContinueCmd("zcv", "right", "Continue task in right split (LLM handoff, -c <branch> for worktree)");
	registerContinueCmd("zch", "down", "Continue task in lower split (LLM handoff, -c <branch> for worktree)");

	// Floating shortcuts from settings
	for (const [cmdName, cfg] of loadFloatingCommands()) {
		pi.registerCommand(cmdName, {
			description: cfg.description,
			handler: async (args, ctx) => {
				const trimmed = args.trim();
				if (trimmed && !cfg.acceptArgs) { ctx.ui.notify(`Usage: /${cmdName}`, "warning"); return; }
				const command = trimmed ? `${cfg.run} ${trimmed}` : cfg.run;
				const r = await openFloating(pi, command, cmdName);
				if (r.ok) ctx.ui.notify(`Opened /${cmdName}${r.paneId ? ` (${r.paneId})` : ""}`, "info");
				else ctx.ui.notify(`Failed: ${r.error}`, "error");
			},
		});
	}

	// Overview command
	pi.registerCommand("zellij", {
		description: "Show zellij session overview",
		handler: async (_args, ctx) => {
			try {
				const sessions = (await runZellij(pi, ["list-sessions"])).split("\n").filter((l) => l.trim());
				ctx.ui.notify(["Zellij sessions:", ...sessions.map((s) => `  ${s}`)].join("\n"), "info");
			} catch (e: any) {
				ctx.ui.notify(`Error: ${e.message}`, "error");
			}
		},
	});

	// ═══════════════════════════════════════════════════════════════════════════
	// PANE HIGHLIGHTING
	// ═══════════════════════════════════════════════════════════════════════════

	let highlightConfig = loadHighlightConfig();
	let focusTimer: ReturnType<typeof setInterval> | undefined;

	async function resetColor() {
		if (!isInsideZellij()) return;
		const paneId = process.env.ZELLIJ_PANE_ID;
		const args = paneId ? ["action", "set-pane-color", "-p", paneId, "--reset"] : ["action", "set-pane-color", "--reset"];
		await execZellij(pi, args);
	}

	async function setColor(bg?: string, fg?: string) {
		if (!isInsideZellij()) return;
		const paneId = process.env.ZELLIJ_PANE_ID;
		const args = ["action", "set-pane-color"];
		if (paneId) args.push("-p", paneId);
		if (bg) args.push("--bg", bg);
		if (fg) args.push("--fg", fg);
		await execZellij(pi, args);
	}

	pi.on("session_start", async () => { highlightConfig = loadHighlightConfig(); });
	pi.on("session_switch", async () => { highlightConfig = loadHighlightConfig(); await resetColor(); });
	pi.on("input", async () => { if (focusTimer) { clearInterval(focusTimer); focusTimer = undefined; } await resetColor(); });
	pi.on("agent_start", async () => {
		if (highlightConfig.workingBg || highlightConfig.workingFg) await setColor(highlightConfig.workingBg, highlightConfig.workingFg);
	});
	pi.on("agent_end", async () => {
		if (!highlightConfig.enabled || !isInsideZellij()) return;
		await setColor(highlightConfig.doneBg, highlightConfig.doneFg);
		if (focusTimer) clearInterval(focusTimer);
		focusTimer = setTimeout(async () => { await resetColor(); focusTimer = undefined; }, 30_000);
		if (focusTimer && typeof focusTimer === "object" && "unref" in focusTimer) (focusTimer as any).unref();
	});
	pi.on("session_shutdown", async () => { await resetColor(); });
}
