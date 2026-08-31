import { describe, expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";

describe("tokens stale ctx guard", () => {
	test("tokens extension catch path does not touch ctx.ui.theme", () => {
		const source = readFileSync(join(import.meta.dir, "tokens.ts"), "utf8");
		expect(source.includes("setStatusSafely(ctx, ctx.ui.theme")).toBe(false);
	});
});
