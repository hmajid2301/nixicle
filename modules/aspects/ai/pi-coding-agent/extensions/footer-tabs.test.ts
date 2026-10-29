import { expect, test } from "bun:test";
import { visibleWidth } from "@mariozechner/pi-tui";
import statusline, { renderFooterLine } from "./footer.ts";

const data = {
	branch: "main",
	sessionName: "Fix login bug",
	modelId: "gpt-5.4",
	thinkingLevel: "medium",
	used: 32000,
	total: 128000,
	input: 23000,
	output: 8000,
	cost: 0.12,
	working: true,
	turnCount: 7,
	elapsed: "12m",
};
const plain = (text: string) => text.replace(/\x1b\[[0-9;]*m/g, "");

test("renders fused rounded tabs and preserves session stats", () => {
	const line = renderFooterLine(data, 180);
	const text = plain(line);
	expect(text).toContain("");
	expect(text).toContain("");
	expect(text).toContain("main");
	expect(text).toContain("Fix login bug");
	expect(text).toContain("working #7 12m");
	expect(text).toContain("32.0k/128.0k");
	expect(text).toContain("25%");
	expect(text).toContain("↑23.0k ↓8.0k $0.120");
	expect(text).toContain("gpt-5.4 · medium");
	expect(line).toContain("\x1b[48;2;49;50;68m");
	expect(visibleWidth(line)).toBeLessThanOrEqual(180);
	expect(text).not.toMatch(/ {3,}/);
});

test("uses distinct Catppuccin accents for tabs, model, and thinking", () => {
	const line = renderFooterLine(data, 180);
	expect(line).toContain("\x1b[48;2;203;166;247m");
	expect(line).toContain("\x1b[48;2;137;220;235m");
	expect(line).toContain("\x1b[38;2;180;190;254m󰚩 gpt-5.4");
	expect(line).toContain("\x1b[38;2;250;179;135m · medium");
});

test("hides token stats before activity and shortens names before dropping tabs", () => {
	const medium = plain(renderFooterLine(data, 120));
	expect(medium).not.toContain("↑");
	expect(medium).not.toContain("$");
	expect(medium).toContain("working #7 12m");
	expect(medium).toContain("main");
	expect(medium).toContain("Fix login bug");

	const compact = plain(renderFooterLine({
		...data,
		branch: "feat/a-very-long-branch-name",
		sessionName: "A very long session title that needs shortening",
	}, 120));
	expect(compact).toContain("");
	expect(compact).toContain("");
	expect(compact).not.toContain("↑");
	expect(compact).toContain("gpt-5.4");
	expect(compact).toContain("25%");
});

test("drops activity before shortening names when space is limited", () => {
	for (const working of [false, true]) {
		const text = plain(renderFooterLine({
			...data,
			working,
			branch: "feat/compact-footer",
			sessionName: "Improve small screen spacing",
		}, 120));
		expect(text).toContain("feat/compact-footer");
		expect(text).toContain("Improve small screen spacing");
		expect(text).not.toContain(working ? "working" : "idle");
		expect(text).not.toContain("12m");
		expect(text).toContain("gpt-5.4");
		expect(text).toContain("25%");
		expect(text).not.toMatch(/ {3,}/);
	}
});

test("does not indent the stats when there are no tabs", () => {
	const text = plain(renderFooterLine({ ...data, branch: undefined, sessionName: undefined }, 50));
	expect(text.startsWith(" ")).toBe(false);
});

test("uses Claude's session icon and a supported Nerd Font robot", () => {
	const text = plain(renderFooterLine(data, 180));
	expect(text).toContain("");
	expect(text).toContain("󰚩 gpt-5.4");
	expect(text).not.toContain("");
});

test("fits narrow panes and retains model and context at 50 columns", () => {
	const line = renderFooterLine(data, 50);
	expect(visibleWidth(line)).toBeLessThanOrEqual(50);
	expect(plain(line)).toContain("gpt-5.4");
	expect(plain(line)).toContain("25%");
	for (const width of [0, 1, 10, 30, 80, 120]) {
		expect(visibleWidth(renderFooterLine(data, width))).toBeLessThanOrEqual(width);
	}
});

test("fits wide Unicode names and omits unset session or thinking", () => {
	const line = renderFooterLine({ ...data, sessionName: "修复登录".repeat(50), branch: "分支".repeat(40) }, 100);
	expect(visibleWidth(line)).toBeLessThanOrEqual(100);
	const minimal = plain(renderFooterLine({ ...data, sessionName: undefined, branch: undefined, thinkingLevel: "off" }, 160));
	expect(minimal).not.toContain("undefined");
	expect(minimal).not.toContain(" · off");
});

test("distinguishes unknown context from empty context and clamps progress", () => {
	expect(plain(renderFooterLine({ ...data, used: null }, 160))).toContain("--/128.0k");
	expect(plain(renderFooterLine({ ...data, used: 0 }, 160))).toContain("0/128.0k");
	expect(plain(renderFooterLine({ ...data, used: 200000 }, 160))).toContain("100%");
});

test("reads current Pi context-window field and refreshes on session naming", async () => {
	const handlers = new Map<string, Function[]>();
	let factory: Function | undefined;
	let renders = 0;
	const ctx = {
		hasUI: true,
		getContextUsage: () => ({ tokens: 32000, contextWindow: 128000 }),
		model: { id: "gpt-5.4", contextWindow: 1000000 },
		sessionManager: { getBranch: () => [] },
		ui: { setFooter: (value: Function) => { factory = value; } },
	};
	statusline({
		on: (event: string, handler: Function) => {
			const list = handlers.get(event) ?? [];
			list.push(handler);
			handlers.set(event, list);
			return () => {};
		},
		registerCommand: () => {},
		getThinkingLevel: () => "off",
		getSessionName: () => "New session title",
	} as any);
	await handlers.get("session_start")![0]({}, ctx);
	const footer = factory!({ requestRender: () => { renders++; } }, { fg: (_color: string, text: string) => text }, {
		getGitBranch: () => "main",
		onBranchChange: () => () => {},
	});
	expect(plain(footer.render(180)[0])).toContain("32.0k/128.0k");
	for (const handler of handlers.get("session_info_changed") ?? []) await handler({}, ctx);
	expect(renders).toBeGreaterThan(0);
	footer.dispose();
});
