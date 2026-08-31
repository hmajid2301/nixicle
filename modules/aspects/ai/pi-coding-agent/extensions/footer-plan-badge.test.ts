import { describe, expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";

describe("footer plan badge removal", () => {
	test("custom footer no longer renders plan badge", () => {
		const source = readFileSync(join(import.meta.dir, "footer.ts"), "utf8");

		expect(source.includes("planBadge(theme)")).toBe(false);
		expect(source.includes("function planBadge(")).toBe(false);
	});
});
