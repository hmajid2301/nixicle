/**
 * Plan Tracker Extension
 *
 * A native pi tool for tracking implementation plan progress.
 * State is stored in tool result details for proper branching support.
 * Shows a persistent TUI widget with progress indicators.
 *
 * Actions: init, update, status, review, clear
 */

import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { StringEnum } from "@mariozechner/pi-ai";
import { Text } from "@mariozechner/pi-tui";
import { Type, type Static } from "typebox";

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

export default function register(pi: ExtensionAPI) {
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
