import { describe, expect, test } from "bun:test";
import { shouldRenderQuotaStatus } from "./quotas-ui";

describe("shouldRenderQuotaStatus", () => {
	test("suppresses automatic quota status renders in regular TUI mode", () => {
		expect(shouldRenderQuotaStatus({
			uiMode: "regular",
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
