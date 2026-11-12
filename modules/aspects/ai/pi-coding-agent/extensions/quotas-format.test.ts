import { expect, test } from "bun:test";
import { formatQuotaFooter } from "./quotas.ts";

const now = Date.UTC(2026, 0, 1);
const theme = { fg: (_color: string, text: string) => text };
const primary = { label: "5h", usedPercent: 28, resetsAt: new Date(now + 134 * 60000), windowSeconds: 18000 };
const weekly = { label: "7d", usedPercent: 16, resetsAt: new Date(now + 3 * 86400000), windowSeconds: 604800 };

test("formats Claude-style used percentages and the primary reset only", () => {
	expect(formatQuotaFooter(theme, { provider: "openai-codex", windows: [primary, weekly] }, now))
		.toBe(" 28% ⟳2h14m │  16%");
});

test("distinguishes Zen monthly windows and limited/error states", () => {
	const monthly = { ...weekly, label: "m", usedPercent: 9, windowSeconds: 2592000 };
	expect(formatQuotaFooter(theme, { provider: "opencode-go", windows: [primary, weekly, monthly] }, now))
		.toBe(" 28% ⟳2h14m │  16% │  m9%");
	expect(formatQuotaFooter(theme, { provider: "openai-codex", windows: [{ ...primary, usedPercent: 100, limited: true, resetsAt: new Date(now - 1) }] }, now))
		.toBe(" 100% ⟳0m!");
	expect(formatQuotaFooter(theme, { provider: "openai-codex", windows: [{ ...primary, resetsAt: new Date(NaN) }] }, now))
		.toBe(" 28%");
	expect(formatQuotaFooter(theme, { provider: "openai-codex", windows: [] }, now)).toBeUndefined();
});
