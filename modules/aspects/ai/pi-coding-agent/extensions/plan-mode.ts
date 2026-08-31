/**
 * Plan Mode Extension
 *
 * Read-only exploration mode for safe code analysis.
 * When enabled, only read-only tools are available.
 *
 * Features:
 * - /plan command or Ctrl+Alt+P to toggle
 * - Bash restricted to allowlisted read-only commands
 * - Extracts numbered plan steps from "Plan:" sections
 * - [DONE:n] markers to complete steps during execution
 * - Progress tracking widget during execution
 */

import type { AgentMessage } from "@mariozechner/pi-agent-core";
import type { AssistantMessage, TextContent } from "@mariozechner/pi-ai";
import { StringEnum } from "@mariozechner/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { Key, Text } from "@mariozechner/pi-tui";
import { Type, type Static } from "typebox";

// NOTE: pi extension loader no resolve relative TS imports at runtime.
// Keep plan-mode self-contained (copy from plan-utils.ts).
const DESTRUCTIVE_PATTERNS = [
	/\brm\b/i,
	/\brmdir\b/i,
	/\bmv\b/i,
	/\bcp\b/i,
	/\bmkdir\b/i,
	/\btouch\b/i,
	/\bchmod\b/i,
	/\bchown\b/i,
	/\bchgrp\b/i,
	/\bln\b/i,
	/\btee\b/i,
	/\btruncate\b/i,
	/\bdd\b/i,
	/\bshred\b/i,
	/(^|[^<])>(?!>)/,
	/>>/,
	/\bnpm\s+(install|uninstall|update|ci|link|publish)\b/i,
	/\byarn\s+(add|remove|install|publish)\b/i,
	/\bpnpm\s+(add|remove|install|publish)\b/i,
	/\bpip\s+(install|uninstall)\b/i,
	/\bapt(-get)?\s+(install|remove|purge|update|upgrade)\b/i,
	/\bbrew\s+(install|uninstall|upgrade)\b/i,
	/\bgit\s+(add|commit|push|pull|merge|rebase|reset|checkout|branch\s+-[dD]|stash|cherry-pick|revert|tag|init|clone)\b/i,
	/\bsudo\b/i,
	/\bsu\b/i,
	/\bkill\b/i,
	/\bpkill\b/i,
	/\bkillall\b/i,
	/\breboot\b/i,
	/\bshutdown\b/i,
	/\bsystemctl\s+(start|stop|restart|enable|disable)\b/i,
	/\bservice\s+\S+\s+(start|stop|restart)\b/i,
	/\b(vim?|nano|emacs|code|subl)\b/i,
];

const SAFE_PATTERNS = [
	/^\s*cat\b/,
	/^\s*head\b/,
	/^\s*tail\b/,
	/^\s*less\b/,
	/^\s*more\b/,
	/^\s*grep\b/,
	/^\s*find\b/,
	/^\s*ls\b/,
	/^\s*pwd\b/,
	/^\s*echo\b/,
	/^\s*printf\b/,
	/^\s*wc\b/,
	/^\s*sort\b/,
	/^\s*uniq\b/,
	/^\s*diff\b/,
	/^\s*file\b/,
	/^\s*stat\b/,
	/^\s*tree\b/,
	/^\s*which\b/,
	/^\s*whoami\b/,
	/^\s*id\b/,
	/^\s*uname\b/,
	/^\s*date\b/,
	/^\s*env\b/,
	/^\s*printenv\b/,
	/^\s*ps\b/,
	/^\s*top\b/,
	/^\s*htop\b/,
	/^\s*free\b/,
	/^\s*df\b/,
	/^\s*du\b/,
	/^\s*ip\b/,
	/^\s*ss\b/,
	/^\s*netstat\b/,
	/^\s*lsof\b/,
	/^\s*journalctl\b/,
	/^\s*systemctl\s+status\b/i,
	/^\s*nix\s+info\b/i,
	/^\s*nix\s+flake\s+show\b/i,
	/^\s*nix\s+flake\s+metadata\b/i,
	/^\s*nix\s+path-info\b/i,
	/^\s*nix\s+show-derivation\b/i,
	/^\s*nix\s+log\b/i,
	/^\s*nix\s+why-depends\b/i,
	/^\s*go\s+(env|list|version|test\s+-c)\b/i,
	/^\s*cargo\s+(metadata|version)\b/i,
	/^\s*python\s+--version\b/i,
	/^\s*node\s+--version\b/i,
	/^\s*bun\s+--version\b/i,
	/^\s*npm\s+--version\b/i,
	/^\s*yarn\s+--version\b/i,
	/^\s*pnpm\s+--version\b/i,
	/^\s*git\s+(status|diff|log|show|rev-parse|branch|remote\s+-v)\b/i,
	/^\s*awk\b/,
	/^\s*rg\b/,
	/^\s*fd\b/,
	/^\s*bat\b/,
	/^\s*eza\b/,
	/^\s*docker\s+ps\b/i,
	/^\s*docker\s+compose\s+ps\b/i,
	/^\s*nix\s+build\s+--dry-run\b/i,
	/^\s*nix\s+eval\b/i,
	/^\s*cargo\s+check\b/i,
	/^\s*cargo\s+clippy\b/i,
	/^\s*cargo\s+test\s+--no-run\b/i,
];

function isSafeCommand(command: string): boolean {
	const normalizedCommand = command.replace(/(["'`])(?:\\.|(?!\1)[^\\])*\1/g, "");
	const isDestructive = DESTRUCTIVE_PATTERNS.some((p) => p.test(normalizedCommand));
	const isSafe = SAFE_PATTERNS.some((p) => p.test(command));
	return !isDestructive && isSafe;
}

interface TodoItem {
	step: number;
	text: string;
	completed: boolean;
}

function cleanStepText(text: string): string {
	let cleaned = text
		.replace(/\*{1,2}([^*]+)\*{1,2}/g, "$1")
		.replace(/`([^`]+)`/g, "$1")
		.replace(
			/^(Use|Run|Execute|Create|Write|Read|Check|Verify|Update|Modify|Add|Remove|Delete|Install)\s+(the\s+)?/i,
			"",
		)
		.replace(/^(?:\s*[-*+]\s+|\s*\d+[.)]\s+)/, "")
		.replace(/\s+/g, " ")
		.trim();

	if (cleaned.length > 0) cleaned = cleaned.charAt(0).toUpperCase() + cleaned.slice(1);
	if (cleaned.length > 50) {
		let truncated = cleaned.slice(0, 47);
		const lastSpace = truncated.lastIndexOf(" ");
		if (lastSpace > 0) truncated = truncated.slice(0, lastSpace);
		cleaned = `${truncated}...`;
	}
	return cleaned;
}

function extractTodoItems(message: string): TodoItem[] {
	const items: TodoItem[] = [];
	const headerMatch = message.match(/\*{0,2}Plan:\*{0,2}\s*\n/i);
	if (!headerMatch) return items;

	const planSection = message.slice(message.indexOf(headerMatch[0]) + headerMatch[0].length);
	const numberedPattern = /^\s*(\d+)[.)]\s+(.+?)(?=\n\s*\d+[.)]\s+|\n*$)/gms;

	for (const match of planSection.matchAll(numberedPattern)) {
		const text = match[2]
			.split("\n")
			.find((line) => line.trim().length > 0 && !/^\s*[-*]\s+/.test(line))
			?.trim()
			.replace(/\*{1,2}$/, "")
			.trim();
		if (!text) continue;
		if (text.length > 5 && !text.startsWith("`") && !text.startsWith("/") && !text.startsWith("-")) {
			const cleaned = cleanStepText(text);
			if (cleaned.length > 3) items.push({ step: items.length + 1, text: cleaned, completed: false });
		}
	}
	return items;
}

function extractDoneSteps(message: string): number[] {
	const steps: number[] = [];
	for (const match of message.matchAll(/\[DONE:(\d+)\]/gi)) {
		const step = Number(match[1]);
		if (Number.isFinite(step)) steps.push(step);
	}
	return steps;
}

function markCompletedSteps(text: string, items: TodoItem[]): TodoItem[] {
	const doneSteps = new Set(extractDoneSteps(text));
	return items.map((item) => ({
		...item,
		completed: item.completed || doneSteps.has(item.step),
	}));
}

// Tools
const PLAN_MODE_TOOLS = ["read", "bash", "grep", "find", "ls", "ask_user_question"];
const NORMAL_MODE_TOOLS = ["read", "bash", "edit", "write", "grep", "find", "ls", "ask_user_question"];

// Type guard for assistant messages
function isAssistantMessage(m: AgentMessage): m is AssistantMessage {
	return m.role === "assistant" && Array.isArray(m.content);
}

// Extract text content from an assistant message
function getTextContent(message: AssistantMessage): string {
	return message.content
		.filter((block): block is TextContent => block.type === "text")
		.map((block) => block.text)
		.join("\n");
}

// ── Types ─────────────────────────────────────────────────────────────────────

type TaskStatus = "pending" | "in_progress" | "complete";

interface Task {
	name: string;
	status: TaskStatus;
}

type ActionType = "init" | "update" | "status" | "review" | "clear";

interface PlanTrackerDetails {
	action: ActionType;
	tasks: Task[];
	error?: string;
	updatedIndex?: number;
}

interface ActionResult {
	text: string;
	tasks: Task[];
	error?: string;
	updatedIndex?: number;
}

// ── Parameters ────────────────────────────────────────────────────────────────

const PlanTrackerParams = Type.Object({
	action: StringEnum(["init", "update", "status", "review", "clear"] as const, {
		description: "Action to perform",
	}),
	tasks: Type.Optional(
		Type.Array(Type.String(), {
			description: "Task names (for init)",
		}),
	),
	index: Type.Optional(
		Type.Integer({
			minimum: 0,
			description: "Task index, 0-based (for update)",
		}),
	),
	status: Type.Optional(
		StringEnum(["pending", "in_progress", "complete"] as const, {
			description: "New status (for update)",
		}),
	),
});

type PlanTrackerInput = Static<typeof PlanTrackerParams>;

// ── Action Handlers ───────────────────────────────────────────────────────────

function handleInit(taskNames: string[] | undefined): ActionResult {
	if (!taskNames || taskNames.length === 0) {
		return {
			text: "Error: tasks array required for init",
			tasks: [],
			error: "tasks required",
		};
	}
	const tasks: Task[] = taskNames.map((name) => ({
		name,
		status: "pending" as TaskStatus,
	}));
	return {
		text: `Plan initialized with ${tasks.length} tasks.\n${formatStatus(tasks)}`,
		tasks,
	};
}

function handleUpdate(
	tasks: Task[],
	index: number | undefined,
	status: TaskStatus | undefined,
): ActionResult {
	if (index === undefined || !status) {
		return {
			text: "Error: index and status required for update",
			tasks: [...tasks],
			error: "index and status required",
		};
	}
	if (tasks.length === 0) {
		return {
			text: "Error: no plan active. Use init first.",
			tasks: [],
			error: "no plan active",
		};
	}
	if (index < 0 || index >= tasks.length) {
		return {
			text: `Error: index ${index} out of range (0-${tasks.length - 1})`,
			tasks: [...tasks],
			error: `index ${index} out of range`,
		};
	}
	const updated = tasks.map((t, i) =>
		i === index ? { ...t, status } : { ...t },
	);
	return {
		text: `Task ${index} "${updated[index].name}" → ${status}\n${formatStatus(updated)}`,
		tasks: updated,
		updatedIndex: index,
	};
}

function handleStatusAction(tasks: Task[]): ActionResult {
	return {
		text: formatStatus(tasks),
		tasks: [...tasks],
	};
}

function handleReview(tasks: Task[]): ActionResult {
	if (tasks.length === 0) {
		return { text: "No plan active.", tasks: [] };
	}

	const complete = tasks.filter((t) => t.status === "complete");
	const inProgress = tasks.filter((t) => t.status === "in_progress");
	const pending = tasks.filter((t) => t.status === "pending");

	const lines: string[] = [];
	lines.push(`Plan Review: ${complete.length}/${tasks.length} complete`);

	if (inProgress.length > 0) {
		lines.push("");
		lines.push(`IN PROGRESS (${inProgress.length}):`);
		for (const t of inProgress) {
			const idx = tasks.indexOf(t);
			lines.push(`  → [${idx}] ${t.name}`);
		}
	}

	if (pending.length > 0) {
		lines.push("");
		lines.push(`PENDING (${pending.length}):`);
		for (const t of pending) {
			const idx = tasks.indexOf(t);
			lines.push(`  ○ [${idx}] ${t.name}`);
		}
	}

	if (complete.length > 0) {
		lines.push("");
		lines.push(`COMPLETE (${complete.length}):`);
		for (const t of complete) {
			const idx = tasks.indexOf(t);
			lines.push(`  ✓ [${idx}] ${t.name}`);
		}
	}

	return {
		text: lines.join("\n"),
		tasks: [...tasks],
	};
}

function handleClear(tasks: Task[]): ActionResult {
	const count = tasks.length;
	return {
		text: count > 0 ? `Plan cleared (${count} tasks removed).` : "No plan was active.",
		tasks: [],
	};
}

// ── Formatting ────────────────────────────────────────────────────────────────

function formatStatus(tasks: Task[]): string {
	if (tasks.length === 0) return "No plan active.";

	const complete = tasks.filter((t) => t.status === "complete").length;
	const inProgress = tasks.filter((t) => t.status === "in_progress").length;
	const pending = tasks.filter((t) => t.status === "pending").length;

	const lines: string[] = [];
	lines.push(
		`Plan: ${complete}/${tasks.length} complete (${inProgress} in progress, ${pending} pending)`,
	);
	lines.push("");
	for (let i = 0; i < tasks.length; i++) {
		const t = tasks[i];
		const icon =
			t.status === "complete" ? "✓" : t.status === "in_progress" ? "→" : "○";
		lines.push(`  ${icon} [${i}] ${t.name}`);
	}
	return lines.join("\n");
}

function renderWidgetLines(tasks: Task[], theme: any, width: number): string[] {
	if (tasks.length === 0) return [];
	const allComplete = tasks.every((t) => t.status === "complete");
	if (allComplete) return [];

	const complete = tasks.filter((t) => t.status === "complete").length;
	const inProgress = tasks.filter((t) => t.status === "in_progress").length;
	const pending = tasks.filter((t) => t.status === "pending").length;
	const groups: [string, TaskStatus, string][] = [
		["In Progress", "in_progress", "→"],
		["Pending", "pending", "○"],
		["Complete", "complete", "✓"],
	];

	const lines: string[] = [];

	// Header with progress bar
	const bar = tasks
		.map((t) => {
			switch (t.status) {
				case "complete":
					return theme.fg("success", "━");
				case "in_progress":
					return theme.fg("warning", "▸");
				default:
					return theme.fg("dim", "─");
			}
		})
		.join("");
	lines.push(`${theme.bold(theme.fg("accent", "Plan"))} [${bar}] ${theme.fg("muted", `${complete}/${tasks.length}`)}  ${theme.fg("dim", `→${inProgress} ○${pending}`)}`);

	// Grouped task lines
	for (const [label, status, icon] of groups) {
		const group = tasks.filter((t) => t.status === status);
		if (group.length === 0) continue;

		const ic = status === "complete"
			? theme.fg("success", icon)
			: status === "in_progress"
				? theme.fg("warning", icon)
				: theme.fg("dim", icon);

		for (const t of group) {
			const idx = tasks.indexOf(t);
			const prefix = `  ${ic} ${theme.fg("muted", `[${idx}]`)} `;
			const maxNameLen = Math.max(10, width - 12);
			const name = t.name.length > maxNameLen
				? t.name.slice(0, maxNameLen - 1) + "…"
				: t.name;
			lines.push(`${prefix}${name}`);
		}
	}

	return lines;
}

// ── State Reconstruction ──────────────────────────────────────────────────────

interface BranchEntry {
	type: string;
	message?: {
		role: string;
		toolName?: string;
		details?: PlanTrackerDetails;
	};
}

function reconstructFromBranch(entries: BranchEntry[]): Task[] {
	let tasks: Task[] = [];
	for (const entry of entries) {
		if (entry.type !== "message") continue;
		const msg = entry.message;
		if (!msg || msg.role !== "toolResult" || msg.toolName !== "plan_tracker") {
			continue;
		}
		const details = msg.details as PlanTrackerDetails | undefined;
		const hasValidTasks =
			details &&
			!details.error &&
			Array.isArray(details.tasks) &&
			details.tasks.every(
				(task) =>
					task &&
					typeof task.name === "string" &&
					(task.status === "pending" ||
						task.status === "in_progress" ||
						task.status === "complete"),
			);
		if (hasValidTasks) {
			tasks = details.tasks.map((task) => ({ ...task }));
		}
	}
	return tasks;
}

// ── Extension ─────────────────────────────────────────────────────────────────

function registerPlanTracker(pi: ExtensionAPI) {
	let tasks: Task[] = [];

	const reconstructState = (ctx: ExtensionContext) => {
		try {
			const branch = ctx.sessionManager?.getBranch();
			if (branch) {
				tasks = reconstructFromBranch(branch as BranchEntry[]);
			}
		} catch {}
	};

	const updateWidget = (ctx: ExtensionContext) => {
		if (!ctx.hasUI) return;
		try {
			const allDone = tasks.length > 0 && tasks.every((t) => t.status === "complete");
			if (tasks.length === 0 || allDone) {
				ctx.ui.setWidget("plan_tracker", undefined);
			} else {
				const width = process.stdout.columns ?? 80;
				const lines = renderWidgetLines(tasks, ctx.ui.theme, width);
				ctx.ui.setWidget("plan_tracker", lines);
			}
		} catch {}
	};

	// Reconstruct state + widget on session events
	for (const event of [
		"session_start",
		"session_switch",
		"session_fork",
		"session_tree",
	] as const) {
		pi.on(event, async (_event: any, ctx: ExtensionContext) => {
			reconstructState(ctx);
			updateWidget(ctx);
		});
	}

	// ── Tool ────────────────────────────────────────────────────────────────

	pi.registerTool({
		name: "plan_tracker",
		label: "Plan Tracker",
		description: `Track implementation plan progress with a persistent TUI widget.

Actions:
- init: Set task list (pass tasks array of names)
- update: Change a task's status by index (0-based)
- status: Show current plan state
- review: Review todos grouped by status (in_progress → pending → complete)
- clear: Remove active plan

Note: task indices are 0-based.

The widget shows: Tasks: [━━▸──] (2/5) Task 3: Name

State persists across conversation branches via tool result details.`,

		promptSnippet: "Track plan progress with init/update/status/review/clear actions",
		promptGuidelines: [
			"Use plan_tracker init with a task list before starting multi-step work.",
			"Use plan_tracker update to mark tasks in_progress or complete as you work.",
			"Use plan_tracker status or review to check remaining work.",
			"Use plan_tracker clear to dismiss the plan widget when done.",
		],

		parameters: PlanTrackerParams,

		async execute(_toolCallId, params, _signal, _onUpdate, ctx: ExtensionContext) {
			let result: ActionResult;

			switch (params.action) {
				case "init": {
					result = handleInit(params.tasks);
					if (!result.error) {
						tasks = result.tasks;
					} else {
						tasks = [];
						result = { ...result, tasks: [] };
					}
					updateWidget(ctx);
					break;
				}
				case "update": {
					result = handleUpdate(tasks, params.index, params.status);
					tasks = result.tasks;
					updateWidget(ctx);
					break;
				}
				case "status": {
					result = handleStatusAction(tasks);
					break;
				}
				case "review": {
					result = handleReview(tasks);
					break;
				}
				case "clear": {
					result = handleClear(tasks);
					tasks = result.tasks;
					updateWidget(ctx);
					break;
				}
				default:
					return {
						content: [
							{
								type: "text" as const,
								text: `Unknown action: ${params.action}`,
							},
						],
						details: {
							action: "status" as ActionType,
							tasks: [...tasks],
							error: "unknown action",
						} as PlanTrackerDetails,
					};
			}

			const details: PlanTrackerDetails = {
				action: params.action,
				tasks: result.tasks,
				...(result.error ? { error: result.error } : {}),
				...(result.updatedIndex !== undefined ? { updatedIndex: result.updatedIndex } : {}),
			};

			return {
				content: [{ type: "text" as const, text: result.text }],
				details,
			};
		},

		renderCall(args: any, theme: any) {
			let text = theme.fg("toolTitle", theme.bold("plan_tracker "));
			text += theme.fg("muted", args.action);
			if (args.action === "update" && args.index !== undefined) {
				text += ` ${theme.fg("accent", `[${args.index}]`)} → ${theme.fg("dim", args.status)}`;
			}
			if (args.action === "init" && args.tasks) {
				text += ` ${theme.fg("dim", `(${args.tasks.length} tasks)`)}`;
			}
			return new Text(text, 0, 0);
		},

		renderResult(result: any, { expanded }: any, theme: any, _context: any) {
			const details = result.details as PlanTrackerDetails | undefined;
			if (!details) {
				const content = result.content?.[0];
				return new Text(
					content?.type === "text" ? content.text : "",
					0,
					0,
				);
			}

			if (details.error) {
				return new Text(
					theme.fg("error", `Error: ${details.error}`),
					0,
					0,
				);
			}

			const taskList = details.tasks;
			switch (details.action) {
				case "init":
					return new Text(
						theme.fg("success", "✓ ") +
							theme.fg(
								"muted",
								`Plan initialized with ${taskList.length} tasks`,
							),
						0,
						0,
					);
				case "update": {
					const complete = taskList.filter(
						(t) => t.status === "complete",
					).length;
					const idx = details.updatedIndex;
					const taskName = (idx !== undefined && taskList[idx]) ? taskList[idx].name : "?";
					const allDone = complete === taskList.length;
					if (allDone) {
						return new Text(
							theme.fg("success", "✓ ") +
								theme.fg("muted", `All ${taskList.length} tasks complete`),
							0,
							0,
						);
					}
					return new Text(
						theme.fg("success", "✓ ") +
							theme.fg("muted", `${taskName}`) +
							theme.fg("dim", ` — ${complete}/${taskList.length} done`),
						0,
						0,
					);
				}
				case "status": {
					if (taskList.length === 0) {
						return new Text(
							theme.fg("dim", "No plan active"),
							0,
							0,
						);
					}
					const complete = taskList.filter(
						(t) => t.status === "complete",
					).length;
					const summary = theme.fg("muted", `${complete}/${taskList.length} complete`);
					if (!expanded) return new Text(summary, 0, 0);

					let text = summary;
					for (const t of taskList) {
						const icon =
							t.status === "complete"
								? theme.fg("success", "✓")
								: t.status === "in_progress"
									? theme.fg("warning", "→")
									: theme.fg("dim", "○");
						text += `\n${icon} ${theme.fg("muted", t.name)}`;
					}
					return new Text(text, 0, 0);
				}
				case "review": {
					if (taskList.length === 0) {
						return new Text(theme.fg("dim", "No plan active"), 0, 0);
					}
					const complete = taskList.filter((t) => t.status === "complete").length;
					const summary = theme.bold(theme.fg("accent", "Plan Review ")) +
						theme.fg("muted", `${complete}/${taskList.length}`);
					if (!expanded) return new Text(summary, 0, 0);

					let text = summary;
					const groups: [string, TaskStatus, string][] = [
						["In Progress", "in_progress", "→"],
						["Pending", "pending", "○"],
						["Complete", "complete", "✓"],
					];
					for (const [label, status, icon] of groups) {
						const group = taskList.filter((t) => t.status === status);
						if (group.length === 0) continue;
						text += `\n${theme.fg("muted", `${label} (${group.length}):`)}`;
						for (const t of group) {
							const idx = taskList.indexOf(t);
							const ic = status === "complete"
								? theme.fg("success", icon)
								: status === "in_progress"
									? theme.fg("warning", icon)
									: theme.fg("dim", icon);
							text += `\n  ${ic} ${theme.fg("muted", `[${idx}]`)} ${t.name}`;
						}
					}
					return new Text(text, 0, 0);
				}
				case "clear":
					return new Text(
						theme.fg("success", "✓ ") +
							theme.fg("muted", "Plan cleared"),
						0,
						0,
					);
				default:
					return new Text(theme.fg("dim", "Done"), 0, 0);
			}
		},
	});

	// ── Commands ────────────────────────────────────────────────────────────

	pi.registerCommand("plan-status", {
		description: "Show current plan tracker status",
		handler: async (_args: any, ctx: ExtensionContext) => {
			reconstructState(ctx);
			ctx.ui.notify(formatStatus(tasks), tasks.length > 0 ? "info" : "warning");
		},
	});

	pi.registerCommand("plan-review", {
		description: "Review plan todos grouped by status",
		handler: async (_args: any, ctx: ExtensionContext) => {
			reconstructState(ctx);
			const result = handleReview(tasks);
			ctx.ui.notify(result.text, tasks.length > 0 ? "info" : "warning");
		},
	});

	pi.registerCommand("plan-clear", {
		description: "Clear the active plan",
		handler: async (_args: any, ctx: ExtensionContext) => {
			reconstructState(ctx);
			const count = tasks.length;
			tasks = [];
			updateWidget(ctx);
			ctx.ui.notify(
				count > 0 ? `Plan cleared (${count} tasks)` : "No plan was active",
				count > 0 ? "success" : "warning",
			);
		},
	});
}


export default function planModeExtension(pi: ExtensionAPI): void {
	registerPlanTracker(pi);
	let planModeEnabled = false;
	let executionMode = false;
	let todoItems: TodoItem[] = [];

	pi.registerFlag("plan", {
		description: "Start in plan mode (read-only exploration)",
		type: "boolean",
		default: false,
	});

	function updateStatus(ctx: ExtensionContext): void {
		if (!ctx.hasUI) return;

		// Footer status
		if (executionMode && todoItems.length > 0) {
			const completed = todoItems.filter((t) => t.completed).length;
			ctx.ui.setStatus("plan-mode", ctx.ui.theme.fg("accent", `📋 ${completed}/${todoItems.length}`));
		} else if (planModeEnabled) {
			ctx.ui.setStatus("plan-mode", ctx.ui.theme.fg("warning", "⏸ plan"));
		} else {
			ctx.ui.setStatus("plan-mode", undefined);
		}

		// Widget showing todo list
		if (executionMode && todoItems.length > 0) {
			const lines = todoItems.map((item) => {
				if (item.completed) {
					return (
						ctx.ui.theme.fg("success", "☑ ") + ctx.ui.theme.fg("muted", ctx.ui.theme.strikethrough(item.text))
					);
				}
				return `${ctx.ui.theme.fg("muted", "☐ ")}${item.text}`;
			});
			ctx.ui.setWidget("plan-todos", lines);
		} else {
			ctx.ui.setWidget("plan-todos", undefined);
		}
	}

	function togglePlanMode(ctx: ExtensionContext): void {
		planModeEnabled = !planModeEnabled;
		executionMode = false;
		todoItems = [];

		if (planModeEnabled) {
			pi.setActiveTools(PLAN_MODE_TOOLS);
			ctx.ui.notify(`Plan mode enabled. Tools: ${PLAN_MODE_TOOLS.join(", ")}`);
		} else {
			pi.setActiveTools(NORMAL_MODE_TOOLS);
			ctx.ui.notify("Plan mode disabled. Full access restored.");
		}
		updateStatus(ctx);
	}

	function persistState(): void {
		pi.appendEntry("plan-mode", {
			enabled: planModeEnabled,
			todos: todoItems,
			executing: executionMode,
		});
	}

	pi.registerCommand("plan", {
		description: "Toggle plan mode (read-only exploration)",
		handler: async (args, ctx) => {
			// Delegate /plan <goal> to the pipelines extension (spawn plan preset).
			if (typeof args === "string" && args.trim()) {
				const start = (globalThis as { __pipelinesStartPlan?: (g: { goal: string }) => void }).__pipelinesStartPlan;
				if (start) {
					start({ goal: args.trim() });
					return;
				}
			}
			togglePlanMode(ctx);
		},
	});

	pi.registerCommand("todos", {
		description: "Show current plan todo list",
		handler: async (_args, ctx) => {
			if (todoItems.length === 0) {
				ctx.ui.notify("No todos. Create a plan first with /plan", "info");
				return;
			}
			const list = todoItems.map((item, i) => `${i + 1}. ${item.completed ? "✓" : "○"} ${item.text}`).join("\n");
			ctx.ui.notify(`Plan Progress:\n${list}`, "info");
		},
	});

	pi.registerShortcut(Key.ctrlAlt("p"), {
		description: "Toggle plan mode",
		handler: async (ctx) => togglePlanMode(ctx),
	});

	// Block destructive bash commands in plan mode
	pi.on("tool_call", async (event) => {
		if (!planModeEnabled || event.toolName !== "bash") return;

		const command = event.input.command as string;
		if (!isSafeCommand(command)) {
			return {
				block: true,
				reason: `Plan mode: command blocked (not allowlisted). Use /plan to disable plan mode first.\nCommand: ${command}`,
			};
		}
	});

	// Filter out stale plan mode context when not in plan mode
	pi.on("context", async (event) => {
		if (planModeEnabled) return;

		return {
			messages: event.messages.filter((m) => {
				const msg = m as AgentMessage & { customType?: string };
				if (msg.customType === "plan-mode-context") return false;
				if (msg.role !== "user") return true;

				const content = msg.content;
				if (typeof content === "string") {
					return !content.includes("[PLAN MODE ACTIVE]");
				}
				if (Array.isArray(content)) {
					return !content.some(
						(c) => c.type === "text" && (c as TextContent).text?.includes("[PLAN MODE ACTIVE]"),
					);
				}
				return true;
			}),
		};
	});

	// Inject plan/execution context before agent starts
	pi.on("before_agent_start", async () => {
		if (planModeEnabled) {
			return {
				message: {
					customType: "plan-mode-context",
					content: `[PLAN MODE ACTIVE]
You are in plan mode - a read-only exploration mode for safe code analysis.

Restrictions:
- You can only use: read, bash, grep, find, ls, ask_user_question
- You CANNOT use: edit, write (file modifications are disabled)
- Bash is restricted to an allowlist of read-only commands

Ask clarifying questions using the ask_user_question tool.
Use brave-search skill via bash for web research.

Create a detailed numbered plan under a "Plan:" header:

Plan:
1. First step description
2. Second step description
...

Do NOT attempt to make changes - just describe what you would do.`,
					display: false,
				},
			};
		}

		if (executionMode && todoItems.length > 0) {
			const remaining = todoItems.filter((t) => !t.completed);
			const todoList = remaining.map((t) => `${t.step}. ${t.text}`).join("\n");
			return {
				message: {
					customType: "plan-execution-context",
					content: `[EXECUTING PLAN - Full tool access enabled]

Remaining steps:
${todoList}

Execute each step in order.
After completing a step, include a [DONE:n] tag in your response.`,
					display: false,
				},
			};
		}
	});

	// Track progress after each turn
	pi.on("turn_end", async (event, ctx) => {
		if (!executionMode || todoItems.length === 0) return;
		if (!isAssistantMessage(event.message)) return;

		const text = getTextContent(event.message);
		const nextTodoItems = markCompletedSteps(text, todoItems);
		const changed = nextTodoItems.some(
			(item, index) => item.completed !== todoItems[index]?.completed,
		);
		todoItems = nextTodoItems;
		if (changed) {
			updateStatus(ctx);
		}
		persistState();
	});

	// Handle plan completion and plan mode UI
	pi.on("agent_end", async (event, ctx) => {
		// Check if execution is complete
		if (executionMode && todoItems.length > 0) {
			if (todoItems.every((t) => t.completed)) {
				const completedList = todoItems.map((t) => `~~${t.text}~~`).join("\n");
				pi.sendMessage(
					{ customType: "plan-complete", content: `**Plan Complete!** ✓\n\n${completedList}`, display: true },
					{ triggerTurn: false },
				);
				executionMode = false;
				todoItems = [];
				pi.setActiveTools(NORMAL_MODE_TOOLS);
				updateStatus(ctx);
				persistState(); // Save cleared state so resume doesn't restore old execution mode
			}
			return;
		}

		if (!planModeEnabled) return;

		// Extract todos from last assistant message
		const lastAssistant = [...event.messages].reverse().find(isAssistantMessage);
		if (lastAssistant) {
			todoItems = extractTodoItems(getTextContent(lastAssistant));
		}

		// Show plan steps and prompt for next action
		if (todoItems.length > 0) {
			const todoListText = todoItems.map((t, i) => `${i + 1}. ☐ ${t.text}`).join("\n");
			pi.sendMessage(
				{
					customType: "plan-todo-list",
					content: `**Plan Steps (${todoItems.length}):**\n\n${todoListText}`,
					display: true,
				},
				{ triggerTurn: false },
			);
		}

		const executePlan = (): void => {
			planModeEnabled = false;
			executionMode = todoItems.length > 0;
			pi.setActiveTools(NORMAL_MODE_TOOLS);
			updateStatus(ctx);

			const execMessage =
				todoItems.length > 0
					? `Execute the plan. Start with: ${todoItems[0].text}`
					: "Execute the plan you just created.";
			pi.sendMessage(
				{ customType: "plan-mode-execute", content: execMessage, display: true },
				{ triggerTurn: true },
			);
		};

		if (!ctx.hasUI) {
			if (todoItems.length === 0) {
				pi.sendMessage(
					{
						customType: "plan-mode-warning",
						content:
							"Warning: no todo items were extracted from the plan. Proceeding with full access and without progress tracking.",
						display: true,
					},
					{ triggerTurn: false },
				);
			}
			executePlan();
			return;
		}

		const executeLabel = todoItems.length > 0 ? "Execute the plan (track progress)" : "Execute the plan";
		const choices =
			todoItems.length > 0
				? [executeLabel, "Stay in plan mode", "Refine the plan"]
				: [executeLabel, "Stay in plan mode", "Refine the plan"];

		const choice = await ctx.ui.select("Plan mode - what next?", choices);

		if (choice === executeLabel && todoItems.length > 0) {
			executePlan();
		} else if (choice === "Execute the plan") {
			const confirmed = await ctx.ui.select(
				"No todo items were extracted. Executing now will restore full access without progress tracking. Continue?",
				["Continue", "Stay in plan mode"],
			);
			if (confirmed === "Continue") executePlan();
		} else if (choice === "Refine the plan") {
			const refinement = await ctx.ui.editor("Refine the plan:", "");
			if (refinement?.trim()) {
				pi.sendUserMessage(refinement.trim(), { deliverAs: "followUp" });
			}
		}
	});

	// Restore state on session start/resume
	pi.on("session_start", async (_event, ctx) => {
		if (pi.getFlag("plan") === true) {
			planModeEnabled = true;
		}

		const entries = ctx.sessionManager.getEntries();

		// Restore persisted state
		const planModeEntry = entries
			.filter((e: { type: string; customType?: string }) => e.type === "custom" && e.customType === "plan-mode")
			.pop() as { data?: { enabled: boolean; todos?: TodoItem[]; executing?: boolean } } | undefined;

		if (planModeEntry?.data) {
			planModeEnabled = planModeEntry.data.enabled ?? planModeEnabled;
			todoItems = planModeEntry.data.todos ?? todoItems;
			executionMode = planModeEntry.data.executing ?? executionMode;
		}

		// On resume: re-scan messages to rebuild completion state
		// Only scan messages AFTER the last "plan-mode-execute" to avoid picking up [DONE:n] from previous plans
		const isResume = planModeEntry !== undefined;
		if (isResume && executionMode && todoItems.length > 0) {
			// Find the index of the last plan-mode-execute entry (marks when current execution started)
			let executeIndex = -1;
			for (let i = entries.length - 1; i >= 0; i--) {
				const entry = entries[i] as { type: string; customType?: string };
				if (entry.customType === "plan-mode-execute") {
					executeIndex = i;
					break;
				}
			}

			// Only scan messages after the execute marker
			const messages: AssistantMessage[] = [];
			for (let i = executeIndex + 1; i < entries.length; i++) {
				const entry = entries[i];
				if (entry.type === "message" && "message" in entry && isAssistantMessage(entry.message as AssistantMessage)) {
					messages.push(entry.message as AssistantMessage);
				}
			}
			const allText = messages.map(getTextContent).join("\n");
			todoItems = markCompletedSteps(allText, todoItems);
		}

		if (planModeEnabled) {
			pi.setActiveTools(PLAN_MODE_TOOLS);
		}
		updateStatus(ctx);
	});
}
