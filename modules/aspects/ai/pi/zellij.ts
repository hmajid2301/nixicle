/**
 * Zellij Pi Extension
 *
 * Tools:
 *   zellij_list_sessions, zellij_list_tabs, zellij_list_panes,
 *   zellij_dump_pane, zellij_current_tab, zellij_new_pane
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type, StringEnum } from "@mariozechner/pi-ai";

// ── Helpers ────────────────────────────────────────────────────────────────────

const ZELLIJ_TIMEOUT = 10_000;

async function runZellij(pi: ExtensionAPI, args: string[], session?: string): Promise<string> {
	const env: Record<string, string> = {};
	if (session) env.ZELLIJ_SESSION_NAME = session;
	const result = await pi.exec("zellij", args, { env, timeout: ZELLIJ_TIMEOUT });
	if (result.code !== 0 && !result.killed) throw new Error(result.stderr || result.stdout);
	return result.stdout;
}

// ── Extension ─────────────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "zellij_list_sessions",
		label: "Zellij Sessions",
		description: "List all active Zellij sessions",
		parameters: Type.Object({}),
		async execute() {
			const output = await runZellij(pi, ["list-sessions"]);
			return { content: [{ type: "text" as const, text: output || "No active sessions." }], details: {} };
		},
	});

	pi.registerTool({
		name: "zellij_list_tabs",
		label: "Zellij Tabs",
		description: "List all tabs in a Zellij session",
		parameters: Type.Object({
			session: Type.Optional(Type.String({ description: "Session name (current if omitted)" })),
		}),
		async execute(_, params) {
			const output = await runZellij(pi, ["action", "list-tabs", "-j"], params.session);
			return { content: [{ type: "text" as const, text: output }], details: { output: JSON.parse(output) } };
		},
	});

	pi.registerTool({
		name: "zellij_list_panes",
		label: "Zellij Panes",
		description: "List all panes with detailed info (JSON)",
		parameters: Type.Object({
			session: Type.Optional(Type.String({ description: "Session name" })),
			tab: Type.Optional(Type.String({ description: "Tab name or ID to filter" })),
		}),
		async execute(_, params) {
			const output = await runZellij(pi, ["action", "list-panes", "-j", "-a", "-c", "-g", "-s", "-t"], params.session);
			let panes = JSON.parse(output);
			if (params.tab) panes = panes.filter((p: any) => p.tab_name === params.tab || String(p.tab_id) === params.tab);
			const summary = panes.map((p: any) => ({ id: p.id, title: p.title, tab: p.tab_name, cwd: p.pane_cwd, focused: p.is_focused, floating: p.is_floating }));
			return { content: [{ type: "text" as const, text: JSON.stringify(summary, null, 2) }], details: { panes: summary } };
		},
	});

	pi.registerTool({
		name: "zellij_dump_pane",
		label: "Zellij Dump",
		description: "Dump content (viewport + scrollback) of a specific pane",
		parameters: Type.Object({
			pane_id: Type.String({ description: "Pane ID (e.g. 'terminal_1' or '1')" }),
			session: Type.Optional(Type.String({ description: "Session name" })),
			include_scrollback: Type.Optional(Type.Boolean({ description: "Include scrollback (default true)", default: true })),
		}),
		async execute(_, params) {
			const args = ["action", "dump-screen", "-p", params.pane_id];
			if (params.include_scrollback !== false) args.push("-f");
			const output = await runZellij(pi, args, params.session);
			const maxLen = 50_000;
			const truncated = output.length > maxLen ? output.slice(0, maxLen) + "\n... (truncated)" : output;
			return { content: [{ type: "text" as const, text: truncated }], details: { pane_id: params.pane_id, length: output.length, truncated: output.length > maxLen } };
		},
	});

	pi.registerTool({
		name: "zellij_current_tab",
		label: "Zellij Current Tab",
		description: "Get info about the currently active tab",
		parameters: Type.Object({
			session: Type.Optional(Type.String({ description: "Session name" })),
		}),
		async execute(_, params) {
			const output = await runZellij(pi, ["action", "current-tab-info", "-j"], params.session);
			return { content: [{ type: "text" as const, text: output }], details: { info: JSON.parse(output) } };
		},
	});

	pi.registerTool({
		name: "zellij_new_pane",
		label: "Zellij New Pane",
		description: "Open a new pane with an optional command",
		parameters: Type.Object({
			command: Type.Optional(Type.String({ description: "Command to run" })),
			direction: Type.Optional(StringEnum(["right", "down"] as const, { description: "Direction" })),
			session: Type.Optional(Type.String({ description: "Session name" })),
			cwd: Type.Optional(Type.String({ description: "Working directory" })),
		}),
		async execute(_, params) {
			const args = ["action", "new-pane"];
			if (params.direction) args.push("--direction", params.direction);
			if (params.cwd) args.push("--cwd", params.cwd);
			if (params.command) args.push("--", "bash", "-c", params.command);
			const output = await runZellij(pi, args, params.session);
			return { content: [{ type: "text" as const, text: output || "New pane created." }], details: {} };
		},
	});
}
