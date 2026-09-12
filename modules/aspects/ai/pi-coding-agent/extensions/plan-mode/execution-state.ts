import type { TodoItem } from "./todos.ts";

export const PLAN_MODE_TOOLS = ["read", "bash", "grep", "find", "ls", "ask_user_question"];
export const NORMAL_MODE_TOOLS = ["read", "bash", "edit", "write", "grep", "find", "ls", "ask_user_question"];

export function renderTodoWidgetLines(todoItems: TodoItem[], theme: any): string[] {
	return todoItems.map((item) => {
		if (item.completed) {
			return (
				theme.fg("success", "☑ ") + theme.fg("muted", theme.strikethrough(item.text))
			);
		}
		return `${theme.fg("muted", "☐ ")}${item.text}`;
	});
}

export function planModeContextMessage(): string {
	return `[PLAN MODE ACTIVE]
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

Do NOT attempt to make changes - just describe what you would do.`;
}

export function executionContextMessage(todoItems: TodoItem[]): string {
	const remaining = todoItems.filter((t) => !t.completed);
	const todoList = remaining.map((t) => `${t.step}. ${t.text}`).join("\n");
	return `[EXECUTING PLAN - Full tool access enabled]

Remaining steps:
${todoList}

Execute each step in order.
After completing a step, include a [DONE:n] tag in your response.`;
}
