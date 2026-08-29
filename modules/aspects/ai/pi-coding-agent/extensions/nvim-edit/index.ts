import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type, type Static } from "typebox";
import * as fs from "node:fs";
import * as net from "node:net";
import * as os from "node:os";
import * as path from "node:path";

const NvimEditParams = Type.Object({
	file: Type.String({ description: "File path to edit" }),
	line: Type.Number({ description: "Line number (1-indexed)" }),
	content: Type.String({ description: "Replacement/inserted content. Ignored for delete." }),
	changeType: Type.Union([Type.Literal("replace"), Type.Literal("insert"), Type.Literal("delete")], {
		description: "Type of line-oriented change",
	}),
	comment: Type.Optional(Type.String({ description: "Optional comment explaining the requested change" })),
});

type NvimEditInput = Static<typeof NvimEditParams>;

type ClientMessage =
	| { type: "response"; id: string; approved: boolean; comment?: string; editedContent?: string }
	| { type: "ping" };

type PendingRequest = {
	resolve: (value: ReturnType<typeof textResult>) => void;
	timeout: NodeJS.Timeout;
	signal?: AbortSignal;
	abortHandler?: () => void;
};

const MAX_MESSAGE_SIZE = 1024 * 1024;
const uid = typeof process.getuid === "function" ? process.getuid() : os.userInfo().username;
const SOCKET_DIR = path.join(os.tmpdir(), `pi-nvim-edit-${uid}-${process.pid}`);
const SOCKET_FILE = path.join(SOCKET_DIR, "socket");
const SESSION_FILE = path.join(SOCKET_DIR, "session.json");

let server: net.Server | null = null;
let currentClient: net.Socket | null = null;
let nextRequestId = 1;
const pending = new Map<string, PendingRequest>();
let activeNotify: ((message: string, level?: string) => void) | null = null;

function notify(message: string, level: string = "info") {
	if (!activeNotify) return;
	try {
		activeNotify(message, level);
	} catch {
		// Ignore stale ctx errors during session replacement/reload teardown.
	}
}

function textResult(text: string, details: Record<string, unknown> = {}) {
	return { content: [{ type: "text" as const, text }], details };
}

function fail(message: string, details: Record<string, unknown> = {}) {
	return textResult(`Error: ${message}`, details);
}

function cleanupPending(id: string) {
	const entry = pending.get(id);
	if (!entry) return;
	clearTimeout(entry.timeout);
	entry.signal?.removeEventListener?.("abort", entry.abortHandler!);
	pending.delete(id);
}

function handleClientLine(socket: net.Socket, line: string) {
	let message: ClientMessage;
	try {
		message = JSON.parse(line);
	} catch {
		return;
	}

	if (message.type === "ping") {
		socket.write(JSON.stringify({ type: "pong" }) + "\n");
		return;
	}

	if (message.type !== "response") return;
	const entry = pending.get(message.id);
	if (!entry) return;
	cleanupPending(message.id);
	entry.resolve(
		textResult(message.approved ? "Neovim approved edit." : "Neovim rejected edit.", {
			approved: message.approved,
			comment: message.comment,
			editedContent: message.editedContent,
		}),
	);
}

function attachClient(socket: net.Socket) {
	if (currentClient && currentClient !== socket) currentClient.destroy();
	currentClient = socket;
	notify("nvim-edit: Neovim client connected", "info");

	let buffer = "";
	socket.on("data", (data) => {
		buffer += data.toString("utf-8");
		if (Buffer.byteLength(buffer, "utf-8") > MAX_MESSAGE_SIZE) {
			socket.destroy(new Error("Message too large"));
			return;
		}
		let newline = buffer.indexOf("\n");
		while (newline >= 0) {
			const line = buffer.slice(0, newline).trim();
			buffer = buffer.slice(newline + 1);
			if (line) handleClientLine(socket, line);
			newline = buffer.indexOf("\n");
		}
	});

	socket.on("close", () => {
		if (currentClient === socket) currentClient = null;
		for (const id of pending.keys()) {
			const entry = pending.get(id);
			if (!entry) continue;
			cleanupPending(id);
			entry.resolve(fail("Neovim client disconnected", { id }));
		}
		notify("nvim-edit: Neovim client disconnected", "info");
	});

	socket.on("error", (err) => {
		if (currentClient === socket) currentClient = null;
		notify(`nvim-edit: Socket error: ${err.message}`, "error");
	});
}

export default function nvimEditExtension(pi: ExtensionAPI) {
	pi.registerTool({
		name: "nvim_edit",
		label: "Nvim Edit",
		description: "Send a line-oriented edit request to Neovim for review, approval, rejection, or manual adjustment.",
		parameters: NvimEditParams,

		async execute(_toolCallId, params, signal, _onUpdate, _ctx) {
			const input = params as NvimEditInput;
			if (!currentClient || currentClient.destroyed) {
				return fail(`No Neovim client connected. Start Neovim and load nvim-edit. Socket: ${SOCKET_FILE}`);
			}
			if (pending.size > 0) {
				return fail(`Cannot send new edit while ${pending.size} pending edit${pending.size === 1 ? " is" : "s are"} awaiting Neovim response`, {
					pending: pending.size,
				});
			}

			const id = String(nextRequestId++);
			const payload = JSON.stringify({ type: "edit", id, ...input }) + "\n";

			return await new Promise<ReturnType<typeof textResult>>((resolve) => {
				const timeout = setTimeout(() => {
					cleanupPending(id);
					resolve(fail("Timeout waiting for Neovim response", { id }));
				}, 5 * 60 * 1000);

				const abort = () => {
					cleanupPending(id);
					resolve(fail("nvim_edit cancelled", { id }));
				};

				pending.set(id, { resolve, timeout, signal, abortHandler: abort });
				signal?.addEventListener?.("abort", abort, { once: true });

				currentClient!.write(payload, (err) => {
					if (!err) return;
					cleanupPending(id);
					resolve(fail(`Failed to send edit request: ${err.message}`, { id }));
				});
			});
		},
	});

	pi.on("session_start", async (_event, ctx) => {
		activeNotify = (message, level = "info") => ctx.ui.notify(message, level as any);
		try {
			fs.mkdirSync(SOCKET_DIR, { recursive: true, mode: 0o700 });
			try {
				fs.unlinkSync(SOCKET_FILE);
			} catch {}

			fs.writeFileSync(
				SESSION_FILE,
				JSON.stringify({ pid: process.pid, cwd: process.cwd(), socket: SOCKET_FILE, startedAt: new Date().toISOString() }),
			);

			server = net.createServer((socket) => attachClient(socket));
			server.on("error", (err) => notify(`nvim-edit: Server error: ${err.message}`, "error"));
			server.listen(SOCKET_FILE, () => notify(`nvim-edit: Listening on ${SOCKET_FILE}`, "success"));
		} catch (err) {
			notify(`nvim-edit: Failed to start server: ${err}`, "error");
		}
	});

	pi.on("session_shutdown", async () => {
		activeNotify = null;
		for (const id of pending.keys()) cleanupPending(id);
		currentClient?.destroy();
		currentClient = null;
		server?.close();
		server = null;
		try {
			fs.unlinkSync(SOCKET_FILE);
		} catch {}
		try {
			fs.unlinkSync(SESSION_FILE);
		} catch {}
	});
}
