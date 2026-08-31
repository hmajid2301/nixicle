import { describe, expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";

const RUNTIME_EXTENSIONS = ["footer.ts", "quotas.ts"] as const;

describe("runtime-loaded extensions stay self-contained", () => {
	for (const file of RUNTIME_EXTENSIONS) {
		test(`${file} has no relative imports`, () => {
			const source = readFileSync(join(import.meta.dir, file), "utf8");
			expect(source).not.toMatch(/from\s+['"]\.\.?\//);
		});
	}
});
