import { describe, expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";

describe("footer tool count removal", () => {
	test("custom footer no longer renders tool count badge", () => {
		const source = readFileSync(join(import.meta.dir, "footer.ts"), "utf8");

		expect(source.includes("toolCount(theme)")).toBe(false);
		expect(source.includes("function toolCount(")).toBe(false);
	});
});
