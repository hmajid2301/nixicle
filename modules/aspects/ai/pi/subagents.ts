// @ts-nocheck
/**
 * Subagents Extension - rewritten around a clean run/step lifecycle.
 *
 * Goals:
 * - compact high-level bottom widget only
 * - chain steps materialize up front (future steps visible as waiting)
 * - responsive inline rendering (wide: boxes, medium/narrow: pills + detail)
 * - settled runs auto-collapse and eventually clear
 * - simpler execution model with fewer stale-state bugs
 */

import { spawn } from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import type { Message } from "@mariozechner/pi-ai";
import { StringEnum } from "@mariozechner/pi-ai";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { getAgentDir, parseFrontmatter } from "@mariozechner/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";
import { Type } from "typebox";

function safeWidth(): number {
	return Math.max(1, (process.stdout.columns ?? 80) - 1);
}

// ─────────────────────────────────────────────────────────────────────────────
// Agent discovery + settings
// ─────────────────────────────────────────────────────────────────────────────

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

interface Settings {
	model: string | null;
	extensions: string[] | null;
	environment: Record<string, string>;
}

const SETTINGS_KEY = "pi-subagents";
const RESULTS_DIR = path.join(os.homedir(), ".pi", "agent", "sessions", "subagents", "results");
const SESSION_DIR = path.join(os.homedir(), ".pi", "agent", "sessions", "subagents");
const RECENT_SETTLED_MS = 5 * 60_000;
const FAILED_KEEP_MS = 30 * 60_000;
const MAX_RECENT_SETTLED = 8;
const SPINNER = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
const SPINNER_MS = 80;

function loadAgentsFromDir(dir: string, source: "user" | "project"): AgentConfig[] {
	const agents: AgentConfig[] = [];
	if (!fs.existsSync(dir)) return agents;
	let entries: fs.Dirent[] = [];
	try { entries = fs.readdirSync(dir, { withFileTypes: true }); } catch { return agents; }

	for (const entry of entries) {
		if (!entry.name.endsWith(".md")) continue;
		if (!entry.isFile() && !entry.isSymbolicLink()) continue;
		const filePath = path.join(dir, entry.name);
		let content = "";
		try { content = fs.readFileSync(filePath, "utf-8"); } catch { continue; }
		const { frontmatter, body } = parseFrontmatter<Record<string, string>>(content);
		if (!frontmatter.name || !frontmatter.description) continue;
		const tools = frontmatter.tools?.split(",").map((s) => s.trim()).filter(Boolean);
		const extensions = frontmatter.extensions?.split(",").map((s) => s.trim()).filter(Boolean);
		const skills = frontmatter.skills?.split(",").map((s) => s.trim()).filter(Boolean);
		agents.push({
			name: frontmatter.name,
			description: frontmatter.description,
			tools: tools?.length ? tools : undefined,
			model: frontmatter.model,
			extensions: extensions?.length ? extensions : undefined,
			skills: skills?.length ? skills : undefined,
			thinking: frontmatter.thinking || undefined,
			systemPrompt: body,
			source,
			filePath,
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
	const merged = new Map<string, AgentConfig>();
	const list = scope === "both" ? [...userAgents, ...projectAgents] : scope === "user" ? userAgents : projectAgents;
	for (const agent of list) merged.set(agent.name, agent);
	return { agents: Array.from(merged.values()), projectAgentsDir: projectDir };
}

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
	for (const [k, v] of Object.entries(value as Record<string, unknown>)) {
		if (typeof v !== "string") continue;
		const key = k.trim();
		if (!key || key.includes("=") || key.includes("\0") || v.includes("\0")) continue;
		env[key] = v;
	}
	return env;
}

function mergeEnvironment(base: Record<string, string> | undefined, overrides: Record<string, string> | undefined): Record<string, string> {
	const env = { ...(base ?? {}) };
	if (!overrides) return env;
	if (process.platform === "win32") {
		for (const [k, v] of Object.entries(overrides)) {
			const nk = k.toLowerCase();
			for (const key of Object.keys(env)) if (key.toLowerCase() === nk) delete env[key];
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
			.filter((x): x is string => typeof x === "string" && x.trim().length > 0)
			.map((x) => resolveConfiguredPath(x.trim(), baseDir));
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
		model: null,
		extensions: null,
		...gs,
		...ps,
		environment: mergeEnvironment(gs.environment, ps.environment),
	};
}

function mergeExtensions(settings: Settings, agent: AgentConfig): string[] {
	return [...new Set([...(settings.extensions ?? []), ...(agent.extensions ?? [])])];
}

function buildChildEnv(settings: Settings): NodeJS.ProcessEnv {
	if (process.platform === "win32") {
		const inherited = { ...process.env };
		for (const [k, v] of Object.entries(settings.environment)) {
			const nk = k.toLowerCase();
			for (const key of Object.keys(inherited)) if (key.toLowerCase() === nk) delete inherited[key];
			inherited[k] = v;
		}
		return inherited;
	}
	return { ...process.env, ...settings.environment };
}

// ─────────────────────────────────────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────────────────────────────────────

type StepStatus = "queued" | "running" | "waiting" | "done" | "failed" | "aborted";
type RunMode = "single" | "parallel" | "chain";

interface StepState {
	id: number;
	runId: number;
	index: number;
	agentName: string;
	task: string;
	cwd: string;
	status: StepStatus;
	startTime?: number;
	endTime?: number;
	elapsedMs: number;
	turnCount: number;
	toolCount: number;
	tokenCount: number;
	currentTool?: string;
	lastOutput?: string;
	error?: string;
	stderrTail: string[];
	messages: Message[];
	proc?: ReturnType<typeof spawn>;
	resultText?: string;
	sessionFile: string;
	resultFile?: string;
}

interface RunState {
	id: number;
	mode: RunMode;
	label: string;
	steps: StepState[];
	status: StepStatus;
	createdAt: number;
	updatedAt: number;
	async: boolean;
	keepVisibleUntil?: number;
}

interface UsageStats {
	input: number;
	output: number;
	cacheRead: number;
	cacheWrite: number;
	cost: number;
	contextTokens: number;
	turns: number;
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

interface ToolDetails {
	mode: RunMode;
	runs: Array<{
		id: number;
		label: string;
		mode: RunMode;
		status: StepStatus;
		steps: Array<{
			id: number;
			index: number;
			agentName: string;
			task: string;
			status: StepStatus;
			elapsedMs: number;
			turnCount: number;
			toolCount: number;
			tokenCount: number;
			currentTool?: string;
			lastOutput?: string;
			error?: string;
		}>;
	}>;
	results?: SubagentResult[];
	runningCount: number;
	queuedCount: number;
	waitingCount: number;
	completedCount: number;
	failedCount: number;
	availableAgents?: string;
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

function spinnerFrame(): string {
	return SPINNER[Math.floor(Date.now() / SPINNER_MS) % SPINNER.length]!;
}

function fmtDuration(ms: number): string {
	const s = Math.floor(ms / 1000);
	if (s < 60) return `${s}s`;
	const m = Math.floor(s / 60);
	if (m < 60) return `${m}m${s % 60}s`;
	return `${Math.floor(m / 60)}h${m % 60}m`;
}

function formatCount(n: number): string {
	if (!Number.isFinite(n) || n <= 0) return "0";
	if (n < 1000) return `${Math.round(n)}`;
	if (n < 10_000) return `${(n / 1000).toFixed(1)}k`;
	if (n < 1_000_000) return `${Math.round(n / 1000)}k`;
	return `${(n / 1_000_000).toFixed(1)}M`;
}

function truncateInline(text: string, maxChars: number): string {
	const single = text.replace(/\s+/g, " ").trim();
	if (single.length <= maxChars) return single;
	return `${single.slice(0, Math.max(0, maxChars - 1))}…`;
}

function stripAnsi(text: string): string {
	return text.replace(/\x1b\[[0-9;]*m/g, "").replace(/\x1b\][^\x07]*(\x07|\x1b\\)/g, "");
}

function getPiInvocation(args: string[]): { command: string; args: string[] } {
	const currentScript = process.argv[1];
	const isBunVirtualScript = currentScript?.startsWith("/$bunfs/root/");
	if (currentScript && !isBunVirtualScript && fs.existsSync(currentScript)) {
		return { command: process.execPath, args: [currentScript, ...args] };
	}
	const execName = path.basename(process.execPath).toLowerCase();
	if (!/^(node|bun)(\.exe)?$/.test(execName)) return { command: process.execPath, args };
	return { command: "pi", args };
}

function makeSessionFile(id: number): string {
	fs.mkdirSync(SESSION_DIR, { recursive: true });
	return path.join(SESSION_DIR, `subagent-${id}-${Date.now()}.jsonl`);
}

async function writePromptFile(systemPrompt: string, agentName: string): Promise<{ path: string; dir: string } | null> {
	if (!systemPrompt.trim()) return null;
	const dir = await fs.promises.mkdtemp(path.join(os.tmpdir(), "pi-subagent-"));
	const filePath = path.join(dir, `prompt-${agentName.replace(/[^\w.-]/g, "_")}.md`);
	await fs.promises.writeFile(filePath, systemPrompt, { encoding: "utf-8", mode: 0o600 });
	return { path: filePath, dir };
}

function cleanupTemp(promptFile?: { path: string; dir: string } | null) {
	if (!promptFile) return;
	try { fs.unlinkSync(promptFile.path); } catch {}
	try { fs.rmSync(promptFile.dir, { recursive: true, force: true }); } catch {}
}

function formatToolCallPreview(toolName: string, args: Record<string, unknown>): string {
	switch (toolName) {
		case "bash": {
			const c = typeof args.command === "string" ? args.command : "...";
			return `bash $ ${truncateInline(c, 72)}`;
		}
		case "read":
		case "write":
		case "edit": {
			const p = String(args.path || args.file_path || "...").replace(/^\/home\/[^/]+/, "~");
			return `${toolName} ${p}`;
		}
		default:
			return toolName || "tool";
	}
}

function extractTextFromMessage(msg: Message): string {
	const texts = msg.content.filter((part: any) => part.type === "text" && typeof part.text === "string").map((part: any) => part.text);
	return texts.join("\n").trim();
}

function getFinalOutput(messages: Message[]): string {
	for (let i = messages.length - 1; i >= 0; i--) {
		const msg = messages[i];
		if (msg.role !== "assistant") continue;
		const text = extractTextFromMessage(msg);
		if (text) return text;
	}
	return "";
}

function statusIcon(status: StepStatus): string {
	if (status === "running") return spinnerFrame();
	if (status === "done") return "✓";
	if (status === "failed") return "✗";
	if (status === "aborted") return "⊘";
	if (status === "waiting") return "○";
	return "○";
}

function compactStatus(status: StepStatus): string {
	if (status === "running") return spinnerFrame();
	if (status === "done") return "✓";
	if (status === "failed") return "✗";
	if (status === "aborted") return "⊘";
	if (status === "waiting") return "?";
	return "○";
}

function toToolDetails(runs: RunState[], results?: SubagentResult[], availableAgents?: string): ToolDetails {
	const allSteps = runs.flatMap((run) => run.steps);
	return {
		mode: runs[0]?.mode ?? "single",
		runs: runs.map((run) => ({
			id: run.id,
			label: run.label,
			mode: run.mode,
			status: run.status,
			steps: run.steps.map((step) => ({
				id: step.id,
				index: step.index,
				agentName: step.agentName,
				task: step.task,
				status: step.status,
				elapsedMs: step.elapsedMs,
				turnCount: step.turnCount,
				toolCount: step.toolCount,
				tokenCount: step.tokenCount,
				currentTool: step.currentTool,
				lastOutput: step.lastOutput,
				error: step.error,
			})),
		})),
		results,
		runningCount: allSteps.filter((s) => s.status === "running").length,
		queuedCount: allSteps.filter((s) => s.status === "queued").length,
		waitingCount: allSteps.filter((s) => s.status === "waiting").length,
		completedCount: allSteps.filter((s) => s.status === "done").length,
		failedCount: allSteps.filter((s) => s.status === "failed" || s.status === "aborted").length,
		availableAgents,
	};
}

// ─────────────────────────────────────────────────────────────────────────────
// Rendering
// ─────────────────────────────────────────────────────────────────────────────

function renderBottomWidget(runs: RunState[], theme: any, width: number): string[] {
	const steps = runs.flatMap((run) => run.steps);
	const running = steps.filter((s) => s.status === "running");
	const queued = steps.filter((s) => s.status === "queued");
	const waiting = steps.filter((s) => s.status === "waiting");
	const done = steps.filter((s) => s.status === "done");
	const failed = steps.filter((s) => s.status === "failed" || s.status === "aborted");
	const summary = [
		theme.bold("Subagents"),
		theme.fg("dim", " "),
		running.length ? theme.fg("accent", `●${running.length} running`) : "",
		queued.length ? theme.fg("dim", `⏳${queued.length} queued`) : "",
		waiting.length ? theme.fg("warning", `?${waiting.length} waiting`) : "",
		done.length ? theme.fg("success", `✓${done.length} done`) : "",
		failed.length ? theme.fg("error", `✗${failed.length} failed`) : "",
	].filter(Boolean).join(theme.fg("dim", " · "));
	const lines = [truncateToWidth(summary, width)];
	const secondParts: string[] = [];
	if (running.length) secondParts.push(`Running: ${running.map((s) => s.agentName).slice(0, 2).join(", ")}`);
	if (waiting.length) secondParts.push(`Waiting: ${waiting.map((s) => s.agentName).slice(0, 2).join(", ")}`);
	if (!running.length && !waiting.length && (done.length || failed.length)) secondParts.push("Recent done collapsed · /subclear to dismiss");
	if (secondParts.length) lines.push(truncateToWidth(secondParts.join("   "), width));
	return lines.map(line => truncateToWidth(line, width));
}

function boxForStep(step: ToolDetails["runs"][number]["steps"][number], width: number): string[] {
	const inner = Math.max(12, width - 3);
	const title = `${step.agentName}`;
	const line1 = `${compactStatus(step.status)} ${fmtDuration(step.elapsedMs)} · ${step.toolCount}t`;
	const line2 = truncateInline(step.currentTool || step.lastOutput || step.task, inner - 1);
	const top = `┌${"─".repeat(inner)}┐`;
	const mid1 = `│${title.padEnd(inner)}│`;
	const mid2 = `│${truncateToWidth(line1, inner).padEnd(inner)}│`;
	const mid3 = `│${truncateToWidth(line2, inner).padEnd(inner)}│`;
	const bottom = `└${"─".repeat(inner)}┘`;
	return [top, mid1, mid2, mid3, bottom];
}

function joinHorizontalBoxes(boxes: string[][], width: number): string[] {
	if (boxes.length === 0) return [];
	const height = Math.max(...boxes.map((b) => b.length));
	const lines: string[] = [];
	for (let row = 0; row < height; row++) {
		let line = "";
		for (let i = 0; i < boxes.length; i++) {
			line += boxes[i]![row] || "";
			if (i < boxes.length - 1) line += row === 2 ? " → " : "   ";
		}
		lines.push(truncateToWidth(line, width));
	}
	return lines.map(line => truncateToWidth(line, width));
}

function renderWideRun(run: ToolDetails["runs"][number], width: number): string[] {
	const lines: string[] = [];
	lines.push(truncateToWidth(`${run.mode === "chain" ? "Chain" : run.mode === "parallel" ? "Parallel" : "Run"} #${run.id} · ${run.label}`, width));
	lines.push("─".repeat(Math.min(width, 76)));
	const boxCount = Math.max(1, run.steps.length);
	const connectorWidth = (boxCount - 1) * 3;
	const boxWidth = Math.max(14, Math.min(24, Math.floor((width - connectorWidth - (boxCount - 1) * 3) / boxCount)));
	const boxes = run.steps.map((step) => boxForStep(step, boxWidth));
	lines.push(...joinHorizontalBoxes(boxes, width));
	return lines.map(line => truncateToWidth(line, width));
}

function renderStepPills(run: ToolDetails["runs"][number], width: number): string {
	const pills = run.steps.map((step) => `[${compactStatus(step.status)} ${step.agentName}${step.elapsedMs > 0 ? ` ${fmtDuration(step.elapsedMs)}` : ""}]`).join(" → ");
	return truncateToWidth(pills, width);
}

function renderDetailCard(step: ToolDetails["runs"][number]["steps"][number], width: number): string[] {
	const inner = Math.max(20, width - 3);
	const top = `┌${"─".repeat(inner)}┐`;
	const bottom = `└${"─".repeat(inner)}┘`;
	const lines = [
		top,
		`│${truncateToWidth(`${step.agentName}`, inner).padEnd(inner)}│`,
		`│${truncateToWidth(`task     ${truncateInline(step.task, inner - 9)}`, inner).padEnd(inner)}│`,
		`│${truncateToWidth(`tool     ${truncateInline(step.currentTool || "—", inner - 9)}`, inner).padEnd(inner)}│`,
		`│${truncateToWidth(`usage    ${step.toolCount}t · ${formatCount(step.tokenCount)} tok · ${fmtDuration(step.elapsedMs)}`, inner).padEnd(inner)}│`,
		`│${truncateToWidth(`${step.error ? "error" : "latest"}   ${truncateInline(step.error || step.lastOutput || "—", inner - 9)}`, inner).padEnd(inner)}│`,
		bottom,
	];
	return lines.map(line => truncateToWidth(line, width));
}

function renderMediumRun(run: ToolDetails["runs"][number], width: number): string[] {
	const lines: string[] = [];
	lines.push(truncateToWidth(`${run.mode === "chain" ? "Chain" : run.mode === "parallel" ? "Parallel" : "Run"} #${run.id}`, width));
	lines.push(renderStepPills(run, width));
	const active = run.steps.find((s) => s.status === "running")
		?? run.steps.find((s) => s.status === "failed")
		?? run.steps.find((s) => s.status === "waiting")
		?? run.steps[run.steps.length - 1];
	if (active) lines.push(...renderDetailCard(active, width));
	return lines.map(line => truncateToWidth(line, width));
}

function renderNarrowRun(run: ToolDetails["runs"][number], width: number): string[] {
	const lines: string[] = [];
	const pills = run.steps.map((step) => `[${compactStatus(step.status)} ${step.agentName[0] || "?"}]`).join(" ");
	lines.push(truncateToWidth(pills, width));
	const active = run.steps.find((s) => s.status === "running")
		?? run.steps.find((s) => s.status === "failed")
		?? run.steps.find((s) => s.status === "waiting")
		?? run.steps[run.steps.length - 1];
	if (active) lines.push(...renderDetailCard(active, width));
	return lines.map(line => truncateToWidth(line, width));
}

function renderRunDetails(runs: ToolDetails["runs"], width: number): string[] {
	const lines: string[] = [];
	for (const run of runs) {
		if (lines.length) lines.push("");
		if (width > 120 && run.mode === "chain") lines.push(...renderWideRun(run, width));
		else if (width >= 80) lines.push(...renderMediumRun(run, width));
		else lines.push(...renderNarrowRun(run, width));
	}
	return lines.map((line) => truncateToWidth(line, width));
}

// ─────────────────────────────────────────────────────────────────────────────
// Extension
// ─────────────────────────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
	let currentCtx: any = null;
	let nextRunId = 1;
	let nextStepId = 1;
	let animTimer: ReturnType<typeof setInterval> | null = null;
	let discoveredAgents: AgentConfig[] = [];
	let agentMap = new Map<string, AgentConfig>();
	const runs = new Map<number, RunState>();
	const steps = new Map<number, StepState>();

	function availableAgentsString() {
		return discoveredAgents.map((a) => `${a.name} (${a.source})`).join(", ");
	}

	function getActiveRuns(): RunState[] {
		const now = Date.now();
		const all = Array.from(runs.values());
		return all.filter((run) => {
			const hasLive = run.steps.some((s) => s.status === "running" || s.status === "queued" || s.status === "waiting");
			if (hasLive) return true;
			const hasFailed = run.steps.some((s) => s.status === "failed" || s.status === "aborted");
			if (hasFailed) return now - run.updatedAt < FAILED_KEEP_MS;
			return now - run.updatedAt < RECENT_SETTLED_MS;
		});
	}

	function refreshRunStatus(run: RunState) {
		run.updatedAt = Date.now();
		for (const step of run.steps) {
			if (step.status === "running" && step.startTime) step.elapsedMs = Date.now() - step.startTime;
		}
		const statuses = run.steps.map((s) => s.status);
		if (statuses.some((s) => s === "running")) run.status = "running";
		else if (statuses.some((s) => s === "failed")) run.status = "failed";
		else if (statuses.some((s) => s === "waiting" || s === "queued")) run.status = statuses.some((s) => s === "waiting") ? "waiting" : "queued";
		else if (statuses.every((s) => s === "done")) run.status = "done";
		else if (statuses.every((s) => s === "aborted")) run.status = "aborted";
		else run.status = "queued";
	}

	function pruneOldRuns() {
		const all = Array.from(runs.values());
		const now = Date.now();
		const settled = all
			.filter((run) => !run.steps.some((s) => s.status === "running" || s.status === "queued" || s.status === "waiting"))
			.sort((a, b) => b.updatedAt - a.updatedAt);
		for (let i = MAX_RECENT_SETTLED; i < settled.length; i++) {
			const run = settled[i]!;
			const hasFailed = run.steps.some((s) => s.status === "failed" || s.status === "aborted");
			const ttl = hasFailed ? FAILED_KEEP_MS : RECENT_SETTLED_MS;
			if (now - run.updatedAt < ttl) continue;
			for (const step of run.steps) steps.delete(step.id);
			runs.delete(run.id);
		}
		for (const run of all) {
			if (run.steps.some((s) => s.status === "running" || s.status === "queued" || s.status === "waiting")) continue;
			const hasFailed = run.steps.some((s) => s.status === "failed" || s.status === "aborted");
			const ttl = hasFailed ? FAILED_KEEP_MS : RECENT_SETTLED_MS;
			if (now - run.updatedAt < ttl) continue;
			for (const step of run.steps) steps.delete(step.id);
			runs.delete(run.id);
		}
	}

	function flushWidget() {
		if (!currentCtx?.hasUI) return;
		pruneOldRuns();
		const visibleRuns = getActiveRuns();
		if (visibleRuns.length === 0) {
			currentCtx.ui.setWidget("subagents", undefined);
			return;
		}
		const width = safeWidth();
		currentCtx.ui.setWidget("subagents", renderBottomWidget(visibleRuns, currentCtx.ui.theme, width));
	}

	function ensureAnimation() {
		if (animTimer) return;
		animTimer = setInterval(() => {
			const hasRunning = Array.from(steps.values()).some((step) => step.status === "running");
			if (!hasRunning) {
				if (animTimer) clearInterval(animTimer);
				animTimer = null;
			}
			flushWidget();
		}, 200);
		if (animTimer.unref) animTimer.unref();
	}

	function stopAll() {
		if (animTimer) { clearInterval(animTimer); animTimer = null; }
		for (const step of steps.values()) {
			if (step.proc && step.status === "running") {
				try { step.proc.kill("SIGTERM"); } catch {}
			}
		}
	}

	function createStep(agentName: string, task: string, cwd: string, runId: number, index: number, status: StepStatus): StepState {
		const stepId = nextStepId++;
		const step: StepState = {
			id: stepId,
			runId,
			index,
			agentName,
			task,
			cwd,
			status,
			elapsedMs: 0,
			turnCount: 0,
			toolCount: 0,
			tokenCount: 0,
			stderrTail: [],
			messages: [],
			sessionFile: makeSessionFile(stepId),
		};
		steps.set(step.id, step);
		return step;
	}

	function createRun(mode: RunMode, label: string, stepConfigs: Array<{ agent: string; task: string; cwd?: string }>, defaultCwd: string, asyncRun = false): RunState {
		const runId = nextRunId++;
		const initialStatus: StepStatus = mode === "chain" ? "running" : mode === "single" ? "running" : "queued";
		const run: RunState = {
			id: runId,
			mode,
			label,
			createdAt: Date.now(),
			updatedAt: Date.now(),
			async: asyncRun,
			status: initialStatus,
			steps: [],
		};
		runs.set(run.id, run);
		run.steps = stepConfigs.map((cfg, idx) => createStep(cfg.agent, cfg.task, cfg.cwd ?? defaultCwd, run.id, idx + 1, mode === "chain" ? (idx === 0 ? "running" : "waiting") : mode === "single" ? "running" : "queued"));
		if (mode === "parallel") {
			for (const step of run.steps) step.status = "queued";
			run.status = "queued";
		}
		refreshRunStatus(run);
		return run;
	}

	async function runStep(step: StepState, agentConfig: AgentConfig, ctx: any, signal?: AbortSignal): Promise<SubagentResult> {
		const settings = resolveSettings(step.cwd || ctx.cwd || process.cwd());
		const parentModel = ctx.model ? `${ctx.model.provider}/${ctx.model.id}` : undefined;
		const model = agentConfig.model ?? settings.model ?? parentModel;
		const promptFile = await writePromptFile(agentConfig.systemPrompt ?? "", agentConfig.name);
		const args = ["--mode", "json", "-p", "--no-session"];
		const extensions = mergeExtensions(settings, agentConfig);
		if (settings.extensions !== null) args.push("--no-extensions");
		for (const ext of extensions) args.push("--extension", ext);
		if (model) args.push("--model", model);
		if (agentConfig.thinking) args.push("--thinking", agentConfig.thinking);
		if (agentConfig.skills?.length) for (const skill of agentConfig.skills) args.push("--skill", skill);
		if (agentConfig.tools?.length) args.push("--tools", agentConfig.tools.join(","));
		if (promptFile) args.push("--append-system-prompt", promptFile.path);
		args.push(`Task: ${step.task}`);

		const result: SubagentResult = {
			agent: step.agentName,
			task: step.task,
			status: "running",
			exitCode: -1,
			messages: [],
			stderr: "",
			usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, contextTokens: 0, turns: 0 },
			startTime: Date.now(),
			agentSource: agentConfig.source,
		};

		step.status = "running";
		step.startTime = Date.now();
		step.endTime = undefined;
		step.elapsedMs = 0;
		step.turnCount = 0;
		step.toolCount = 0;
		step.tokenCount = 0;
		step.currentTool = undefined;
		step.lastOutput = undefined;
		step.error = undefined;
		step.stderrTail = [];
		step.messages = [];
		step.resultText = undefined;
		refreshRunStatus(runs.get(step.runId)!);
		flushWidget();
		ensureAnimation();

		const invocation = getPiInvocation(args);
		return await new Promise<SubagentResult>((resolve) => {
			const proc = spawn(invocation.command, invocation.args, {
				cwd: step.cwd,
				stdio: ["pipe", "pipe", "pipe"],
				env: buildChildEnv(settings),
				shell: false,
			});
			step.proc = proc;
			proc.stdin.on("error", () => {});
			proc.stdin.end();

			let buffer = "";
			const processLine = (line: string) => {
				if (!line.trim()) return;
				try {
					const evt = JSON.parse(line);
					if (evt.type === "message_update") {
						const delta = evt.assistantMessageEvent;
						if (delta?.type === "text_delta" && typeof delta.delta === "string") {
							const merged = `${step.lastOutput || ""}${delta.delta}`;
							const lastLine = merged.split("\n").filter((s: string) => s.trim()).pop();
							if (lastLine) step.lastOutput = truncateInline(lastLine, 120);
						}
					}
					if (evt.type === "tool_execution_start") {
						step.toolCount++;
						step.currentTool = formatToolCallPreview(evt.toolName || evt.tool || "tool", evt.args || {});
					}
					if (evt.type === "tool_execution_end") {
						step.currentTool = undefined;
					}
					if (evt.type === "message_end" && evt.message) {
						const msg = evt.message as Message;
						result.messages.push(msg);
						step.messages.push(msg);
						if (msg.role === "assistant") {
							result.usage.turns++;
							step.turnCount++;
							const usage = (msg as any).usage;
							if (usage) {
								result.usage.input += usage.input || 0;
								result.usage.output += usage.output || 0;
								result.usage.cacheRead += usage.cacheRead || 0;
								result.usage.cacheWrite += usage.cacheWrite || 0;
								result.usage.cost += usage.cost?.total || 0;
								result.usage.contextTokens = Math.max(result.usage.contextTokens, usage.totalTokens || 0);
								step.tokenCount = Math.max(step.tokenCount, usage.totalTokens || 0);
							}
							if (!result.model && (msg as any).model) result.model = (msg as any).model;
							const text = extractTextFromMessage(msg);
							if (text) step.lastOutput = truncateInline(text.split("\n").filter((s) => s.trim()).pop() || text, 120);
						}
					}
				} catch {}
				step.elapsedMs = step.startTime ? Date.now() - step.startTime : step.elapsedMs;
				refreshRunStatus(runs.get(step.runId)!);
				flushWidget();
			};

			proc.stdout.setEncoding("utf-8");
			proc.stdout.on("data", (chunk: string) => {
				buffer += chunk;
				const lines = buffer.split("\n");
				buffer = lines.pop() || "";
				for (const line of lines) processLine(line);
			});

			proc.stderr.setEncoding("utf-8");
			proc.stderr.on("data", (chunk: string) => {
				result.stderr += chunk;
				const tail = chunk.split("\n").map((s) => s.trim()).filter(Boolean);
				if (tail.length) {
					step.stderrTail.push(...tail);
					if (step.stderrTail.length > 20) step.stderrTail = step.stderrTail.slice(-20);
					step.error = truncateInline(tail[tail.length - 1]!, 120);
					flushWidget();
				}
			});

			proc.on("close", (code) => {
				if (buffer.trim()) processLine(buffer);
				result.exitCode = code ?? 0;
				result.endTime = Date.now();
				step.endTime = Date.now();
				step.elapsedMs = step.startTime ? step.endTime - step.startTime : step.elapsedMs;
				step.proc = undefined;
				step.currentTool = undefined;
				step.resultText = getFinalOutput(result.messages);
				if (code === 0) {
					result.status = "completed";
					step.status = "done";
					step.lastOutput = step.lastOutput || truncateInline(step.resultText || "(no output)", 120);
				} else {
					result.status = "failed";
					step.status = "failed";
					step.error = step.error || `Exited with code ${code ?? 1}`;
					result.errorMessage = step.error;
				}
				cleanupTemp(promptFile);
				refreshRunStatus(runs.get(step.runId)!);
				flushWidget();
				resolve(result);
			});

			proc.on("error", (err: Error) => {
				result.exitCode = 1;
				result.status = "failed";
				result.errorMessage = err.message;
				step.status = "failed";
				step.error = `Spawn failed: ${err.message}`;
				step.endTime = Date.now();
				step.elapsedMs = step.startTime ? step.endTime - step.startTime : step.elapsedMs;
				step.proc = undefined;
				cleanupTemp(promptFile);
				refreshRunStatus(runs.get(step.runId)!);
				flushWidget();
				resolve(result);
			});

			if (signal) {
				const kill = () => {
					try { proc.kill("SIGTERM"); } catch {}
					setTimeout(() => { try { if (!proc.killed) proc.kill("SIGKILL"); } catch {} }, 5000);
				};
				if (signal.aborted) kill();
				else signal.addEventListener("abort", kill, { once: true });
			}
		});
	}

	async function runSingleRun(run: RunState, ctx: any, signal?: AbortSignal, onUpdate?: (details: ToolDetails) => void, agentConfigOverride?: AgentConfig): Promise<SubagentResult[]> {
		const step = run.steps[0]!;
		const agentConfig = agentConfigOverride ?? agentMap.get(step.agentName)!;
		const result = await runStep(step, agentConfig, ctx, signal);
		refreshRunStatus(run);
		onUpdate?.(toToolDetails([run], [result], availableAgentsString()));
		return [result];
	}

	async function runParallelRun(run: RunState, ctx: any, signal?: AbortSignal, onUpdate?: (details: ToolDetails) => void): Promise<SubagentResult[]> {
		const results: SubagentResult[] = new Array(run.steps.length);
		for (const step of run.steps) step.status = "queued";
		refreshRunStatus(run);
		flushWidget();
		const tasks = run.steps.map(async (step, idx) => {
			const agentConfig = agentMap.get(step.agentName)!;
			const result = await runStep(step, agentConfig, ctx, signal);
			results[idx] = result;
			refreshRunStatus(run);
			onUpdate?.(toToolDetails([run], results.filter(Boolean), availableAgentsString()));
			return result;
		});
		await Promise.all(tasks);
		refreshRunStatus(run);
		return results;
	}

	async function runChainRun(run: RunState, ctx: any, signal?: AbortSignal, onUpdate?: (details: ToolDetails) => void): Promise<SubagentResult[]> {
		const results: SubagentResult[] = [];
		let previousOutput = "";
		for (let i = 0; i < run.steps.length; i++) {
			const step = run.steps[i]!;
			step.task = step.task.replace(/\{previous\}/g, previousOutput);
			step.status = "running";
			for (let j = i + 1; j < run.steps.length; j++) if (run.steps[j]!.status === "waiting") run.steps[j]!.status = "waiting";
			refreshRunStatus(run);
			flushWidget();
			const agentConfig = agentMap.get(step.agentName)!;
			const result = await runStep(step, agentConfig, ctx, signal);
			results.push(result);
			onUpdate?.(toToolDetails([run], results, availableAgentsString()));
			if (result.status !== "completed") {
				for (let j = i + 1; j < run.steps.length; j++) {
					if (run.steps[j]!.status === "waiting") run.steps[j]!.status = "queued";
				}
				refreshRunStatus(run);
				return results;
			}
			previousOutput = getFinalOutput(result.messages);
			if (i + 1 < run.steps.length && run.steps[i + 1]!.status === "waiting") run.steps[i + 1]!.status = "running";
		}
		refreshRunStatus(run);
		return results;
	}

	function detailsText(details: ToolDetails): string {
		const run = details.runs[0];
		if (!run) return "No run.";
		const statusCounts = `running:${details.runningCount} queued:${details.queuedCount} waiting:${details.waitingCount} done:${details.completedCount} failed:${details.failedCount}`;
		return `${run.label} (${statusCounts})`;
	}

	function findFirstAvailableAgent(preferred: string[]): string | null {
		for (const name of preferred) {
			if (agentMap.has(name)) return name;
		}
		return null;
	}

	function looksLikeCodeExplorationTask(task: string): boolean {
		const t = task.toLowerCase();
		return [
			"codebase", "repo", "repository", "file", "files", "symbol", "definition", "reference", "call site", "callsite",
			"function", "type", "interface", "class", "module", "flow", "trace", "implementation", "where is", "where does",
			"architecture", "refactor", "path", "handler", "lsp", "treesitter", "ast", "tree-sitter",
		].some((needle) => t.includes(needle));
	}

	function chooseResearchAgent(task: string, explicitAgent?: string): { agent: string | null; purpose: "research" | "scout" | "review" } {
		if (explicitAgent) {
			const purpose = explicitAgent === "reviewer" ? "review" : explicitAgent === "explore" ? "scout" : looksLikeCodeExplorationTask(task) ? "scout" : "research";
			return { agent: explicitAgent, purpose };
		}
		if (looksLikeCodeExplorationTask(task)) {
			return {
				agent: findFirstAvailableAgent(["librarian", "reviewer", "plan", "explore", "task", "coder", "researcher"]),
				purpose: "scout",
			};
		}
		return {
			agent: findFirstAvailableAgent(["researcher", "librarian", "explore", "reviewer", "plan", "task", "coder"]),
			purpose: "research",
		};
	}

	function withSemanticExplorationTools(agentConfig: AgentConfig, task: string, purpose: "research" | "scout" | "review"): AgentConfig {
		if (!(purpose === "scout" || looksLikeCodeExplorationTask(task))) return agentConfig;
		const preferredTools = ["lsp", "read_code_structure", "read_code_symbol", "find", "read"];
		const mergedTools = [...new Set([...(agentConfig.tools ?? []), ...preferredTools])];
		return { ...agentConfig, tools: mergedTools };
	}

	function buildSupervisorSummaryTask(task: string, purpose: "research" | "scout" | "review" = "research"): string {
		const framing = purpose === "research"
			? "Do the research in your own isolated context so the parent agent does not need to ingest all intermediate findings."
			: purpose === "scout"
				? "Explore in your own isolated context so the parent agent does not need to ingest all intermediate codebase discovery."
				: "Review in your own isolated context so the parent agent only receives the actionable conclusions.";
		const semanticHint = purpose === "scout"
			? "When available, prefer semantic code-intelligence tools first: lsp, read_code_structure, and read_code_symbol. If ast-grep is installed, you MAY use the ast-grep CLI via bash for structural search. Use plain read/find only after narrowing the search space."
			: "If the task involves source code, prefer semantic code-intelligence tools such as lsp, read_code_structure, and read_code_symbol when available. If ast-grep is installed, you MAY use the ast-grep CLI via bash for structural search.";
		return `${framing}\n\n${semanticHint}\n\nTask:\n${task}\n\nReturn ONLY a concise supervisor handoff in this format:\n- Summary: 2-4 sentences\n- Key findings: 3-7 bullets\n- Evidence: file paths / commands / sources only when important\n- Open questions: bullets or 'none'\n- Recommended next step: 1-3 bullets\n\nDo not dump raw logs, long transcripts, or verbose chain-of-thought.`;
	}

	async function startAsync(run: RunState, ctx: any) {
		fs.mkdirSync(RESULTS_DIR, { recursive: true });
		const resultPath = path.join(RESULTS_DIR, `run-${run.id}-${Date.now()}.json`);
		for (const step of run.steps) step.resultFile = resultPath;
		const execute = run.mode === "single" ? runSingleRun(run, ctx) : run.mode === "parallel" ? runParallelRun(run, ctx) : runChainRun(run, ctx);
		execute.then((results) => {
			try {
				fs.writeFileSync(resultPath, JSON.stringify({
					runId: run.id,
					label: run.label,
					mode: run.mode,
					status: run.status,
					results: results.map((r) => ({ agent: r.agent, task: r.task, status: r.status, exitCode: r.exitCode, output: getFinalOutput(r.messages).slice(0, 50_000) })),
				}, null, 2), "utf-8");
			} catch {}
			ctx.ui.notify(`Subagent run #${run.id} ${run.status === "done" ? "completed" : run.status}`, run.status === "done" ? "success" : run.status === "failed" ? "error" : "info");
			flushWidget();
		}).catch((err) => {
			ctx.ui.notify(`Subagent run #${run.id} failed: ${err instanceof Error ? err.message : String(err)}`, "error");
		});
	}

	function formatErrorReport(step: StepState): string {
		const lines = [
			`#${step.id} ${step.agentName} — ${step.status.toUpperCase()}`,
			`Task: ${step.task}`,
			`Elapsed: ${fmtDuration(step.elapsedMs)} · Turns: ${step.turnCount} · Tools: ${step.toolCount}`,
		];
		if (step.error) lines.push(`Error: ${step.error}`);
		if (step.stderrTail.length) {
			lines.push("", "stderr:");
			for (const line of step.stderrTail.slice(-8)) lines.push(`  ${line}`);
		}
		return lines.join("\n");
	}

	pi.on("session_start", async (_event, ctx) => {
		currentCtx = ctx;
		const discovery = discoverAgents(ctx.cwd, "both");
		discoveredAgents = discovery.agents;
		agentMap = new Map(discoveredAgents.map((a) => [a.name, a]));
		flushWidget();
	});

	pi.on("session_shutdown", async () => {
		stopAll();
	});

	pi.registerCommand("agents", {
		description: "List/filter available agents: /agents [filter]",
		handler: async (args, ctx) => {
			currentCtx = ctx;
			const filter = args?.trim()?.toLowerCase() ?? "";
			if (discoveredAgents.length === 0) {
				ctx.ui.notify("No agents found. Create agents in ~/.pi/agent/agents/*.md or .pi/agents/*.md", "info");
				return;
			}
			const filtered = filter ? discoveredAgents.filter((a) => a.name.toLowerCase().includes(filter) || a.description.toLowerCase().includes(filter)) : discoveredAgents;
			const lines = filtered.map((a) => `${a.name} [${a.source}]${a.model ? ` · ${a.model}` : ""}\n  ${a.description}`).join("\n\n");
			ctx.ui.notify(`Available agents (${filtered.length}):\n${lines}`, "success");
		},
	});

	pi.registerTool({
		name: "subagent_create",
		description: "Spawn a subagent with live widget. Use it to offload bounded work into isolated context and bring back only the useful result.",
		parameters: Type.Object({
			agent: Type.String({ description: "Agent name (from ~/.pi/agent/agents/*.md)" }),
			task: Type.String({ description: "Task description" }),
			async: Type.Optional(Type.Boolean({ description: "Fire-and-forget: don't block, notify when done (default: false)" })),
		}),
		async execute(_callId, args, _signal, _onUpdate, ctx) {
			currentCtx = ctx;
			if (discoveredAgents.length === 0) return { content: [{ type: "text", text: "No agents found. Create agents in ~/.pi/agent/agents/*.md" }], isError: true };
			const agentConfig = agentMap.get(args.agent);
			if (!agentConfig) return { content: [{ type: "text", text: `Unknown agent: ${args.agent}. Available: ${availableAgentsString()}` }], isError: true };
			const run = createRun("single", `${args.agent}: ${truncateInline(args.task, 40)}`, [{ agent: args.agent, task: args.task, cwd: ctx.cwd }], ctx.cwd, Boolean(args.async));
			flushWidget();
			ensureAnimation();
			if (args.async) {
				startAsync(run, ctx);
				return { content: [{ type: "text", text: `Subagent run #${run.id} started in background.` }], details: toToolDetails([run], undefined, availableAgentsString()) };
			}
			const results = await runSingleRun(run, ctx);
			return { content: [{ type: "text", text: getFinalOutput(results[0]!.messages) || "(no output)" }], details: toToolDetails([run], results, availableAgentsString()), isError: results[0]!.status === "failed" };
		},
		renderCall(args: any, theme: any) {
			return { render: () => [truncateToWidth(`${theme.fg("toolTitle", theme.bold("subagent_create"))} ${args.async ? "⟳" : "▶"} ${args.agent} ${theme.fg("muted", truncateInline(args.task || "", 60))}`, safeWidth())] };
		},
		renderResult(result: any, _options: any, _theme: any) {
			const details = result.details as ToolDetails | undefined;
			if (!details?.runs?.length) return { render: () => [truncateToWidth(result.content?.[0]?.text ?? "(no output)", safeWidth())] };
			return { render: () => renderRunDetails(details.runs, safeWidth()) };
		},
	});

	pi.registerTool({
		name: "subagent_continue",
		description: "Continue an existing subagent's conversation.",
		parameters: Type.Object({ id: Type.Number({ description: "Subagent ID" }), task: Type.String({ description: "Follow-up task" }) }),
		async execute(_callId, args, signal, _onUpdate, ctx) {
			currentCtx = ctx;
			const step = steps.get(args.id);
			if (!step) return { content: [{ type: "text", text: `No subagent #${args.id} found.` }] };
			if (step.status === "running") return { content: [{ type: "text", text: `Subagent #${args.id} is still running.` }] };
			const run = createRun("single", `${step.agentName}: ${truncateInline(args.task, 40)}`, [{ agent: step.agentName, task: args.task, cwd: step.cwd }], step.cwd, false);
			const results = await runSingleRun(run, ctx, signal);
			return { content: [{ type: "text", text: getFinalOutput(results[0]!.messages) || "(no output)" }], details: toToolDetails([run], results, availableAgentsString()), isError: results[0]!.status === "failed" };
		},
	});

	pi.registerTool({
		name: "subagent_remove",
		description: "Remove a subagent.",
		parameters: Type.Object({ id: Type.Number({ description: "Subagent ID" }) }),
		execute: async (_callId, args, _signal, _onUpdate, ctx) => {
			currentCtx = ctx;
			const step = steps.get(args.id);
			if (!step) return { content: [{ type: "text", text: `No subagent #${args.id} found.` }] };
			if (step.proc && step.status === "running") {
				try { step.proc.kill("SIGTERM"); } catch {}
				step.status = "aborted";
				step.endTime = Date.now();
			}
			const run = runs.get(step.runId);
			if (run) {
				for (const child of run.steps) steps.delete(child.id);
				runs.delete(run.id);
			}
			flushWidget();
			return { content: [{ type: "text", text: `Subagent #${args.id} removed.` }] };
		},
	});

	pi.registerTool({
		name: "subagent_list",
		description: "List all subagents.",
		parameters: Type.Object({}),
		execute: async () => {
			if (runs.size === 0) return { content: [{ type: "text", text: "No active subagents." }] };
			const list = Array.from(runs.values()).map((run) => {
				refreshRunStatus(run);
				const stepsText = run.steps.map((step) => `#${step.id} ${compactStatus(step.status)} ${step.agentName} ${fmtDuration(step.elapsedMs)} ${truncateInline(step.currentTool || step.task, 50)}`).join("\n  ");
				return `Run #${run.id} ${run.mode} ${run.status}\n  ${stepsText}`;
			}).join("\n\n");
			return { content: [{ type: "text", text: list }] };
		},
	});

	pi.registerTool({
		name: "subagents",
		label: "Subagents",
		description: "Run specialized subagents with progress tracking. Best for offloading research, discovery, review, or bounded implementation into isolated context.",
		promptSnippet: "Delegate research, scouting, review, or bounded implementation to isolated child agents so the parent only gets the useful summary/result.",
		promptGuidelines: [
			"Use subagents when you want to keep heavy research/discovery out of the parent context.",
			"Prefer one focused agent per bounded task instead of a huge parent-context exploration.",
			"For research/scouting, ask the child to return a concise supervisor summary rather than raw logs.",
		],
		parameters: Type.Object({
			mode: StringEnum(["single", "parallel", "chain"] as const, { description: "Execution mode", default: "single" }),
			agent: Type.Optional(Type.String({ description: "Agent name (single mode)" })),
			task: Type.Optional(Type.String({ description: "Task (single mode)" })),
			tasks: Type.Optional(Type.Array(Type.Object({ agent: Type.String(), task: Type.String(), cwd: Type.Optional(Type.String()) }))),
			chain: Type.Optional(Type.Array(Type.Object({ agent: Type.String(), task: Type.String({ description: "Use {previous} to reference prior output" }), cwd: Type.Optional(Type.String()) }))),
			agentScope: Type.Optional(StringEnum(["user", "project", "both"] as const, { default: "both" })),
			cwd: Type.Optional(Type.String()),
		}),
		async execute(_toolCallId, params, signal, onUpdate, ctx) {
			currentCtx = ctx;
			const cwd = params.cwd ?? ctx.cwd;
			const discovery = discoverAgents(cwd, params.agentScope ?? "both");
			discoveredAgents = discovery.agents;
			agentMap = new Map(discoveredAgents.map((a) => [a.name, a]));
			if (discoveredAgents.length === 0) return { content: [{ type: "text", text: "No agents found. Create agents in ~/.pi/agent/agents/*.md" }], details: toToolDetails([], [], "none"), isError: true };
			const available = availableAgentsString();

			if (params.mode === "single") {
				if (!params.agent || !params.task) return { content: [{ type: "text", text: `Invalid parameters. Available agents: ${available}` }], isError: true };
				if (!agentMap.get(params.agent)) return { content: [{ type: "text", text: `Unknown agent: ${params.agent}. Available: ${available}` }], isError: true };
				const run = createRun("single", `${params.agent}: ${truncateInline(params.task, 40)}`, [{ agent: params.agent, task: params.task, cwd }], cwd, false);
				const results = await runSingleRun(run, ctx, signal, (details) => onUpdate?.({ content: [{ type: "text", text: detailsText(details) }], details }));
				return { content: [{ type: "text", text: getFinalOutput(results[0]!.messages) || "(no output)" }], details: toToolDetails([run], results, available), isError: results[0]!.status === "failed" };
			}

			if (params.mode === "parallel") {
				if (!params.tasks?.length) return { content: [{ type: "text", text: `Invalid parameters. Available agents: ${available}` }], isError: true };
				const invalid = params.tasks.filter((task) => !agentMap.get(task.agent));
				if (invalid.length) return { content: [{ type: "text", text: `Unknown agents: ${invalid.map((t) => t.agent).join(", ")}. Available: ${available}` }], isError: true };
				const run = createRun("parallel", `parallel ×${params.tasks.length}`, params.tasks.map((t) => ({ agent: t.agent, task: t.task, cwd: t.cwd ?? cwd })), cwd, false);
				const results = await runParallelRun(run, ctx, signal, (details) => onUpdate?.({ content: [{ type: "text", text: detailsText(details) }], details }));
				return { content: [{ type: "text", text: `Parallel complete: ${results.filter((r) => r.status === "completed").length}/${results.length} succeeded` }], details: toToolDetails([run], results, available), isError: results.some((r) => r.status === "failed") };
			}

			if (params.mode === "chain") {
				if (!params.chain?.length) return { content: [{ type: "text", text: `Invalid parameters. Available agents: ${available}` }], isError: true };
				const invalid = params.chain.filter((step) => !agentMap.get(step.agent));
				if (invalid.length) return { content: [{ type: "text", text: `Unknown agents: ${invalid.map((t) => t.agent).join(", ")}. Available: ${available}` }], isError: true };
				const run = createRun("chain", `chain ×${params.chain.length}`, params.chain.map((t) => ({ agent: t.agent, task: t.task, cwd: t.cwd ?? cwd })), cwd, false);
				const results = await runChainRun(run, ctx, signal, (details) => onUpdate?.({ content: [{ type: "text", text: detailsText(details) }], details }));
				return { content: [{ type: "text", text: `Chain complete: ${results.filter((r) => r.status === "completed").length}/${params.chain.length} steps` }], details: toToolDetails([run], results, available), isError: results.some((r) => r.status === "failed") };
			}

			return { content: [{ type: "text", text: `Invalid parameters. Available agents: ${available}` }], isError: true };
		},
		renderCall(args: any, theme: any) {
			const count = args.tasks?.length ?? args.chain?.length ?? (args.agent ? 1 : 0);
			return { render: () => [truncateToWidth(`${theme.fg("toolTitle", theme.bold("subagents"))} ${args.mode || "single"}${count ? ` ×${count}` : ""}`, safeWidth())] };
		},
		renderResult(result: any, _options: any, _theme: any) {
			const details = result.details as ToolDetails | undefined;
			if (!details?.runs?.length) return { render: () => [truncateToWidth(result.content?.[0]?.text ?? "(no output)", safeWidth())] };
			return { render: () => renderRunDetails(details.runs, safeWidth()) };
		},
	});

	pi.registerTool({
		name: "subagent_research",
		description: "Run a research/scout subagent in isolated context and return only a concise summary to the parent agent.",
		promptSnippet: "Offload research or codebase scouting into a child agent and get back a concise supervisor handoff.",
		promptGuidelines: [
			"Use subagent_research when the parent agent should avoid context pollution from broad exploration.",
			"subagent_research is ideal for docs lookup, repo scouting, pattern discovery, and summarization back to the main agent.",
		],
		parameters: Type.Object({
			task: Type.String({ description: "Research/scouting task to perform in isolated context" }),
			agent: Type.Optional(Type.String({ description: "Optional specific agent. Defaults to researcher/librarian/explore/reviewer/plan if available." })),
			cwd: Type.Optional(Type.String({ description: "Optional working directory" })),
		}),
		async execute(_callId, args, signal, _onUpdate, ctx) {
			currentCtx = ctx;
			const choice = chooseResearchAgent(args.task, args.agent);
			if (!choice.agent) {
				return { content: [{ type: "text", text: `No suitable research-capable agent found. Available: ${availableAgentsString()}` }], isError: true };
			}
			const baseAgent = agentMap.get(choice.agent)!;
			const effectiveAgent = withSemanticExplorationTools(baseAgent, args.task, choice.purpose);
			const task = buildSupervisorSummaryTask(args.task, choice.purpose);
			const cwd = args.cwd ?? ctx.cwd;
			const run = createRun("single", `${choice.agent}: ${truncateInline(args.task, 40)}`, [{ agent: choice.agent, task, cwd }], cwd, false);
			const results = await runSingleRun(run, ctx, signal, undefined, effectiveAgent);
			const text = getFinalOutput(results[0]!.messages) || "(no output)";
			return { content: [{ type: "text", text }], details: toToolDetails([run], results, availableAgentsString()), isError: results[0]!.status === "failed" };
		},
		renderCall(args: any, theme: any) {
			return { render: () => [truncateToWidth(`${theme.fg("toolTitle", theme.bold("subagent_research"))} ${theme.fg("accent", args.agent || "auto")} ${theme.fg("muted", truncateInline(args.task || "", 60))}`, safeWidth())] };
		},
		renderResult(result: any, _options: any, _theme: any) {
			const details = result.details as ToolDetails | undefined;
			if (!details?.runs?.length) return { render: () => [truncateToWidth(result.content?.[0]?.text ?? "(no output)", safeWidth())] };
			return { render: () => renderRunDetails(details.runs, safeWidth()) };
		},
	});

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
			if (!agentMap.get(agentName)) { ctx.ui.notify(`Unknown agent: ${agentName}. Available: ${availableAgentsString()}`, "error"); return; }
			const run = createRun("single", `${agentName}: ${truncateInline(task, 40)}`, [{ agent: agentName, task, cwd: ctx.cwd }], ctx.cwd, false);
			ctx.ui.notify(`Subagent run #${run.id} started`, "info");
			await runSingleRun(run, ctx);
			ctx.ui.notify(`Subagent run #${run.id} ${run.status}`, run.status === "done" ? "success" : run.status === "failed" ? "error" : "info");
		},
	});

	pi.registerCommand("subresearch", {
		description: "Run isolated research/scouting and return only a concise summary: /subresearch <task>",
		handler: async (args, ctx) => {
			currentCtx = ctx;
			const rawTask = args?.trim() ?? "";
			if (!rawTask) { ctx.ui.notify("Usage: /subresearch <task>", "error"); return; }
			const choice = chooseResearchAgent(rawTask);
			if (!choice.agent) { ctx.ui.notify(`No suitable research-capable agent found. Available: ${availableAgentsString()}`, "error"); return; }
			const baseAgent = agentMap.get(choice.agent)!;
			const effectiveAgent = withSemanticExplorationTools(baseAgent, rawTask, choice.purpose);
			const task = buildSupervisorSummaryTask(rawTask, choice.purpose);
			const run = createRun("single", `${choice.agent}: ${truncateInline(rawTask, 40)}`, [{ agent: choice.agent, task, cwd: ctx.cwd }], ctx.cwd, false);
			ctx.ui.notify(`Research subagent run #${run.id} started with ${choice.agent}`, "info");
			const results = await runSingleRun(run, ctx, undefined, undefined, effectiveAgent);
			ctx.ui.notify(`Research subagent run #${run.id} ${run.status}`, run.status === "done" ? "success" : "error");
			ctx.ui.notify(getFinalOutput(results[0]!.messages) || "(no output)", run.status === "done" ? "info" : "error");
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
			const prior = steps.get(num);
			if (!prior || Number.isNaN(num) || !task) { ctx.ui.notify("Usage: /subcont <id> <task>", "error"); return; }
			if (prior.status === "running") { ctx.ui.notify(`Subagent #${num} is still running.`, "warning"); return; }
			const run = createRun("single", `${prior.agentName}: ${truncateInline(task, 40)}`, [{ agent: prior.agentName, task, cwd: prior.cwd }], prior.cwd, false);
			await runSingleRun(run, ctx);
			ctx.ui.notify(`Subagent run #${run.id} ${run.status}`, run.status === "done" ? "success" : run.status === "failed" ? "error" : "info");
		},
	});

	pi.registerCommand("subrm", {
		description: "Remove a subagent: /subrm <id>",
		handler: async (args, ctx) => {
			currentCtx = ctx;
			const num = parseInt(args?.trim() ?? "", 10);
			if (Number.isNaN(num)) { ctx.ui.notify("Usage: /subrm <id>", "error"); return; }
			const step = steps.get(num);
			if (!step) { ctx.ui.notify(`No subagent #${num} found.`, "error"); return; }
			if (step.proc && step.status === "running") {
				try { step.proc.kill("SIGTERM"); } catch {}
				step.status = "aborted";
			}
			const run = runs.get(step.runId);
			if (run) {
				for (const child of run.steps) steps.delete(child.id);
				runs.delete(run.id);
			}
			flushWidget();
			ctx.ui.notify(`Subagent #${num} removed.`, "info");
		},
	});

	pi.registerCommand("subclear", {
		description: "Clear settled subagent history",
		handler: async (_args, ctx) => {
			currentCtx = ctx;
			let removed = 0;
			for (const run of Array.from(runs.values())) {
				const hasLive = run.steps.some((s) => s.status === "running" || s.status === "queued" || s.status === "waiting");
				if (hasLive) continue;
				for (const step of run.steps) steps.delete(step.id);
				runs.delete(run.id);
				removed++;
			}
			flushWidget();
			ctx.ui.notify(removed ? `Cleared ${removed} settled run${removed === 1 ? "" : "s"}.` : "No settled runs to clear.", removed ? "success" : "info");
		},
	});

	pi.registerCommand("suberr", {
		description: "Inspect subagent error details: /suberr <id>",
		handler: async (args, ctx) => {
			currentCtx = ctx;
			const trimmed = args?.trim() ?? "";
			if (!trimmed) {
				const failed = Array.from(steps.values()).filter((step) => step.status === "failed" || step.status === "aborted");
				if (!failed.length) { ctx.ui.notify("No failed subagents.", "info"); return; }
				ctx.ui.notify(failed.map(formatErrorReport).join("\n" + "─".repeat(40) + "\n"), "error");
				return;
			}
			const num = parseInt(trimmed, 10);
			const step = steps.get(num);
			if (!step) { ctx.ui.notify(`No subagent #${num} found.`, "error"); return; }
			ctx.ui.notify(formatErrorReport(step), step.status === "failed" || step.status === "aborted" ? "error" : "info");
		},
	});
}
