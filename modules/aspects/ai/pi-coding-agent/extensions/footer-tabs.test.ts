import { expect, test } from "bun:test";
import { visibleWidth } from "@mariozechner/pi-tui";
import statusline, { renderFooterLines } from "./footer.ts";

const data = {
	branch: "main",
	sessionName: "Fix login bug",
	modelId: "gpt-5.4",
	thinkingLevel: "medium",
	used: 32000,
	total: 128000,
	quotaStatus: " 28% ⟳2h14m │  16%",
};
const plain = (text: string) => text.replace(/\x1b\[[0-9;]*m/g, "");

test("copies Claude's fused lavender tabs and compact usage layout", () => {
	const lines = renderFooterLines(data, 150);
	const text = plain(lines.join("\n"));
	expect(lines).toHaveLength(1);
	expect(text).toContain("   main ");
	expect(text).toContain("   Fix login bug ");
	expect(text).toContain(" ▓▓░░░░░░░░ 32k/128k");
	expect(text).toContain(" 28% ⟳2h14m │  16%");
	expect(text).toContain("󰚩 gpt-5.4 ·medium");
	expect(text).not.toMatch(/working|idle|↑|↓|\$/);
	expect(lines[0]).toContain("\x1b[48;2;180;190;254m");
	expect(lines[0]).toContain("\x1b[48;2;49;50;68m");
});

test("right-aligns usage and model against the terminal edge", () => {
	const line = renderFooterLines(data, 150)[0];
	expect(visibleWidth(line)).toBe(150);
	expect(plain(line)).toMatch(/gpt-5\.4 ·medium$/);
	expect(plain(line)).toMatch(/^ /);
});

test("preserves names beyond the old fixed truncation limits", () => {
	const name = "Improve footer names without shortening their useful context";
	const branch = "feat/a-branch-name-longer-than-twenty-four-columns";
	const text = plain(renderFooterLines({ ...data, sessionName: name, branch }, 240).join("\n"));
	expect(text).toContain(name);
	expect(text).toContain(branch);
	expect(text).not.toMatch(/…|\.\.\./);
});

test("puts the full session name above stats instead of dropping or ellipsizing it", () => {
	const name = "Investigate a long session title without losing any of its words";
	const lines = renderFooterLines({ ...data, sessionName: name }, 50);
	const text = plain(lines.join("\n"));
	expect(lines.length).toBeGreaterThan(1);
	for (const word of name.split(" ")) expect(text).toContain(word);
	expect(text).toContain("gpt-5.4");
	expect(text).toContain("28%");
	expect(text).not.toMatch(/…|\.\.\./);
	for (const line of lines) expect(visibleWidth(line)).toBeLessThanOrEqual(50);
});

test("wraps Unicode and unbroken names within terminal columns", () => {
	for (const sessionName of ["修复登录".repeat(30), "a".repeat(160), "👩‍💻".repeat(20)]) {
		for (const width of [0, 1, 5, 10, 30, 80, 120]) {
			const lines = renderFooterLines({ ...data, sessionName }, width);
			for (const line of lines) expect(visibleWidth(line)).toBeLessThanOrEqual(width);
			expect(plain(lines.join("\n"))).not.toContain("…");
			if (width >= 30) {
				const reconstructed = plain(lines.join(""))
					.replace(/   | /g, "").replace(/\s/g, "");
				expect(reconstructed).toContain(sessionName);
			}
		}
	}
});

test("handles unset names, context, local models, and control characters", () => {
	const text = plain(renderFooterLines({
		...data, branch: undefined, sessionName: undefined, quotaStatus: undefined,
		thinkingLevel: "off", used: null,
	}, 50).join("\n"));
	expect(text).toContain("--/128k");
	expect(text).toContain("gpt-5.4");
	expect(text).not.toMatch(/undefined|off||/);
	expect(text.startsWith(" ")).toBe(false);
	expect(plain(renderFooterLines({ ...data, used: 200000 }, 150).join(""))).toContain("200k/128k");
	expect(plain(renderFooterLines({ ...data, used: 0 }, 150).join(""))).toContain("0k/128k");
	expect(plain(renderFooterLines({ ...data, sessionName: "hello\x1b\nworld" }, 150).join(""))).toContain("hello world");
});

test("reads quota statuses and fresh context without showing unrelated spend plugins", async () => {
	const handlers = new Map<string, Function[]>();
	const statuses = new Map([[
		"provider-quota", data.quotaStatus,
	], ["token-usage", "spend:$99"]]);
	let factory: Function | undefined;
	let renders = 0;
	const ctx = {
		hasUI: true,
		getContextUsage: () => ({ tokens: 32000, contextWindow: 128000 }),
		model: { id: "gpt-5.4", contextWindow: 1000000 },
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
	const footer = factory!({ requestRender: () => { renders++; } }, {}, {
		getGitBranch: () => "main",
		getExtensionStatuses: () => statuses,
		onBranchChange: () => () => {},
	});
	const text = plain(footer.render(150).join("\n"));
	expect(text).toContain("32k/128k");
	expect(text).toContain("28%");
	expect(text).not.toContain("spend");
	statuses.set("provider-quota", " 29% ⟳2h13m");
	expect(plain(footer.render(150).join(""))).toContain("29%");
	for (const handler of handlers.get("session_info_changed") ?? []) await handler({}, ctx);
	expect(renders).toBeGreaterThan(0);
	footer.dispose();
});
