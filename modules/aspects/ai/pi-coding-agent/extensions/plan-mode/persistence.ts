import type { AssistantMessage } from "@mariozechner/pi-ai";
import { getTextContent, isAssistantMessage } from "./messages.ts";
import { markCompletedSteps, type TodoItem } from "./todos.ts";

export interface PlanModeRuntimeState {
	planModeEnabled: boolean;
	executionMode: boolean;
	todoItems: TodoItem[];
}

export interface RestoredPlanModeState extends PlanModeRuntimeState {
	isResume: boolean;
}

export interface SessionEntry {
	type: string;
	customType?: string;
	data?: {
		enabled?: boolean;
		todos?: TodoItem[];
		executing?: boolean;
	};
	message?: unknown;
}

export function findLatestPlanModeEntry(entries: SessionEntry[]): SessionEntry | undefined {
	return entries
		.filter((e) => e.type === "custom" && e.customType === "plan-mode")
		.pop();
}

export function restorePlanModeState(initial: PlanModeRuntimeState, entries: SessionEntry[]): RestoredPlanModeState {
	const planModeEntry = findLatestPlanModeEntry(entries);
	let planModeEnabled = initial.planModeEnabled;
	let todoItems = initial.todoItems;
	let executionMode = initial.executionMode;

	if (planModeEntry?.data) {
		planModeEnabled = planModeEntry.data.enabled ?? planModeEnabled;
		todoItems = planModeEntry.data.todos ?? todoItems;
		executionMode = planModeEntry.data.executing ?? executionMode;
	}

	const isResume = planModeEntry !== undefined;
	if (isResume && executionMode && todoItems.length > 0) {
		let executeIndex = -1;
		for (let i = entries.length - 1; i >= 0; i--) {
			const entry = entries[i] as { customType?: string };
			if (entry.customType === "plan-mode-execute") {
				executeIndex = i;
				break;
			}
		}

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

	return { planModeEnabled, executionMode, todoItems, isResume };
}
