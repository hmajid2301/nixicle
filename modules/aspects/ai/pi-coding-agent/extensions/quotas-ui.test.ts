import { describe, expect, test } from "bun:test";
import { shouldRenderQuotaStatus } from "./quotas-ui";

describe("shouldRenderQuotaStatus", () => {
	test("renders quota status in regular and fullscreen TUI modes", () => {
		expect(shouldRenderQuotaStatus({
			uiMode: "regular",
			previousText: undefined,
			nextText: "codex 5h:20%",
		})).toBe(true);

		expect(shouldRenderQuotaStatus({
			uiMode: undefined,
			previousText: undefined,
			nextText: "codex 5h:20%",
		})).toBe(false);
	});

	test("renders in fullscreen only when text changed", () => {
		expect(shouldRenderQuotaStatus({
			uiMode: "fullscreen",
			previousText: undefined,
			nextText: "codex 5h:20%",
		})).toBe(true);

		expect(shouldRenderQuotaStatus({
			uiMode: "fullscreen",
			previousText: "codex 5h:20%",
			nextText: "codex 5h:20%",
		})).toBe(false);
	});
});
