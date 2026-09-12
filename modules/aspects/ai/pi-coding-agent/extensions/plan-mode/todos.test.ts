import { describe, expect, test } from "bun:test";
import { extractTodoItems, markCompletedSteps } from "./todos";

describe("plan-mode todo parsing", () => {
	test("extracts numbered plan steps and normalizes display text", () => {
		const todos = extractTodoItems(`Intro

**Plan:**
1. **Read the target files**
   - preserve details
2) Run \`bun test modules/aspects/ai/pi-coding-agent/extensions\`
3. Update the extension entrypoint with a very long implementation detail that should be truncated cleanly
`);

		expect(todos).toEqual([
			{ step: 1, text: "**Read the target files", completed: false },
			{ step: 2, text: "Bun test...", completed: false },
			{ step: 3, text: "Extension entrypoint with a very long...", completed: false },
		]);
	});

	test("marks done tags case-insensitively without clearing previous completion", () => {
		const todos = [
			{ step: 1, text: "One", completed: true },
			{ step: 2, text: "Two", completed: false },
			{ step: 3, text: "Three", completed: false },
		];

		expect(markCompletedSteps("Finished [done:2] and [DONE:99]", todos)).toEqual([
			{ step: 1, text: "One", completed: true },
			{ step: 2, text: "Two", completed: true },
			{ step: 3, text: "Three", completed: false },
		]);
	});
});
