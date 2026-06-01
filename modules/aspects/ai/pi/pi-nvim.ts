import { createHash } from "node:crypto";
import { mkdirSync, readFileSync, readdirSync, readlinkSync, unlinkSync, writeFileSync, existsSync, statSync, symlinkSync } from "node:fs";
import { basename, join } from "node:path";
import * as net from "node:net";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

type DeliverAs = "steer" | "followUp";

type EditorSelection = {
	startLine: number;
	endLine: number;
	text?: string;
	truncated?: boolean;
};

type EditorState = {
	cwd?: string;
	file?: string;
	absFile?: string;
	filetype?: string;
	modified?: boolean;
	buftype?: string;
	cursor?: { line: number; col: number };
	selection?: EditorSelection | null;
	bufferText?: string;
	bufferTruncated?: boolean;
	updatedAt?: string;
};

type SocketMessage =
	| { type: "ping" }
	| { type: "editor_state"; state: EditorState }
	| { type: "prompt"; message: string; deliverAs?: DeliverAs };

const SOCKETS_DIR = "/tmp/pi-nvim-sockets";
const LATEST_LINK = "/tmp/pi-nvim-latest.sock";
const DEFAULT_DELIVER_AS: DeliverAs = "followUp";

function cwdHash(cwd: string): string {
	return createHash("md5").update(cwd).digest("hex").slice(0, 12);
}

function getSocketPath(cwd: string): string {
	return join(SOCKETS_DIR, `${cwdHash(cwd)}-${process.pid}.sock`);
}

function getDisplayName(state: EditorState): string {
	const target = state.file || state.absFile;
	if (target) return basename(target);
	if (state.buftype) return `[${state.buftype}]`;
	return "[no file]";
}

function formatEditorState(state: EditorState): string {
	const lines = ["[NEOVIM LIVE CONTEXT]"];
	lines.push(`Focused file: ${getDisplayName(state)}`);
	if (state.filetype) lines.push(`Filetype: ${state.filetype}`);
	if (state.cursor) lines.push(`Cursor: L${state.cursor.line}:C${state.cursor.col}`);
	if (state.selection) {
		lines.push(`Selection: lines ${state.selection.startLine}-${state.selection.endLine}`);
		if (state.selection.text) {
			lines.push("Selected text:");
			lines.push("```" + (state.filetype || ""));
			lines.push(state.selection.text);
			lines.push("```");
			if (state.selection.truncated) lines.push("(selection truncated)");
		}
	}
	if (state.bufferText) {
		lines.push("Current in-memory buffer contents:");
		lines.push("```" + (state.filetype || ""));
		lines.push(state.bufferText);
		lines.push("```");
		if (state.bufferTruncated) lines.push("(buffer snapshot truncated)");
	} else if (state.file || state.absFile) {
		lines.push(`Reference: @${state.file || state.absFile}`);
	}
	return lines.join("\n");
}

function formatStatus(state: EditorState | null): string {
	if (!state) return "nvim: --";
	const parts = [`nvim: ${getDisplayName(state)}`];
	if (state.selection) parts.push(`sel ${state.selection.startLine}-${state.selection.endLine}`);
	else if (state.cursor) parts.push(`L${state.cursor.line}`);
	return parts.join(" ");
}

function readJsonLines(socket: net.Socket, onLine: (line: string) => void) {
	let buffer = "";
	socket.on("data", (chunk) => {
		buffer += chunk.toString();
		let idx: number;
		while ((idx = buffer.indexOf("\n")) !== -1) {
			const line = buffer.slice(0, idx).trim();
			buffer = buffer.slice(idx + 1);
			if (line) onLine(line);
		}
	});
}

function cleanupSocket(socketPath: string | null) {
	if (!socketPath) return;
	try {
		unlinkSync(socketPath);
	} catch {}
	try {
		unlinkSync(`${socketPath}.info`);
	} catch {}
	try {
		if (readlinkSync(LATEST_LINK) === socketPath) unlinkSync(LATEST_LINK);
	} catch {}
}

export default function piNvim(pi: ExtensionAPI) {
	let server: net.Server | null = null;
	let socketPath: string | null = null;
	let latestEditorState: EditorState | null = null;
	let sessionCtx: any = null;

	function updateStatus() {
		if (!sessionCtx?.hasUI) return;
		const theme = sessionCtx.ui.theme;
		sessionCtx.ui.setStatus("pi-nvim", theme.fg("accent", formatStatus(latestEditorState)));
	}

	async function respond(conn: net.Socket, obj: any) {
		try {
			conn.write(JSON.stringify(obj) + "\n");
		} catch {}
	}

	async function handleMessage(raw: string, conn: net.Socket) {
		try {
			const msg = JSON.parse(raw) as SocketMessage;
			if (msg.type === "ping") {
				await respond(conn, { ok: true, type: "pong" });
				return;
			}
			if (msg.type === "editor_state") {
				latestEditorState = { ...msg.state, updatedAt: new Date().toISOString() };
				updateStatus();
				await respond(conn, { ok: true });
				return;
			}
			if (msg.type === "prompt") {
				await Promise.resolve(pi.sendUserMessage(msg.message, { deliverAs: msg.deliverAs ?? DEFAULT_DELIVER_AS }));
				await respond(conn, { ok: true });
				return;
			}
			await respond(conn, { ok: false, error: `Unknown command type: ${(msg as any).type}` });
		} catch (error: any) {
			await respond(conn, { ok: false, error: error?.message || String(error) });
		}
	}

	function cleanup() {
		if (server) {
			server.close();
			server = null;
		}
		cleanupSocket(socketPath);
		socketPath = null;
	}

	pi.on("session_start", async (_event, ctx) => {
		sessionCtx = ctx;
		latestEditorState = null;
		updateStatus();

		mkdirSync(SOCKETS_DIR, { recursive: true });
		cleanupSocket(socketPath);
		socketPath = getSocketPath(ctx.cwd);

		try {
			unlinkSync(socketPath);
		} catch {}

		server = net.createServer((conn) => {
			readJsonLines(conn, (line) => void handleMessage(line, conn));
			conn.on("error", () => {});
		});

		server.listen(socketPath, () => {
			try {
				unlinkSync(LATEST_LINK);
			} catch {}
			try {
				symlinkSync(socketPath!, LATEST_LINK);
			} catch {}
			try {
				writeFileSync(
					`${socketPath}.info`,
					JSON.stringify({ cwd: ctx.cwd, pid: process.pid, startedAt: new Date().toISOString() }),
				);
			} catch {}
			updateStatus();
		});

		server.on("error", (err) => {
			ctx.ui.notify(`pi-nvim error: ${err.message}`, "error");
		});
	});

	pi.on("before_agent_start", async () => {
		if (!latestEditorState) return;
		return {
			message: {
				customType: "pi-nvim-live-context",
				content: formatEditorState(latestEditorState),
				display: false,
				details: latestEditorState,
			},
		};
	});

	pi.on("session_shutdown", async () => {
		if (sessionCtx?.hasUI) sessionCtx.ui.setStatus("pi-nvim", undefined);
		sessionCtx = null;
		cleanup();
	});

	process.on("exit", cleanup);

	pi.registerCommand("pi-nvim-info", {
		description: "Show pi-nvim socket path",
		handler: async (_args, ctx) => {
			if (socketPath) {
				const file = latestEditorState ? getDisplayName(latestEditorState) : "--";
				ctx.ui.notify(`Socket: ${socketPath}\nFocused nvim target: ${file}`, "info");
			} else {
				ctx.ui.notify("pi-nvim not active", "warning");
			}
		},
	});
}
