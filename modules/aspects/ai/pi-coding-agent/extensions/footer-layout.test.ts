import { describe, expect, test } from "bun:test";
import { buildRightFooterParts } from "./footer-layout";

describe("buildRightFooterParts", () => {
	test("includes session name with remaining right-side badges", () => {
		const parts = buildRightFooterParts({
			modelId: "openai-codex/gpt-5.4",
			sessionName: "scrollback-fix",
			thinkingBadge: "● high",
		});

		expect(parts).toEqual([
			"openai-codex/gpt-5.4",
			"scrollback-fix",
			"● high",
		]);
	});

	test("omits empty session name", () => {
		const parts = buildRightFooterParts({
			modelId: "openai-codex/gpt-5.4",
			sessionName: "",
			thinkingBadge: "",
			planBadge: "",
		});

		expect(parts).toEqual([
			"openai-codex/gpt-5.4",
		]);
	});
});
