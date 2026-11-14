import { describe, expect, test } from "bun:test";
import { shouldRenderQuotaStatus } from "./quotas.ts";

describe("shouldRenderQuotaStatus", () => {
	test("renders when the status text changes", () => {
		expect(shouldRenderQuotaStatus({ previousText: undefined, nextText: "codex 5h:20%" })).toBe(true);
		expect(shouldRenderQuotaStatus({ previousText: "codex 5h:20%", nextText: "codex 5h:21%" })).toBe(true);
	});

	test("skips unchanged status text", () => {
		expect(shouldRenderQuotaStatus({ previousText: "codex 5h:20%", nextText: "codex 5h:20%" })).toBe(false);
		expect(shouldRenderQuotaStatus({ previousText: undefined, nextText: undefined })).toBe(false);
	});
});
