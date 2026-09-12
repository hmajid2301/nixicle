import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { Text } from "@mariozechner/pi-tui";
import {
	formatStatus,
	handleClear,
	handleInit,
	handleReview,
	handleStatusAction,
	handleUpdate,
	PlanTrackerParams,
	reconstructFromBranch,
	renderWidgetLines,
	type ActionResult,
	type ActionType,
	type BranchEntry,
	type PlanTrackerDetails,
	type Task,
	type TaskStatus,
} from "./tracker.ts";

export function registerPlanTracker(pi: ExtensionAPI) {
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
