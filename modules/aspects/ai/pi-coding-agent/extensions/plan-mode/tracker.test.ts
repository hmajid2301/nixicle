import { describe, expect, test } from "bun:test";
import { handleClear, handleInit, handleReview, handleStatusAction, handleUpdate, reconstructFromBranch } from "./tracker";

describe("plan tracker state", () => {
	test("initializes, updates, reviews, and clears tasks with persisted details", () => {
		const init = handleInit(["Explore", "Implement"]);
		expect(init.text).toContain("Plan initialized with 2 tasks.");
		expect(init.tasks).toEqual([
			{ name: "Explore", status: "pending" },
			{ name: "Implement", status: "pending" },
		]);

		const updated = handleUpdate(init.tasks, 1, "in_progress");
		expect(updated.updatedIndex).toBe(1);
		expect(handleStatusAction(updated.tasks).text).toContain("Plan: 0/2 complete (1 in progress, 1 pending)");
		expect(handleReview(updated.tasks).text).toContain("IN PROGRESS (1):\n  → [1] Implement");
		expect(handleClear(updated.tasks)).toEqual({ text: "Plan cleared (2 tasks removed).", tasks: [] });
	});

	test("reconstructs the last valid plan_tracker result from a branch", () => {
		const tasks = reconstructFromBranch([
			{ type: "message", message: { role: "toolResult", toolName: "plan_tracker", details: { action: "init", tasks: [{ name: "Old", status: "pending" }] } } },
			{ type: "message", message: { role: "toolResult", toolName: "plan_tracker", details: { action: "update", tasks: [{ name: "Broken", status: "bogus" }] } } },
			{ type: "message", message: { role: "toolResult", toolName: "other", details: { action: "clear", tasks: [] } } },
			{ type: "message", message: { role: "toolResult", toolName: "plan_tracker", details: { action: "update", tasks: [{ name: "New", status: "complete" }] } } },
		]);

		expect(tasks).toEqual([{ name: "New", status: "complete" }]);
	});
});
