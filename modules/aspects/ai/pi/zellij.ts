/**
 * Zellij Pi Extension
 *
 * Tools:
 *   zellij_list_sessions, zellij_list_tabs, zellij_list_panes,
 *   zellij_dump_pane, zellij_current_tab, zellij_new_pane,
 *   zellij_send_keys, zellij_new_tab, zellij_close_tab,
 *   zellij_focus_pane, zellij_watch_session
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type, StringEnum } from "@mariozechner/pi-ai";

// ── Helpers ────────────────────────────────────────────────────────────────────

const ZELLIJ_TIMEOUT = 15_000;

async function runZellij(
	pi: ExtensionAPI,
	args: string[],
	session?: string,
	opts?: { timeout?: number },
): Promise<string> {
	const env: Record<string, string> = {};
	if (session) env.ZELLIJ_SESSION_NAME = session;
	const result = await pi.exec("zellij", args, {
		env,
		timeout: opts?.timeout ?? ZELLIJ_TIMEOUT,
	});
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
			if (params.tab)
				panes = panes.filter(
					(p: any) => p.tab_name === params.tab || String(p.tab_id) === params.tab,
				);
			const summary = panes.map((p: any) => ({
				id: p.id,
				title: p.title,
				tab: p.tab_name,
				cwd: p.pane_cwd,
				focused: p.is_focused,
				floating: p.is_floating,
			}));
			return {
				content: [{ type: "text" as const, text: JSON.stringify(summary, null, 2) }],
				details: { panes: summary },
			};
		},
	});

	pi.registerTool({
		name: "zellij_dump_pane",
		label: "Zellij Dump",
		description: "Dump content (viewport + scrollback) of a specific pane",
		parameters: Type.Object({
			pane_id: Type.String({ description: "Pane ID (e.g. 'terminal_1' or '1')" }),
			session: Type.Optional(Type.String({ description: "Session name" })),
			include_scrollback: Type.Optional(
				Type.Boolean({ description: "Include scrollback (default true)", default: true }),
			),
		}),
		async execute(_, params) {
			const args = ["action", "dump-screen", "-p", params.pane_id];
			if (params.include_scrollback !== false) args.push("-f");
			const output = await runZellij(pi, args, params.session);
			const maxLen = 50_000;
			const truncated =
				output.length > maxLen
					? output.slice(0, maxLen) + "\n... (truncated)"
					: output;
			return {
				content: [{ type: "text" as const, text: truncated }],
				details: {
					pane_id: params.pane_id,
					length: output.length,
					truncated: output.length > maxLen,
				},
			};
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
		description:
			"Open a new pane with an optional command. Supports tiled and floating panes.",
		parameters: Type.Object({
			command: Type.Optional(Type.String({ description: "Command to run" })),
			direction: Type.Optional(
				StringEnum(["right", "down"] as const, { description: "Direction" }),
			),
			session: Type.Optional(Type.String({ description: "Session name" })),
			cwd: Type.Optional(Type.String({ description: "Working directory" })),
			floating: Type.Optional(
				Type.Boolean({ description: "Create as a floating pane" }),
			),
			name: Type.Optional(Type.String({ description: "Pane name/title" })),
			pinned: Type.Optional(
				Type.Boolean({ description: "Pin floating pane so it stays on top" }),
			),
			borderless: Type.Optional(
				Type.Boolean({ description: "Create pane without a border" }),
			),
			x: Type.Optional(
				Type.String({ description: "X position (e.g. '10%' or '10')" }),
			),
			y: Type.Optional(
				Type.String({ description: "Y position (e.g. '10%' or '10')" }),
			),
			width: Type.Optional(
				Type.String({ description: "Width (e.g. '80%' or '80')" }),
			),
			height: Type.Optional(
				Type.String({ description: "Height (e.g. '24' or '50%')" }),
			),
			blocking: Type.Optional(
				StringEnum(
					["on_exit", "on_success", "on_failure"] as const,
					{
						description:
							"Block until command exits: on_exit (any exit), on_success (exit 0), on_failure (non-zero)",
					},
				),
			),
		}),
		async execute(_, params) {
			const args = ["action", "new-pane"];
			if (params.direction) args.push("--direction", params.direction);
			if (params.cwd) args.push("--cwd", params.cwd);
			if (params.floating) args.push("--floating");
			if (params.name) args.push("--name", params.name);
			if (params.pinned) args.push("--pinned");
			if (params.borderless) args.push("--borderless");
			if (params.x) args.push("--x", params.x);
			if (params.y) args.push("--y", params.y);
			if (params.width) args.push("--width", params.width);
			if (params.height) args.push("--height", params.height);
			if (params.blocking === "on_exit") args.push("--blocking");
			else if (params.blocking === "on_success") args.push("--block-until-exit-success");
			else if (params.blocking === "on_failure") args.push("--block-until-exit-failure");
			if (params.command) args.push("--", "bash", "-c", params.command);
			const output = await runZellij(pi, args, params.session);
			return {
				content: [{ type: "text" as const, text: output || "New pane created." }],
				details: {},
			};
		},
	});

	// ── New Tools ────────────────────────────────────────────────────────────────

	pi.registerTool({
		name: "zellij_send_keys",
		label: "Zellij Send Keys",
		description:
			"Send keystrokes, paste text, or write characters to a specific pane",
		parameters: Type.Object({
			pane_id: Type.String({ description: "Pane ID to send input to" }),
			action: StringEnum(
				["send-keys", "paste", "write-chars"] as const,
				{ description: "Input method: send-keys (special keys), paste (text), write-chars (char-by-char)" },
			),
			input: Type.String({
				description:
					'Text or keys to send. For send-keys use space-separated values like "Enter" "ctrl c" "Escape". For paste use literal text (multiline OK).',
			}),
			session: Type.Optional(Type.String({ description: "Session name" })),
		}),
		async execute(_, params) {
			const args = ["action", params.action, "--pane-id", params.pane_id];
			if (params.action === "send-keys") {
				// send-keys takes space-separated tokens
				args.push(...params.input.split(/\s+/).filter(Boolean));
			} else {
				args.push(params.input);
			}
			const output = await runZellij(pi, args, params.session);
			return {
				content: [{ type: "text" as const, text: output || "Input sent." }],
				details: {},
			};
		},
	});

	pi.registerTool({
		name: "zellij_new_tab",
		label: "Zellij New Tab",
		description: "Create a new tab, optionally with a command, layout, or name",
		parameters: Type.Object({
			name: Type.Optional(Type.String({ description: "Tab name" })),
			cwd: Type.Optional(Type.String({ description: "Working directory" })),
			session: Type.Optional(Type.String({ description: "Session name" })),
			layout: Type.Optional(
				Type.String({ description: "Path to a layout file (.kdl) or inline layout string" }),
			),
			layout_string: Type.Optional(
				Type.String({ description: "Inline layout KDL string" }),
			),
			command: Type.Optional(Type.String({ description: "Command to run in the first pane" })),
		}),
		async execute(_, params) {
			const args = ["action", "new-tab"];
			if (params.name) args.push("--name", params.name);
			if (params.cwd) args.push("--cwd", params.cwd);
			if (params.layout) args.push("--layout", params.layout);
			if (params.layout_string) args.push("--layout-string", params.layout_string);
			if (params.command) {
				args.push("--", "bash", "-c", params.command);
			}
			const output = await runZellij(pi, args, params.session);
			return {
				content: [{ type: "text" as const, text: output || "New tab created." }],
				details: {},
			};
		},
	});

	pi.registerTool({
		name: "zellij_close_tab",
		label: "Zellij Close Tab",
		description: "Close a specific tab by its ID",
		parameters: Type.Object({
			tab_id: Type.Number({ description: "Tab ID to close" }),
			session: Type.Optional(Type.String({ description: "Session name" })),
		}),
		async execute(_, params) {
			await runZellij(pi, ["action", "close-tab", "--tab-id", String(params.tab_id)], params.session);
			return {
				content: [{ type: "text" as const, text: `Tab ${params.tab_id} closed.` }],
				details: {},
			};
		},
	});

	pi.registerTool({
		name: "zellij_scroll",
		label: "Zellij Scroll",
		description: "Scroll a pane to top, bottom, or by amount",
		parameters: Type.Object({
			pane_id: Type.String({ description: "Pane ID" }),
			direction: StringEnum(
				["top", "bottom", "up", "down", "page_up", "page_down"] as const,
				{ description: "Scroll direction" },
			),
			session: Type.Optional(Type.String({ description: "Session name" })),
			lines: Type.Optional(
				Type.Number({ description: "Number of lines (for up/down)" }),
			),
		}),
		async execute(_, params) {
			const args = ["action"];
			switch (params.direction) {
				case "top":
					args.push("scroll-to-top");
					break;
				case "bottom":
					args.push("scroll-to-bottom");
					break;
				case "up":
					args.push("scroll-up");
					if (params.lines) args.push("--lines", String(params.lines));
					break;
				case "down":
					args.push("scroll-down");
					if (params.lines) args.push("--lines", String(params.lines));
					break;
				case "page_up":
					args.push("page-scroll-up");
					break;
				case "page_down":
					args.push("page-scroll-down");
					break;
			}
			args.push("--pane-id", params.pane_id);
			await runZellij(pi, args, params.session);
			return {
				content: [{ type: "text" as const, text: `Scrolled ${params.direction}.` }],
				details: {},
			};
		},
	});

	pi.registerTool({
		name: "zellij_subscribe",
		label: "Zellij Subscribe",
		description:
			"Stream real-time output from one or more panes. Returns content accumulated over the subscription duration.",
		parameters: Type.Object({
			pane_ids: Type.Array(Type.String(), {
				description: "Pane IDs to subscribe to (e.g. 'terminal_1')",
			}),
			session: Type.Optional(Type.String({ description: "Session name" })),
			scrollback: Type.Optional(
				Type.Number({
					description: "Include this many lines of scrollback in initial delivery (or all if -1)",
				}),
			),
			format: Type.Optional(
				StringEnum(["raw", "json"] as const, {
					description: "Output format: raw (default) or json (NDJSON)",
					default: "raw",
				}),
			),
			ansi: Type.Optional(
				Type.Boolean({ description: "Preserve ANSI styling escape sequences" }),
			),
			duration: Type.Optional(
				Type.Number({
					description: "Stream duration in seconds (default: 15, max: 120)",
					default: 15,
				}),
			),
		}),
		async execute(_, params) {
			const duration = Math.min(params.duration ?? 15, 120);
			const args = ["subscribe"];
			for (const pid of params.pane_ids) {
				args.push("--pane-id", pid);
			}
			if (params.scrollback === -1) args.push("--scrollback");
			else if (params.scrollback) args.push("--scrollback", String(params.scrollback));
			if (params.format) args.push("--format", params.format);
			if (params.ansi) args.push("--ansi");
			const output = await runZellij(pi, args, params.session, {
				timeout: (duration + 5) * 1000,
			});
			const maxLen = 100_000;
			const truncated =
				output.length > maxLen
					? output.slice(0, maxLen) + "\n... (truncated)"
					: output;
			return {
				content: [{ type: "text" as const, text: truncated || "No output from subscribed panes." }],
				details: { pane_ids: params.pane_ids, duration, format: params.format ?? "raw" },
			};
		},
	});

	pi.registerTool({
		name: "zellij_watch_session",
		label: "Zellij Watch",
		description:
			"Attach to a session in read-only mode (view-only, no input). Useful for monitoring long-running tasks.",
		parameters: Type.Object({
			session: Type.String({ description: "Session name to watch" }),
			duration: Type.Optional(
				Type.Number({
					description: "Watch duration in seconds (default: 30, max: 300)",
					default: 30,
				}),
			),
		}),
		async execute(_, params) {
			const duration = Math.min(params.duration ?? 30, 300);
			// Use a timeout slightly longer than requested to let pi see output
			const output = await runZellij(pi, ["watch", params.session!], undefined, {
				timeout: (duration + 5) * 1000,
			});
			const maxLen = 100_000;
			const truncated =
				output.length > maxLen
					? output.slice(0, maxLen) + "\n... (truncated)"
					: output;
			return {
				content: [{ type: "text" as const, text: truncated || "Session ended." }],
				details: { session: params.session, duration },
			};
		},
	});
}
