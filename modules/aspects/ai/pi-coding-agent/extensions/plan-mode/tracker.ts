import { StringEnum } from "@mariozechner/pi-ai";
import { Type, type Static } from "typebox";

export type TaskStatus = "pending" | "in_progress" | "complete";

export interface Task {
	name: string;
	status: TaskStatus;
}

export type ActionType = "init" | "update" | "status" | "review" | "clear";

export interface PlanTrackerDetails {
	action: ActionType;
	tasks: Task[];
	error?: string;
	updatedIndex?: number;
}

export interface ActionResult {
	text: string;
	tasks: Task[];
	error?: string;
	updatedIndex?: number;
}

export const PlanTrackerParams = Type.Object({
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

export type PlanTrackerInput = Static<typeof PlanTrackerParams>;

export function handleInit(taskNames: string[] | undefined): ActionResult {
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

export function handleUpdate(
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

export function handleStatusAction(tasks: Task[]): ActionResult {
	return {
		text: formatStatus(tasks),
		tasks: [...tasks],
	};
}

export function handleReview(tasks: Task[]): ActionResult {
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

export function handleClear(tasks: Task[]): ActionResult {
	const count = tasks.length;
	return {
		text: count > 0 ? `Plan cleared (${count} tasks removed).` : "No plan was active.",
		tasks: [],
	};
}

export function formatStatus(tasks: Task[]): string {
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

export function renderWidgetLines(tasks: Task[], theme: any, width: number): string[] {
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

	for (const [_label, status, icon] of groups) {
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

export interface BranchEntry {
	type: string;
	message?: {
		role: string;
		toolName?: string;
		details?: PlanTrackerDetails;
	};
}

export function isTaskStatus(status: unknown): status is TaskStatus {
	return status === "pending" || status === "in_progress" || status === "complete";
}

export function reconstructFromBranch(entries: BranchEntry[]): Task[] {
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
					isTaskStatus(task.status),
			);
		if (hasValidTasks) {
			tasks = details.tasks.map((task) => ({ ...task }));
		}
	}
	return tasks;
}
