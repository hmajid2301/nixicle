import { describe, expect, test } from "bun:test";
import { restorePlanModeState } from "./persistence";

describe("plan mode persisted execution state", () => {
	test("restores persisted state and reapplies done tags only after the latest execute marker", () => {
		const restored = restorePlanModeState({ planModeEnabled: false, executionMode: false, todoItems: [] }, [
			{ type: "message", message: { role: "assistant", content: [{ type: "text", text: "stale [DONE:2]" }] } },
			{ type: "custom", customType: "plan-mode", data: { enabled: false, executing: true, todos: [
				{ step: 1, text: "One", completed: false },
				{ step: 2, text: "Two", completed: false },
			] } },
			{ type: "custom", customType: "plan-mode-execute" },
			{ type: "message", message: { role: "assistant", content: [{ type: "text", text: "fresh [DONE:1]" }] } },
		]);

		expect(restored).toEqual({
			planModeEnabled: false,
			executionMode: true,
			todoItems: [
				{ step: 1, text: "One", completed: true },
				{ step: 2, text: "Two", completed: false },
			],
			isResume: true,
		});
	});
});
