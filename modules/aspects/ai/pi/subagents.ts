/**
 * Subagents Extension - Agent discovery + Rich Widget + Async Execution
 *
 * Features:
 * - Discovers agents from ~/.pi/agent/agents/*.md and .pi/agents/*.md
 * - Single, parallel, and chain execution modes
 * - Rich live widgets: animated spinner, tool tracking, elapsed time, progress bars
 * - Async background execution with result files + notifications
 * - Rich activity tracking: tool execution start/update/end, thinking state
 * - Agent frontmatter: name, description, model, extensions, skills, thinking, tools
 * - Settings with environment variable injection (global + project)
 * - Semantic completion via agent_end event detection
 * - Artifact files for stdout/stderr diagnostics
 * - Nested fork/subagent usage aggregation
 * - Commands: /sub, /subcont, /subrm, /subclear
 */

import { spawn } from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import type { Message } from "@mariozechner/pi-ai";
import { StringEnum } from "@mariozechner/pi-ai";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { truncateToWidth } from "@mariozechner/pi-tui";
import { Type } from "typebox";
import { getAgentDir, parseFrontmatter } from "@mariozechner/pi-coding-agent";

// ── Agent Discovery (inlined from agents.ts) ──────────────────────────────────

type AgentScope = "user" | "project" | "both";

interface AgentConfig {
	name: string;
	description: string;
	tools?: string[];
	model?: string;
	extensions?: string[];
	skills?: string[];
	thinking?: string;
	systemPrompt: string;
	source: "user" | "project";
	filePath: string;
}

function loadAgentsFromDir(dir: string, source: "user" | "project"): AgentConfig[] {
	const agents: AgentConfig[] = [];
	if (!fs.existsSync(dir)) return agents;
	let entries: fs.Dirent[];
	try { entries = fs.readdirSync(dir, { withFileTypes: true }); } catch { return agents; }

	for (const entry of entries) {
		if (!entry.name.endsWith(".md")) continue;
		if (!entry.isFile() && !entry.isSymbolicLink()) continue;
		const filePath = path.join(dir, entry.name);
		let content: string;
		try { content = fs.readFileSync(filePath, "utf-8"); } catch { continue; }
		const { frontmatter, body } = parseFrontmatter<Record<string, string>>(content);
		if (!frontmatter.name || !frontmatter.description) continue;
		const tools = frontmatter.tools?.split(",").map((t: string) => t.trim()).filter(Boolean);
		const extensions = frontmatter.extensions?.split(",").map((e: string) => e.trim()).filter(Boolean);
		const skills = frontmatter.skills?.split(",").map((s: string) => s.trim()).filter(Boolean);
		agents.push({
			name: frontmatter.name, description: frontmatter.description,
			tools: tools?.length ? tools : undefined, model: frontmatter.model,
			extensions: extensions?.length ? extensions : undefined,
			skills: skills?.length ? skills : undefined,
			thinking: frontmatter.thinking || undefined,
			systemPrompt: body, source, filePath,
		});
	}
	return agents;
}

function findNearestProjectAgentsDir(cwd: string): string | null {
	let dir = cwd;
	while (true) {
		const candidate = path.join(dir, ".pi", "agents");
		try { if (fs.statSync(candidate).isDirectory()) return candidate; } catch {}
		const parent = path.dirname(dir);
		if (parent === dir) return null;
		dir = parent;
	}
}

function discoverAgents(cwd: string, scope: AgentScope) {
	const userDir = path.join(getAgentDir(), "agents");
	const projectDir = findNearestProjectAgentsDir(cwd);
	const userAgents = scope === "project" ? [] : loadAgentsFromDir(userDir, "user");
	const projectAgents = scope === "user" || !projectDir ? [] : loadAgentsFromDir(projectDir, "project");
	const map = new Map<string, AgentConfig>();
	const list = scope === "both" ? [...userAgents, ...projectAgents]
		: scope === "user" ? userAgents : projectAgents;
	for (const a of list) map.set(a.name, a);
	return { agents: Array.from(map.values()), projectAgentsDir: projectDir };
}

// ── Settings ─────────────────────────────────────────────────────────────────

interface Settings {
	model: string | null;
	extensions: string[] | null;
	environment: Record<string, string>;
}

const SETTINGS_KEY = "pi-subagents";

function readJsonSafe(filePath: string): Record<string, unknown> {
	try { return JSON.parse(fs.readFileSync(filePath, "utf-8")); } catch { return {}; }
}

function resolveConfiguredPath(value: string, baseDir: string): string {
	if (!value) return value;
	if (value.startsWith("npm:") || value.startsWith("git:")) return value;
	if (value.startsWith("~/")) return path.join(os.homedir(), value.slice(2));
	if (path.isAbsolute(value)) return value;
	return path.resolve(baseDir, value);
}

function parseEnvironment(value: unknown): Record<string, string> | undefined {
	if (!value || typeof value !== "object" || Array.isArray(value)) return undefined;
	const env: Record<string, string> = {};
	for (const [rawKey, rawValue] of Object.entries(value as Record<string, unknown>)) {
		const key = rawKey.trim();
		if (!key || key.includes("=") || key.includes("\0") || typeof rawValue !== "string" || rawValue.includes("\0")) continue;
		env[key] = rawValue;
	}
	return env;
}

function mergeEnvironment(
	base: Record<string, string> | undefined,
	overrides: Record<string, string> | undefined,
): Record<string, string> {
	const env = { ...(base ?? {}) };
	if (!overrides) return env;
	if (process.platform === "win32") {
		for (const [k, v] of Object.entries(overrides)) {
			const nk = k.toLowerCase();
			for (const key of Object.keys(env)) { if (key.toLowerCase() === nk) delete env[key]; }
			env[k] = v;
		}
		return env;
	}
	return { ...env, ...overrides };
}

function readSettings(filePath: string, baseDir: string): Partial<Settings> {
	const raw = readJsonSafe(filePath)[SETTINGS_KEY];
	if (!raw || typeof raw !== "object") return {};
	const config = raw as Record<string, unknown>;
	const settings: Partial<Settings> = {};
	if (typeof config.model === "string" && config.model.trim()) settings.model = config.model;
	else if (config.model === null) settings.model = null;
	if (config.extensions === null) settings.extensions = null;
	else if (Array.isArray(config.extensions)) {
		settings.extensions = config.extensions
			.filter((e: unknown): e is string => typeof e === "string" && e.trim().length > 0)
			.map((e: string) => resolveConfiguredPath(e.trim(), baseDir));
	}
	const env = parseEnvironment(config.environment);
	if (env) settings.environment = env;
	return settings;
}

function resolveSettings(cwd: string): Settings {
	const globalDir = getAgentDir();
	const projectDir = path.join(cwd, ".pi");
	const gs = readSettings(path.join(globalDir, "settings.json"), globalDir);
	const ps = readSettings(path.join(projectDir, "settings.json"), projectDir);
	return {
		model: null, extensions: null,
		...gs, ...ps,
		environment: mergeEnvironment(gs.environment, ps.environment),
	};
}

function mergeExtensions(settings: Settings, agent: AgentConfig): string[] {
	return [...new Set([...(settings.extensions ?? []), ...(agent.extensions ?? [])])];
}

function buildChildEnv(settings: Settings): NodeJS.ProcessEnv {
	const inherited = { ...process.env };
	if (process.platform === "win32") {
		for (const [k, v] of Object.entries(settings.environment)) {
			const nk = k.toLowerCase();
			for (const key of Object.keys(inherited)) { if (key.toLowerCase() === nk) delete inherited[key]; }
			inherited[k] = v;
		}
		return inherited;
	}
	return { ...inherited, ...settings.environment };
}

// ── Activity Tracking ─────────────────────────────────────────────────────────

interface ToolExecution {
	toolCallId: string;
	toolName: string;
	status: "running" | "completed" | "error";
	updates: number;
	displayText?: string;
	latestText?: string;
	isError?: boolean;
}

interface ThinkingState {
	status: "running" | "completed";
	chars: number;
}

const MAX_STORED_ACTIVITIES = 50;
const MAX_STORED_TOOL_EXECUTIONS = 25;
const MAX_TOOL_PREVIEW_CHARS = 1200;
const MAX_INLINE_ERROR_CHARS = 160;

function formatCount(n: number): string {
	if (!Number.isFinite(n) || n <= 0) return "0";
	if (n < 1000) return String(Math.round(n));
	if (n < 10_000) return `${(n / 1000).toFixed(1)}k`;
	if (n < 1_000_000) return `${Math.round(n / 1000)}k`;
	return `${(n / 1_000_000).toFixed(1)}M`;
}

function truncateInline(text: string, maxChars: number): string {
	const singleLine = text.replace(/\s+/g, " ").trim();
	if (singleLine.length <= maxChars) return singleLine;
	return `${singleLine.slice(0, Math.max(0, maxChars - 1))}…`;
}

function formatToolCallPreview(toolName: string, args: Record<string, unknown>): string {
	if (!args || typeof args !== "object") return toolName || "tool";
	switch (toolName) {
		case "bash": { const c = typeof args.command === "string" ? args.command : "..."; return `bash $ ${truncateInline(c, 80)}`; }
		case "read": { const p = (args.path || args.file_path || "...") as string; return `read ${p.replace(/^\/home\/[^/]+/, "~")}`; }
		case "write": { return `write ${((args.path || args.file_path || "...") as string).replace(/^\/home\/[^/]+/, "~")}`; }
		case "edit": { return `edit ${((args.path || args.file_path || "...") as string).replace(/^\/home\/[^/]+/, "~")}`; }
		default: return toolName || "tool";
	}
}

function extractResultText(toolResult: any): string {
	if (!toolResult || typeof toolResult !== "object") return "";
	const content = Array.isArray(toolResult.content) ? toolResult.content : [];
	const texts = content.filter((p: any) => p?.type === "text" && typeof p.text === "string").map((p: any) => p.text);
	if (texts.length) return texts.join("\n").trim().slice(0, MAX_TOOL_PREVIEW_CHARS);
	return "";
}

// ── Constants ─────────────────────────────────────────────────────────────────

const SPINNER = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
const SPINNER_MS = 80;
const RESULTS_DIR = path.join(os.homedir(), ".pi", "agent", "sessions", "subagents", "results");

// ── Types ─────────────────────────────────────────────────────────────────────

interface UsageStats {
	input: number; output: number; cacheRead: number; cacheWrite: number;
	cost: number; contextTokens: number; turns: number;
}

interface SubagentResult {
	agent: string;
	task: string;
	status: "running" | "completed" | "failed" | "pending";
	exitCode: number;
	messages: Message[];
	stderr: string;
	usage: UsageStats;
	model?: string;
	step?: number;
	errorMessage?: string;
	startTime?: number;
	endTime?: number;
	agentSource?: "user" | "project";
}

interface SubagentDetails {
	mode: "single" | "parallel" | "chain";
	results: SubagentResult[];
	runningCount: number;
	completedCount: number;
	failedCount: number;
	availableAgents?: string;
}

/** State for a single running/finished subagent (widget + execution) */
interface SubState {
	id: number;
	agentName: string;
	task: string;
	taskPreview: string;
	status: "running" | "done" | "error" | "pending";
	proc?: ReturnType<typeof spawn>;
	textChunks: string[];
	lastOutput?: string;
	currentTool?: string;
	currentToolStartedAt?: number;
	toolCount: number;
	turnCount: number;
	elapsed: number;
	startTime: number;
	sessionFile: string;
	resultText?: string;
	// Rich activity tracking (from elpapi42/pi-minimal-subagent)
	thinking?: ThinkingState;
	toolExecutions: ToolExecution[];
	toolExecutionCount: number;
	sawAgentEnd?: boolean;
	artifactDir?: string;
	stdoutArtifact?: string;
	stderrArtifact?: string;
	stdoutTail: string[];
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function fmtDuration(ms: number): string {
	const s = Math.floor(ms / 1000);
	if (s < 60) return `${s}s`;
	const m = Math.floor(s / 60);
	return m < 60 ? `${m}m${s % 60}s` : `${Math.floor(m / 60)}h${m % 60}m`;
}

function spinnerFrame(): string {
	return SPINNER[Math.floor(Date.now() / SPINNER_MS) % SPINNER.length]!;
}

function getFinalOutput(messages: Message[]): string {
	for (let i = messages.length - 1; i >= 0; i--) {
		const msg = messages[i];
		if (msg.role === "assistant") {
			for (const part of msg.content) {
				if (part.type === "text") return part.text;
			}
		}
	}
	return "";
}

function makeSessionFile(id: number): string {
	const dir = path.join(os.homedir(), ".pi", "agent", "sessions", "subagents");
	fs.mkdirSync(dir, { recursive: true });
	return path.join(dir, `subagent-${id}-${Date.now()}.jsonl`);
}

function getPiInvocation(args: string[]): { command: string; args: string[] } {
	const currentScript = process.argv[1];
	const isBunVirtualScript = currentScript?.startsWith("/$bunfs/root/");
	if (currentScript && !isBunVirtualScript && fs.existsSync(currentScript)) {
		return { command: process.execPath, args: [currentScript, ...args] };
	}
	const execName = path.basename(process.execPath).toLowerCase();
	if (!/^(node|bun)(\.exe)?$/.test(execName)) {
		return { command: process.execPath, args };
	}
	return { command: "pi", args };
}

// ── Widget Renderer (pure function) ──────────────────────────────────────────

function renderWidgetLines(subs: Map<number, SubState>, theme: any, width: number): string[] {
	const th = theme;
	const lines: string[] = [];
	if (subs.size === 0) return lines;

	const entries = Array.from(subs.values());

	// Header
	const running = entries.filter(s => s.status === "running").length;
	const done = entries.filter(s => s.status === "done").length;
	const failed = entries.filter(s => s.status === "error").length;

	const headerParts: string[] = [];
	if (running > 0) headerParts.push(th.fg("accent", `● ${running} running`));
	if (done > 0) headerParts.push(th.fg("success", `✓ ${done} done`));
	if (failed > 0) headerParts.push(th.fg("error", `✗ ${failed} failed`));
	// Show total elapsed when all done
	const allDone = running === 0 && (done + failed) > 0;
	if (allDone) {
		const totalElapsed = Math.max(...entries.map(s => s.elapsed));
		headerParts.push(th.fg("dim", fmtDuration(totalElapsed)));
	}
	const header = th.bold(" Subagents ") + th.fg("dim", "│") + " " + headerParts.join(th.fg("dim", " · "));
	lines.push(truncateToWidth(header, width));

	// Separator
	lines.push(th.fg("dim", "─".repeat(Math.min(width, 60))));

	// Each subagent line
	for (const s of entries) {
		// Update elapsed for running agents
		if (s.status === "running") s.elapsed = Date.now() - s.startTime;

		// Status icon
		const icon = s.status === "running" ? th.fg("accent", spinnerFrame())
			: s.status === "done" ? th.fg("success", "✓")
			: s.status === "error" ? th.fg("error", "✗")
			: th.fg("dim", "◦");

		// Agent name + task
		const name = th.fg("accent", s.agentName);
		const taskMax = Math.max(20, width - 40);
		const task = th.fg("muted", s.task.length > taskMax ? s.taskPreview : s.task.slice(0, taskMax));

		// Stats
		const elapsed = th.fg("dim", fmtDuration(s.elapsed));
		const tools = th.fg("dim", `${s.toolCount}t`);
		const turns = s.turnCount > 1 ? th.fg("dim", `${s.turnCount}r`) : "";
		const stats = [elapsed, tools, turns].filter(Boolean).join(th.fg("dim", " · "));

		lines.push(truncateToWidth(`${icon} ${name} ${task} ${th.fg("dim", "│")} ${stats}`, width));

		// Activity sub-line for running agents
		if (s.status === "running") {
			const actParts: string[] = [];

			// Show thinking state
			if (s.thinking?.status === "running") {
				const chars = s.thinking.chars > 0 ? ` ${formatCount(s.thinking.chars)} chars` : "...";
				actParts.push(`thinking${chars}`);
			}

			// Show tool activity with richer info
			if (s.currentTool) {
				const dur = s.currentToolStartedAt ? ` ${fmtDuration(Date.now() - s.currentToolStartedAt)}` : "";
				actParts.push(`${s.currentTool}${dur}`);
			}

			// Show latest tool output preview
			if (s.lastOutput) {
				const preview = s.lastOutput.length > 60 ? s.lastOutput.slice(0, 57) + "…" : s.lastOutput;
				actParts.push(preview);
			}

			// Show recent tool execution summary
			const recentTools = s.toolExecutions.slice(-3);
			for (const t of recentTools) {
				if (t.status === "error") {
					actParts.push(`✗ ${t.displayText || t.toolName}`);
				}
			}

			const activity = actParts.length > 0 ? actParts.join(" · ") : "thinking…";
			lines.push(truncateToWidth(th.fg("dim", `  ${activity}`), width));
		}

		// Error sub-line
		if (s.status === "error" && s.lastOutput) {
			const err = s.lastOutput.length > width - 6 ? s.lastOutput.slice(0, width - 9) + "…" : s.lastOutput;
			lines.push(truncateToWidth(th.fg("error", `  → ${err}`), width));
		}
	}

	return lines;
}

// ── Process Line Parser ──────────────────────────────────────────────────────

function processLine(state: SubState, line: string) {
	if (!line.trim()) return;
	try {
		const event = JSON.parse(line);
		// pi --mode json format (message_end with full message)
		if (event.type === "message_end" && event.message) {
			const msg = event.message;
			if (msg.role === "assistant") {
				for (const part of msg.content) {
					if (part.type === "text") state.textChunks.push(part.text);
				}
				// Cap at 100KB to prevent unbounded growth
				if (state.textChunks.join("").length > 100_000) {
					state.textChunks = [state.textChunks.join("").slice(-50_000)];
				}
				state.lastOutput = state.textChunks.join("").split("\n").filter((l: string) => l.trim()).pop() || "";
			}
		}
		// Streaming format (message_update with deltas)
		else if (event.type === "message_update") {
			const delta = event.assistantMessageEvent;
			if (delta?.type === "text_delta") {
				state.textChunks.push(delta.delta || "");
				if (state.textChunks.join("").length > 100_000) {
					state.textChunks = [state.textChunks.join("").slice(-50_000)];
				}
				state.lastOutput = state.textChunks.join("").split("\n").filter((l: string) => l.trim()).pop() || "";
			}
			// Thinking events
			else if (delta?.type === "thinking_start") {
				state.thinking = { status: "running", chars: 0 };
			} else if (delta?.type === "thinking_delta") {
				if (state.thinking && delta.delta) state.thinking.chars += delta.delta.length;
			} else if (delta?.type === "thinking_end") {
				if (state.thinking) { state.thinking.status = "completed"; if (delta.content) state.thinking.chars = delta.content.length; }
			}
		}
		// Tool execution events with rich tracking
		else if (event.type === "tool_execution_start") {
			state.toolCount++;
			state.toolExecutionCount++;
			const toolName = event.toolName || event.tool || "tool";
			const displayText = event.args ? formatToolCallPreview(toolName, event.args) : toolName;
			state.currentTool = displayText;
			state.currentToolStartedAt = Date.now();
			const tool: ToolExecution = {
				toolCallId: event.toolCallId || `t-${state.toolExecutionCount}`,
				toolName, status: "running", updates: 0, displayText, latestText: undefined, isError: false,
			};
			state.toolExecutions.push(tool);
			while (state.toolExecutions.length > MAX_STORED_TOOL_EXECUTIONS) state.toolExecutions.shift();
		} else if (event.type === "tool_execution_update") {
			const tcId = event.toolCallId;
			const tool = tcId ? state.toolExecutions.find(t => t.toolCallId === tcId) : state.toolExecutions[state.toolExecutions.length - 1];
			if (tool) {
				tool.updates++;
				const text = extractResultText(event.partialResult);
				if (text) tool.latestText = text;
			}
		} else if (event.type === "tool_execution_end") {
			const tcId = event.toolCallId;
			const tool = tcId ? state.toolExecutions.find(t => t.toolCallId === tcId) : state.toolExecutions[state.toolExecutions.length - 1];
			if (tool) {
				tool.status = event.isError ? "error" : "completed";
				tool.isError = Boolean(event.isError);
				const text = extractResultText(event.result);
				if (text) tool.latestText = text;
			}
			state.currentTool = undefined;
			state.currentToolStartedAt = undefined;
		}
		// Agent end - semantic completion
		else if (event.type === "agent_end") {
			state.sawAgentEnd = true;
		}
	} catch {}
}

// ── Temp file helpers ────────────────────────────────────────────────────────

async function writePromptFile(systemPrompt: string, agentName: string): Promise<{ path: string; dir: string } | null> {
	if (!systemPrompt.trim()) return null;
	const dir = await fs.promises.mkdtemp(path.join(os.tmpdir(), "pi-subagent-"));
	const filePath = path.join(dir, `prompt-${agentName.replace(/[^\w.-]/g, "_")}.md`);
	await fs.promises.writeFile(filePath, systemPrompt, { encoding: "utf-8", mode: 0o600 });
	return { path: filePath, dir };
}

function cleanupTemp(tmpPath: string | null, tmpDir: string | null) {
	if (tmpPath) try { fs.unlinkSync(tmpPath); } catch {}
	if (tmpDir) try { fs.rmSync(tmpDir, { recursive: true, force: true }); } catch {}
}

function cleanupTempDir(dir: string | null) {
	if (!dir) return;
	try { fs.rmSync(dir, { recursive: true, force: true }); } catch {}
}

// ── Subagent Runner (with widget updates) ─────────────────────────────────────

async function runSubagentWithWidget(
	state: SubState,
	agentConfig: AgentConfig,
	ctx: any,
	flush: () => void,
): Promise<string> {
	const settings = resolveSettings(ctx.cwd ?? process.cwd());
	const model = agentConfig.model ?? settings.model ?? ctx.model
		? `${ctx.model.provider}/${ctx.model.id}`
		: undefined;

	const promptFile = await writePromptFile(agentConfig.systemPrompt ?? "", agentConfig.name);

	// Create artifact files for diagnostics
	const artifactDir = fs.mkdtempSync(path.join(os.tmpdir(), "pi-subagent-output-"));
	const stdoutArtifact = path.join(artifactDir, "stdout.jsonl");
	const stderrArtifact = path.join(artifactDir, "stderr.log");
	fs.writeFileSync(stdoutArtifact, "", { encoding: "utf-8", mode: 0o600 });
	fs.writeFileSync(stderrArtifact, "", { encoding: "utf-8", mode: 0o600 });
	state.artifactDir = artifactDir;
	state.stdoutArtifact = stdoutArtifact;
	state.stderrArtifact = stderrArtifact;

	return new Promise<string>((resolve) => {
		const args = ["--mode", "json", "-p", "--no-session"];
		const extensions = mergeExtensions(settings, agentConfig);
		if (settings.extensions !== null) args.push("--no-extensions");
		for (const ext of extensions) args.push("--extension", ext);
		if (model) args.push("--model", model);
		if (agentConfig.thinking) args.push("--thinking", agentConfig.thinking);
		if (agentConfig.skills?.length) for (const skill of agentConfig.skills) args.push("--skill", skill);
		if (agentConfig.tools && agentConfig.tools.length > 0) args.push("--tools", agentConfig.tools.join(","));
		if (promptFile) args.push("--append-system-prompt", promptFile.path);
		args.push(`Task: ${state.task}`);

		const invocation = getPiInvocation(args);
		const proc = spawn(invocation.command, invocation.args, {
			stdio: ["pipe", "pipe", "pipe"],
			env: buildChildEnv(settings),
		});

		state.proc = proc;
		state.status = "running";

		proc.stdin.on("error", () => {});
		proc.stdin.end();

		let buffer = "";
		const AGENT_END_GRACE_MS = 250;
		let semanticTimer: ReturnType<typeof setTimeout> | undefined;
		let didClose = false;

		const finishRun = (code: number) => {
			if (semanticTimer) { clearTimeout(semanticTimer); semanticTimer = undefined; }
			if (buffer.trim()) processLine(state, buffer);
			state.elapsed = Date.now() - state.startTime;
			state.status = code === 0 ? "done" : "error";
			state.proc = undefined;
			state.currentTool = undefined;
			state.resultText = state.textChunks.join("");
			cleanupTemp(promptFile?.path ?? null, promptFile?.dir ?? null);
			cleanupTempDir(artifactDir);
			flush();
			resolve(state.resultText);
		};

		const maybeFinishFromAgentEnd = () => {
			if (!state.sawAgentEnd || didClose) return;
			if (semanticTimer) clearTimeout(semanticTimer);
			semanticTimer = setTimeout(() => {
				if (didClose || !state.sawAgentEnd) return;
				proc.stdout!.removeAllListeners("data");
				proc.stderr!.removeAllListeners("data");
				finishRun(0);
				proc.kill("SIGTERM");
			}, AGENT_END_GRACE_MS);
			if (semanticTimer.unref) semanticTimer.unref();
		};

		proc.stdout!.setEncoding("utf-8");
		proc.stdout!.on("data", (chunk: string) => {
			try { fs.appendFileSync(stdoutArtifact, chunk); } catch {}
			buffer += chunk;
			const lines = buffer.split("\n");
			buffer = lines.pop() || "";
			for (const line of lines) { processLine(state, line); maybeFinishFromAgentEnd(); }
			flush();
		});

		proc.stderr!.setEncoding("utf-8");
		proc.stderr!.on("data", (chunk: string) => {
			try { fs.appendFileSync(stderrArtifact, chunk); } catch {}
			if (chunk.trim()) {
				state.lastOutput = chunk.trim();
				flush();
			}
		});

		proc.on("close", (code) => {
			didClose = true;
			finishRun(code ?? 0);
		});

		proc.on("error", (err: Error) => {
			state.status = "error";
			state.proc = undefined;
			state.lastOutput = `Error: ${err.message}`;
			cleanupTemp(promptFile?.path ?? null, promptFile?.dir ?? null);
			cleanupTempDir(artifactDir);
			flush();
			resolve("");
		});
	});
}

// ── Async Runner (fire-and-forget) ────────────────────────────────────────────

async function runSubagentAsync(
	state: SubState,
	agentConfig: AgentConfig,
	ctx: any,
	flush: () => void,
): Promise<void> {
	const settings = resolveSettings(ctx.cwd ?? process.cwd());
	const model = agentConfig.model ?? settings.model ?? ctx.model
		? `${ctx.model.provider}/${ctx.model.id}`
		: undefined;

	const promptFile = await writePromptFile(agentConfig.systemPrompt ?? "", agentConfig.name);

	const args = ["--mode", "json", "-p", "--no-session"];
	const extensions = mergeExtensions(settings, agentConfig);
	if (settings.extensions !== null) args.push("--no-extensions");
	for (const ext of extensions) args.push("--extension", ext);
	if (model) args.push("--model", model);
	if (agentConfig.thinking) args.push("--thinking", agentConfig.thinking);
	if (agentConfig.skills?.length) for (const skill of agentConfig.skills) args.push("--skill", skill);
	if (agentConfig.tools && agentConfig.tools.length > 0) args.push("--tools", agentConfig.tools.join(","));
	if (promptFile) args.push("--append-system-prompt", promptFile.path);
	args.push(`Task: ${state.task}`);

	fs.mkdirSync(RESULTS_DIR, { recursive: true });
	const resultFile = path.join(RESULTS_DIR, `subagent-${state.id}-${Date.now()}.json`);

	const invocation = getPiInvocation(args);
	const proc = spawn(invocation.command, invocation.args, {
		stdio: ["ignore", "pipe", "pipe"],
		env: buildChildEnv(settings),
		detached: true,
	});

	state.proc = proc;
	state.status = "running";
	flush();

	let buffer = "";
	proc.stdout!.setEncoding("utf-8");
	proc.stdout!.on("data", (chunk: string) => {
		buffer += chunk;
		const lines = buffer.split("\n");
		buffer = lines.pop() || "";
		for (const line of lines) processLine(state, line);
		// Periodically write progress
		try {
			fs.writeFileSync(resultFile + ".progress", JSON.stringify({
				id: state.id, agent: state.agentName, task: state.task,
				toolCount: state.toolCount, currentTool: state.currentTool,
				elapsed: Date.now() - state.startTime, status: "running",
			}), "utf-8");
		} catch {}
		flush();
	});

	proc.on("close", (code) => {
		state.elapsed = Date.now() - state.startTime;
		state.status = code === 0 ? "done" : "error";
		state.proc = undefined;
		state.currentTool = undefined;
		state.resultText = state.textChunks.join("");

		// Write final result
		try {
			fs.writeFileSync(resultFile, JSON.stringify({
				id: state.id, agent: state.agentName, task: state.task,
				status: state.status, exitCode: code,
				result: state.resultText.slice(0, 50000),
				toolCount: state.toolCount, elapsed: state.elapsed,
				timestamp: Date.now(),
			}), "utf-8");
			try { fs.unlinkSync(resultFile + ".progress"); } catch {}
		} catch {}

		flush();
		ctx.ui.notify(
			`Subagent #${state.id} ${state.status} in ${fmtDuration(state.elapsed)}`,
			state.status === "done" ? "success" : "error",
		);
		cleanupTemp(promptFile?.path ?? null, promptFile?.dir ?? null);
		try { proc.unref(); } catch {}
	});

	proc.on("error", () => {
		state.status = "error";
		state.proc = undefined;
		cleanupTemp(promptFile?.path ?? null, promptFile?.dir ?? null);
		flush();
	});

	try { proc.unref(); } catch {}
}

// ── Extension ────────────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
	// Widget state
	const subs: Map<number, SubState> = new Map();
	let nextId = 1;
	let animTimer: ReturnType<typeof setInterval> | null = null;
	let currentCtx: any = null;
	let widgetName = "subagents";

	// Agent discovery
	let discoveredAgents: AgentConfig[] = [];
	let agentMap: Map<string, AgentConfig> = new Map();

	// ── Widget flush: re-renders widget using setWidget ───────────────────

	function flush() {
		if (!currentCtx) return;
		if (subs.size === 0) {
			currentCtx.ui.setWidget(widgetName, undefined);
			return;
		}
		const lines = renderWidgetLines(subs, currentCtx.ui.theme, process.stdout.columns ?? 80);
		currentCtx.ui.setWidget(widgetName, lines);
	}

	// ── Animation timer ───────────────────────────────────────────────────

	const AUTO_CLEAR_MS = 30_000; // Auto-clear completed agents after 30s
	let autoClearTimer: ReturnType<typeof setTimeout> | null = null;

	function startAnimation() {
		if (animTimer) return;
		animTimer = setInterval(() => {
			const hasRunning = Array.from(subs.values()).some(s => s.status === "running");
			if (!hasRunning) {
				stopAnimation();
				// Start auto-clear timer for completed agents
				scheduleAutoClear();
				return;
			}
			try { flush(); } catch { stopAnimation(); }
		}, 200);
		if (animTimer.unref) animTimer.unref();
	}

	function stopAnimation() {
		if (animTimer) { clearInterval(animTimer); animTimer = null; }
	}

	function scheduleAutoClear() {
		if (autoClearTimer) return;
		const entries = Array.from(subs.values());
		const allDone = entries.every(s => s.status !== "running");
		const hasErrors = entries.some(s => s.status === "error");
		if (!allDone || subs.size === 0 || hasErrors) return; // Don't auto-clear if errors exist
		autoClearTimer = setTimeout(() => {
			autoClearTimer = null;
			// Only clear if still all done and no errors
			const e = Array.from(subs.values());
			if (e.every(s => s.status !== "running") && !e.some(s => s.status === "error")) {
				subs.clear();
				nextId = 1;
				flush();
			}
		}, AUTO_CLEAR_MS);
		if (autoClearTimer.unref) autoClearTimer.unref();
	}

	function cancelAutoClear() {
		if (autoClearTimer) { clearTimeout(autoClearTimer); autoClearTimer = null; }
	}

	// ── Discover agents on session start ──────────────────────────────────

	pi.on("session_start", async (_event, ctx) => {
		currentCtx = ctx;
		const cwd = ctx.cwd;
		const discovery = discoverAgents(cwd, "both");
		discoveredAgents = discovery.agents;
		agentMap = new Map(discoveredAgents.map((a) => [a.name, a]));
	});

	// ── Helper: create a SubState ─────────────────────────────────────────

	function createSubState(agentName: string, task: string): SubState {
		const id = nextId++;
		const taskPreview = task.length > 40 ? task.slice(0, 37) + "…" : task;
		return {
			id, agentName, task, taskPreview,
			status: "running",
			textChunks: [], lastOutput: undefined,
			currentTool: undefined, currentToolStartedAt: undefined,
			toolCount: 0, turnCount: 1,
			elapsed: 0, startTime: Date.now(),
			sessionFile: makeSessionFile(id),
			toolExecutions: [], toolExecutionCount: 0,
			stdoutTail: [],
		};
	}

	// ── Helper: spawn and track ───────────────────────────────────────────

	function spawnSync(state: SubState, agentConfig: AgentConfig): Promise<string> {
		cancelAutoClear();
		subs.set(state.id, state);
		startAnimation();
		flush();
		return runSubagentWithWidget(state, agentConfig, currentCtx, flush);
	}

	function spawnAsync(state: SubState, agentConfig: AgentConfig): void {
		cancelAutoClear();
		subs.set(state.id, state);
		startAnimation();
		flush();
		runSubagentAsync(state, agentConfig, currentCtx, flush);
	}

	// ── Tool: subagent_create ─────────────────────────────────────────────

	pi.registerTool({
		name: "subagent_create",
		description: "Spawn a subagent with live widget. Returns immediately while it runs in background.",
		parameters: Type.Object({
			agent: Type.String({ description: "Agent name (from ~/.pi/agent/agents/*.md)" }),
			task: Type.String({ description: "Task description" }),
			async: Type.Optional(Type.Boolean({ description: "Fire-and-forget: don't block, notify when done (default: false)" })),
		}),
		async execute(_callId, args, _signal, _onUpdate, ctx) {
			currentCtx = ctx;
			if (discoveredAgents.length === 0) {
				return { content: [{ type: "text", text: "No agents found. Create agents in ~/.pi/agent/agents/*.md" }], isError: true };
			}
			const agentConfig = agentMap.get(args.agent);
			if (!agentConfig) {
				const available = discoveredAgents.map(a => a.name).join(", ");
				return { content: [{ type: "text", text: `Unknown agent: ${args.agent}. Available: ${available}` }], isError: true };
			}

			const state = createSubState(args.agent, args.task);

			if (args.async) {
				spawnAsync(state, agentConfig);
				return { content: [{ type: "text", text: `Subagent #${state.id} spawned async with ${args.agent}. Will notify on completion.` }] };
			}

			const result = await spawnSync(state, agentConfig);
			return { content: [{ type: "text", text: result || "(no output)" }] };
		},

		renderCall(args: any, theme: any) {
			const icon = args.async ? "⟳" : "▶";
			let text = theme.fg("toolTitle", theme.bold("subagent_create "));
			text += theme.fg("accent", `${icon} ${args.agent}`);
			const preview = args.task?.length > 50 ? args.task.slice(0, 47) + "…" : args.task;
			text += " " + theme.fg("muted", `"${preview}"`);
			return { render: () => [text] };
		},

		renderResult(result: any, { isPartial }: { isPartial: boolean }, theme: any) {
			if (isPartial) return { render: () => [theme.fg("warning", "⠙ Running subagent...")] };
			const text = result.content?.[0]?.text ?? "";
			if (text.includes("Error") || text.includes("error")) return { render: () => [theme.fg("error", text.slice(0, 80))] };
			const preview = text.length > 80 ? text.slice(0, 77) + "…" : text;
			return { render: () => [theme.fg("success", "✓ ") + theme.fg("muted", preview)] };
		},
	});

	// ── Tool: subagent_continue ───────────────────────────────────────────

	pi.registerTool({
		name: "subagent_continue",
		description: "Continue an existing subagent's conversation.",
		parameters: Type.Object({
			id: Type.Number({ description: "Subagent ID" }),
			task: Type.String({ description: "Follow-up task" }),
		}),
		async execute(_callId, args, _signal, _onUpdate, ctx) {
			currentCtx = ctx;
			const state = subs.get(args.id);
			if (!state) return { content: [{ type: "text", text: `No subagent #${args.id} found.` }] };
			if (state.status === "running") return { content: [{ type: "text", text: `Subagent #${args.id} is still running.` }] };

			state.status = "running";
			state.task = args.task;
			state.textChunks = [];
			state.lastOutput = undefined;
			state.currentTool = undefined;
			state.elapsed = 0;
			state.startTime = Date.now();
			state.turnCount++;
			startAnimation();
			flush();

			const agentConfig = agentMap.get(state.agentName)!;
			const result = await runSubagentWithWidget(state, agentConfig, ctx, flush);
			return { content: [{ type: "text", text: result || "(no output)" }] };
		},
	});

	// ── Tool: subagent_remove ─────────────────────────────────────────────

	pi.registerTool({
		name: "subagent_remove",
		description: "Remove a subagent.",
		parameters: Type.Object({ id: Type.Number({ description: "Subagent ID" }) }),
		execute: async (_callId, args, _signal, _onUpdate, ctx) => {
			currentCtx = ctx;
			const state = subs.get(args.id);
			if (!state) return { content: [{ type: "text", text: `No subagent #${args.id} found.` }] };
			if (state.proc && state.status === "running") state.proc.kill("SIGTERM");
			subs.delete(args.id);
			flush();
			return { content: [{ type: "text", text: `Subagent #${args.id} removed.` }] };
		},
	});

	// ── Tool: subagent_list ───────────────────────────────────────────────

	pi.registerTool({
		name: "subagent_list",
		description: "List all subagents.",
		parameters: Type.Object({}),
		execute: async () => {
			if (subs.size === 0) return { content: [{ type: "text", text: "No active subagents." }] };
			const list = Array.from(subs.values()).map(s => {
				const icon = s.status === "running" ? "●" : s.status === "done" ? "✓" : "✗";
				return `#${s.id} ${icon} ${s.agentName} (Turn ${s.turnCount}, ${fmtDuration(s.elapsed)}) - ${s.taskPreview}`;
			}).join("\n");
			return { content: [{ type: "text", text: `Subagents:\n${list}` }] };
		},
	});

	// ── Commands ──────────────────────────────────────────────────────────

	pi.registerCommand("sub", {
		description: "Spawn a subagent: /sub <agent> <task>",
		handler: async (args, ctx) => {
			currentCtx = ctx;
			const trimmed = args?.trim() ?? "";
			const spaceIdx = trimmed.indexOf(" ");
			if (spaceIdx === -1) { ctx.ui.notify("Usage: /sub <agent> <task>", "error"); return; }
			const agentName = trimmed.slice(0, spaceIdx);
			const task = trimmed.slice(spaceIdx + 1).trim();
			if (!task) { ctx.ui.notify("Usage: /sub <agent> <task>", "error"); return; }
			if (discoveredAgents.length === 0) { ctx.ui.notify("No agents found.", "error"); return; }
			const agentConfig = agentMap.get(agentName);
			if (!agentConfig) { ctx.ui.notify(`Unknown agent: ${agentName}. Available: ${discoveredAgents.map(a => a.name).join(", ")}`, "error"); return; }

			const state = createSubState(agentName, task);
			ctx.ui.notify(`Subagent #${state.id} started with ${agentName}...`, "info");
			const result = await spawnSync(state, agentConfig);
			ctx.ui.notify(`Subagent #${state.id} finished in ${fmtDuration(state.elapsed)}`, state.status === "done" ? "success" : "error");
		},
	});

	pi.registerCommand("subcont", {
		description: "Continue a subagent: /subcont <id> <task>",
		handler: async (args, ctx) => {
			currentCtx = ctx;
			const trimmed = args?.trim() ?? "";
			const spaceIdx = trimmed.indexOf(" ");
			if (spaceIdx === -1) { ctx.ui.notify("Usage: /subcont <id> <task>", "error"); return; }
			const num = parseInt(trimmed.slice(0, spaceIdx), 10);
			const task = trimmed.slice(spaceIdx + 1).trim();
			if (isNaN(num) || !task) { ctx.ui.notify("Usage: /subcont <id> <task>", "error"); return; }
			const state = subs.get(num);
			if (!state) { ctx.ui.notify(`No subagent #${num} found.`, "error"); return; }
			if (state.status === "running") { ctx.ui.notify(`Subagent #${num} is still running.`, "warning"); return; }

			state.status = "running"; state.task = task; state.textChunks = [];
			state.lastOutput = undefined; state.elapsed = 0; state.startTime = Date.now(); state.turnCount++;
			startAnimation();
			flush();
			ctx.ui.notify(`Continuing Subagent #${num} (Turn ${state.turnCount})…`, "info");

			await runSubagentWithWidget(state, agentMap.get(state.agentName)!, ctx, flush);
		},
	});

	pi.registerCommand("subrm", {
		description: "Remove a subagent: /subrm <id>",
		handler: async (args, ctx) => {
			currentCtx = ctx;
			const num = parseInt(args?.trim() ?? "", 10);
			if (isNaN(num)) { ctx.ui.notify("Usage: /subrm <id>", "error"); return; }
			const state = subs.get(num);
			if (!state) { ctx.ui.notify(`No subagent #${num} found.`, "error"); return; }
			if (state.proc && state.status === "running") { state.proc.kill("SIGTERM"); ctx.ui.notify(`Subagent #${num} killed.`, "warning"); }
			else ctx.ui.notify(`Subagent #${num} removed.`, "info");
			subs.delete(num);
			flush();
		},
	});

	pi.registerCommand("subclear", {
		description: "Clear all subagent widgets",
		handler: async (_args, ctx) => {
			currentCtx = ctx;
			let killed = 0;
			for (const [, state] of subs.entries()) {
				if (state.proc && state.status === "running") { state.proc.kill("SIGTERM"); killed++; }
			}
			const total = subs.size;
			subs.clear();
			nextId = 1;
			stopAnimation();
			flush();
			const msg = total === 0 ? "No subagents to clear." : `Cleared ${total} subagent${total !== 1 ? "s" : ""}${killed > 0 ? ` (${killed} killed)` : ""}.`;
			ctx.ui.notify(msg, total === 0 ? "info" : "success");
		},
	});

	// ── Original subagents tool (single/parallel/chain with rich progress) ─

	pi.registerTool({
		name: "subagents",
		label: "Subagents",
		description: "Run specialized subagents with progress tracking. Agents loaded from ~/.pi/agent/agents/*.md",
		parameters: Type.Object({
			mode: StringEnum(["single", "parallel", "chain"] as const, { description: "Execution mode", default: "single" }),
			agent: Type.Optional(Type.String({ description: "Agent name (single mode)" })),
			task: Type.Optional(Type.String({ description: "Task (single mode)" })),
			tasks: Type.Optional(Type.Array(Type.Object({
				agent: Type.String(), task: Type.String(), cwd: Type.Optional(Type.String()),
			}))),
			chain: Type.Optional(Type.Array(Type.Object({
				agent: Type.String(), task: Type.String({ description: "Use {previous} to reference prior output" }),
				cwd: Type.Optional(Type.String()),
			}))),
			agentScope: Type.Optional(StringEnum(["user", "project", "both"] as const, { default: "both" })),
			cwd: Type.Optional(Type.String()),
		}),

		async execute(_toolCallId, params, signal, onUpdate, ctx) {
			currentCtx = ctx;
			const cwd = params.cwd ?? ctx.cwd;
			const agents = discoveredAgents;

			if (agents.length === 0) {
				return {
					content: [{ type: "text", text: "No agents found. Create agents in ~/.pi/agent/agents/*.md" }],
					details: { mode: "single", results: [], runningCount: 0, completedCount: 0, failedCount: 0, availableAgents: "none" } as SubagentDetails,
					isError: true,
				};
			}

			const availableNames = agents.map(a => `${a.name} (${a.source})`).join(", ");

			// ── Single mode ────────────────────────────────────────────────
			if (params.mode === "single" && params.agent && params.task) {
				const agentConfig = agentMap.get(params.agent);
				if (!agentConfig) {
					return { content: [{ type: "text", text: `Unknown agent: ${params.agent}. Available: ${availableNames}` }], isError: true };
				}

				const state = createSubState(params.agent, params.task);
				subs.set(state.id, state);
				startAnimation();
				flush();

				const result = await runSubagentInline(agentConfig, params.task, cwd, signal, (r) => {
					state.toolCount = r.usage.turns;
					state.elapsed = Date.now() - state.startTime;
					state.status = r.status === "running" ? "running" : r.status === "completed" ? "done" : "error";
					flush();
					onUpdate?.({
						content: [{ type: "text", text: getFinalOutput(r.messages) || "(running...)" }],
						details: { mode: "single", results: [r], runningCount: r.status === "running" ? 1 : 0,
							completedCount: r.status === "completed" ? 1 : 0, failedCount: r.status === "failed" ? 1 : 0, availableAgents: availableNames },
					});
				});

				state.status = result.status === "completed" ? "done" : "error";
				state.elapsed = Date.now() - state.startTime;
				state.resultText = getFinalOutput(result.messages);
				flush();

				return {
					content: [{ type: "text", text: getFinalOutput(result.messages) || "(no output)" }],
					details: { mode: "single", results: [result], runningCount: 0, completedCount: result.status === "completed" ? 1 : 0, failedCount: result.status === "failed" ? 1 : 0, availableAgents: availableNames },
					isError: result.status === "failed",
				};
			}

			// ── Parallel mode ──────────────────────────────────────────────
			if (params.mode === "parallel" && params.tasks && params.tasks.length > 0) {
				const tasks = params.tasks;
				const invalidAgents = tasks.filter(t => !agentMap.get(t.agent));
				if (invalidAgents.length > 0) {
					return { content: [{ type: "text", text: `Unknown agents: ${invalidAgents.map(t => t.agent).join(", ")}. Available: ${availableNames}` }], isError: true };
				}

				// Create widget states for each parallel task
				const parallelStates: SubState[] = tasks.map(t => {
					const s = createSubState(t.agent, t.task);
					subs.set(s.id, s);
					return s;
				});
				startAnimation();
				flush();

				const results: SubagentResult[] = new Array(tasks.length);
				let completed = 0;

				const runTask = async (task: typeof tasks[0], index: number) => {
					const agentConfig = agentMap.get(task.agent)!;
					const state = parallelStates[index]!;

					const result = await runSubagentInline(agentConfig, task.task, task.cwd ?? cwd, signal, (r) => {
						results[index] = r;
						state.toolCount = r.usage.turns;
						state.elapsed = Date.now() - state.startTime;
						state.status = r.status === "running" ? "running" : r.status === "completed" ? "done" : "error";
						flush();

						const running = results.filter(r => r?.status === "running").length;
						onUpdate?.({
							content: [{ type: "text", text: `Progress: ${completed}/${tasks.length} done` }],
							details: { mode: "parallel", results: results.filter((r): r is SubagentResult => r !== undefined),
								runningCount: running, completedCount: results.filter(r => r?.status === "completed").length,
								failedCount: results.filter(r => r?.status === "failed").length, availableAgents: availableNames },
						});
					});
					results[index] = result;
					completed += result.status === "completed" ? 1 : 0;
					state.status = result.status === "completed" ? "done" : "error";
					state.elapsed = Date.now() - state.startTime;
					state.resultText = getFinalOutput(result.messages);
					flush();
					return result;
				};

				const concurrency = Math.min(4, tasks.length);
				const chunks: typeof tasks[] = [];
				for (let i = 0; i < tasks.length; i += concurrency) chunks.push(tasks.slice(i, i + concurrency));
				for (const chunk of chunks) {
					await Promise.all(chunk.map((task, i) => runTask(task, tasks.indexOf(task))));
				}

				return {
					content: [{ type: "text", text: `Parallel complete: ${completed}/${tasks.length} succeeded` }],
					details: { mode: "parallel", results, runningCount: 0, completedCount: completed, failedCount: tasks.length - completed, availableAgents: availableNames },
				};
			}

			// ── Chain mode ─────────────────────────────────────────────────
			if (params.mode === "chain" && params.chain && params.chain.length > 0) {
				const steps = params.chain;
				const invalidAgents = steps.filter(s => !agentMap.get(s.agent));
				if (invalidAgents.length > 0) {
					return { content: [{ type: "text", text: `Unknown agents: ${invalidAgents.map(s => s.agent).join(", ")}. Available: ${availableNames}` }], isError: true };
				}

				const results: SubagentResult[] = [];
				let previousOutput = "";
				let completed = 0;

				for (let i = 0; i < steps.length; i++) {
					const step = steps[i];
					const agentConfig = agentMap.get(step.agent)!;
					const task = step.task.replace(/\{previous\}/g, previousOutput);

					const state = createSubState(step.agent, task);
					subs.set(state.id, state);
					startAnimation();
					flush();

					const result = await runSubagentInline(agentConfig, task, step.cwd ?? cwd, signal, (r) => {
						const allResults = [...results, r];
						state.toolCount = r.usage.turns;
						state.elapsed = Date.now() - state.startTime;
						state.status = r.status === "running" ? "running" : r.status === "completed" ? "done" : "error";
						flush();

						onUpdate?.({
							content: [{ type: "text", text: `Step ${i + 1}/${steps.length}: ${r.status}` }],
							details: { mode: "chain", results: allResults, runningCount: r.status === "running" ? 1 : 0,
								completedCount: allResults.filter(r => r.status === "completed").length, failedCount: allResults.filter(r => r.status === "failed").length, availableAgents: availableNames },
						});
					});

					results.push(result);
					state.status = result.status === "completed" ? "done" : "error";
					state.elapsed = Date.now() - state.startTime;
					state.resultText = getFinalOutput(result.messages);
					flush();

					if (result.status === "completed") {
						completed++;
						previousOutput = getFinalOutput(result.messages);
					} else {
						break;
					}
				}

				return {
					content: [{ type: "text", text: `Chain complete: ${completed}/${steps.length} steps` }],
					details: { mode: "chain", results, runningCount: 0, completedCount: completed, failedCount: steps.length - completed, availableAgents: availableNames },
				};
			}

			return { content: [{ type: "text", text: `Invalid parameters. Available agents: ${availableNames}` }], isError: true };
		},

		renderCall(args: any, theme: any) {
			const modeIcon: Record<string, string> = { single: "▶", parallel: "⟐", chain: "⟾" };
			const icon = modeIcon[args.mode] ?? "▶";
			let text = theme.fg("toolTitle", theme.bold("subagents "));
			text += theme.fg("accent", `${icon} ${args.mode}`);
			if (args.agent) text += " " + theme.fg("dim", args.agent);
			const count = args.tasks?.length ?? args.chain?.length ?? 0;
			if (count > 0) text += " " + theme.fg("muted", `×${count}`);
			return { render: () => [text] };
		},

		renderResult(result: any, { isPartial }: { isPartial: boolean }, theme: any) {
			if (isPartial) return { render: () => [theme.fg("warning", "⠙ Running subagents...")] };
			const text = result.content?.[0]?.text ?? "";
			if (result.isError) return { render: () => [theme.fg("error", text.slice(0, 100))] };
			return { render: () => [theme.fg("success", "✓ ") + theme.fg("muted", text.slice(0, 80))] };
		},
	});

	// ── Inline runner (for single/parallel/chain modes) ───────────────────

	async function runSubagentInline(
		agentConfig: AgentConfig, task: string, cwd: string,
		signal: AbortSignal | undefined, onUpdate: ((result: SubagentResult) => void) | undefined,
	): Promise<SubagentResult> {
		const settings = resolveSettings(cwd);
		const result: SubagentResult = {
			agent: agentConfig.name, task, status: "running", exitCode: -1, messages: [], stderr: "",
			usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, contextTokens: 0, turns: 0 },
			step: undefined, startTime: Date.now(), agentSource: agentConfig.source,
		};

		const args: string[] = ["--mode", "json", "-p", "--no-session"];
		const extensions = mergeExtensions(settings, agentConfig);
		if (settings.extensions !== null) args.push("--no-extensions");
		for (const ext of extensions) args.push("--extension", ext);
		const model = agentConfig.model ?? settings.model;
		if (model) args.push("--model", model);
		if (agentConfig.thinking) args.push("--thinking", agentConfig.thinking);
		if (agentConfig.skills?.length) for (const skill of agentConfig.skills) args.push("--skill", skill);
		if (agentConfig.tools && agentConfig.tools.length > 0) args.push("--tools", agentConfig.tools.join(","));
		args.push(`Task: ${task}`);

		let tmpPromptPath: string | null = null;
		let tmpPromptDir: string | null = null;

		try {
			if (agentConfig.systemPrompt?.trim()) {
				tmpPromptDir = await fs.promises.mkdtemp(path.join(os.tmpdir(), "pi-subagent-"));
				tmpPromptPath = path.join(tmpPromptDir, `prompt-${agentConfig.name.replace(/[^\w.-]/g, "_")}.md`);
				await fs.promises.writeFile(tmpPromptPath!, agentConfig.systemPrompt, { encoding: "utf-8", mode: 0o600 });
				args.push("--append-system-prompt", tmpPromptPath);
			}

			const exitCode = await new Promise<number>((resolve) => {
				const invocation = getPiInvocation(args);
				const proc = spawn(invocation.command, invocation.args, { cwd, shell: false, stdio: ["pipe", "pipe", "pipe"], env: buildChildEnv(settings) });
				proc.stdin.on("error", () => {});
				proc.stdin.end();
				let buffer = "";

				const processLine = (line: string) => {
					if (!line.trim()) return;
					try {
						const event = JSON.parse(line);
						if (event.type === "message_end" && event.message) {
							const msg = event.message as Message;
							result.messages.push(msg);
							if (msg.role === "assistant") {
								result.usage.turns++;
								if (msg.usage) {
									result.usage.input += msg.usage.input || 0;
									result.usage.output += msg.usage.output || 0;
									result.usage.cacheRead += msg.usage.cacheRead || 0;
									result.usage.cacheWrite += msg.usage.cacheWrite || 0;
									result.usage.cost += msg.usage.cost?.total || 0;
									result.usage.contextTokens = Math.max(result.usage.contextTokens, msg.usage.totalTokens || 0);
								}
								if (!result.model && msg.model) result.model = msg.model;
							}
							onUpdate?.(result);
						}
					} catch {}
				};

				proc.stdout.on("data", (data: Buffer) => {
					buffer += data.toString();
					const lines = buffer.split("\n");
					buffer = lines.pop() || "";
					for (const line of lines) processLine(line);
				});

				proc.stderr.on("data", (data: Buffer) => { result.stderr += data.toString(); });
				proc.on("close", (code) => { if (buffer.trim()) processLine(buffer); resolve(code ?? 0); });
				proc.on("error", () => resolve(1));

				if (signal) {
					const killProc = () => { proc.kill("SIGTERM"); setTimeout(() => !proc.killed && proc.kill("SIGKILL"), 5000); };
					if (signal.aborted) killProc();
					else signal.addEventListener("abort", killProc, { once: true });
				}
			});

			result.exitCode = exitCode;
			result.status = exitCode === 0 ? "completed" : "failed";
			result.endTime = Date.now();
			return result;
		} finally {
			if (tmpPromptPath) try { fs.unlinkSync(tmpPromptPath); } catch {}
			if (tmpPromptDir) try { fs.rmSync(tmpPromptDir, { recursive: true, force: true }); } catch {}
		}
	}

	// ── Cleanup on shutdown ───────────────────────────────────────────────

	pi.on("session_shutdown", async () => {
		stopAnimation();
		cancelAutoClear();
		for (const [, state] of subs.entries()) {
			if (state.proc && state.status === "running") state.proc.kill("SIGTERM");
		}
	});
}
