import { expect, test } from "bun:test";
import { parseClaudeUsage } from "./quotas.ts";

test("maps Claude OAuth usage to 5h and 7d windows", () => {
	const usage = parseClaudeUsage({
		five_hour: { utilization: 39.0, resets_at: "2026-11-16T00:10:00.380298+00:00" },
		seven_day: { utilization: 22.0, resets_at: "2026-11-20T05:00:00.380317+00:00" },
		seven_day_opus: null,
	});
	expect(usage).toEqual({
		provider: "claude-code",
		windows: [
			{ label: "5h", usedPercent: 39, resetsAt: new Date("2026-11-16T00:10:00.380Z"), windowSeconds: 18000 },
			{ label: "7d", usedPercent: 22, resetsAt: new Date("2026-11-20T05:00:00.380Z"), windowSeconds: 604800 },
		],
	});
});

test("skips missing windows and reports an empty payload", () => {
	expect(parseClaudeUsage({ five_hour: null, seven_day: { utilization: 5, resets_at: null } })).toEqual({
		provider: "claude-code",
		windows: [{ label: "7d", usedPercent: 5, resetsAt: new Date(0), windowSeconds: 604800 }],
	});
	expect(parseClaudeUsage({})).toEqual({ error: "Claude usage endpoint returned no windows" });
});
