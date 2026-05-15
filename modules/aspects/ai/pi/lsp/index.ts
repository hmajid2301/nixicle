/**
 * LSP Extension for pi-coding-agent
 *
 * Provides an `lsp` tool for code intelligence via Language Server Protocol.
 * All modules inlined into a single file (pi loads extensions as single files).
 *
 * Actions: diagnostics, definition, references, hover, symbols, rename, code_actions, status
 * Config: ~/.pi/agent/lsp.json or project-local .pi/lsp.json
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { StringEnum } from "@mariozechner/pi-ai";
import { Text } from "@mariozechner/pi-tui";
import { type Static, Type } from "typebox";
import * as child_process from "node:child_process";
import * as fs from "node:fs";
import * as fsPromises from "node:fs/promises";
import * as path from "node:path";

// ═══════════════════════════════════════════════════════════════════════════════
// TYPES
// ═══════════════════════════════════════════════════════════════════════════════

const LspParams = Type.Object({
	action: StringEnum(
		[
			"diagnostics",
			"definition",
			"references",
			"hover",
			"symbols",
			"rename",
			"code_actions",
			"status",
		] as const,
		{ description: "LSP operation to perform" },
	),
	file: Type.Optional(Type.String({ description: "File path (relative or absolute)" })),
	line: Type.Optional(Type.Number({ description: "Line number (1-indexed)" })),
	symbol: Type.Optional(Type.String({ description: "Symbol/substring on the target line to resolve column" })),
	query: Type.Optional(Type.String({ description: "Search query or code-action filter" })),
	new_name: Type.Optional(Type.String({ description: "New name for rename" })),
	apply: Type.Optional(Type.Boolean({ description: "Apply edits (default: true for rename)" })),
	timeout: Type.Optional(Type.Number({ description: "Request timeout in seconds (default: 15)" })),
});

type LspParamsType = Static<typeof LspParams>;

interface Position { line: number; character: number; }
interface Range { start: Position; end: Position; }
interface Location { uri: string; range: Range; }
interface LocationLink { originSelectionRange?: Range; targetUri: string; targetRange: Range; targetSelectionRange: Range; }
type DiagnosticSeverity = 1 | 2 | 3 | 4;
interface Diagnostic {
	range: Range; severity?: DiagnosticSeverity; code?: string | number;
	source?: string; message: string;
	relatedInformation?: Array<{ location: Location; message: string }>;
}
interface TextEdit { range: Range; newText: string; }
interface DocumentSymbol { name: string; kind: number; range: Range; selectionRange: Range; children?: DocumentSymbol[]; }
interface SymbolInformation { name: string; kind: number; location: Location; containerName?: string; }
interface Hover { contents: unknown; range?: Range; }
interface CodeAction {
	title: string; kind?: string; edit?: WorkspaceEdit;
	command?: { title: string; command: string; arguments?: unknown[] }; diagnostics?: Diagnostic[];
}
interface WorkspaceEdit { changes?: Record<string, TextEdit[]>; documentChanges?: unknown[]; }

interface JsonRpcRequest { jsonrpc: "2.0"; id: number; method: string; params?: unknown; }
interface JsonRpcNotification { jsonrpc: "2.0"; method: string; params?: unknown; }
interface JsonRpcResponse { jsonrpc: "2.0"; id: number; result?: unknown; error?: { code: number; message: string; data?: unknown }; }

interface ServerConfig {
	command: string; args?: string[]; fileTypes: string[]; rootMarkers: string[];
	disabled?: boolean; settings?: Record<string, unknown>; initOptions?: Record<string, unknown>;
}
interface LspConfig { servers: Record<string, ServerConfig>; idleTimeoutMs?: number; }
interface PendingRequest { resolve: (result: unknown) => void; reject: (error: Error) => void; timer: ReturnType<typeof setTimeout>; }
interface LspClient {
	proc: child_process.ChildProcess; serverName: string; config: ServerConfig; cwd: string;
	initialized: boolean; pendingRequests: Map<number, PendingRequest>; diagnostics: Map<string, Diagnostic[]>;
	messageBuffer: Buffer; nextId: number; lastActivity: number; writeLock: Promise<void>;
}

// ═══════════════════════════════════════════════════════════════════════════════
// CONFIG
// ═══════════════════════════════════════════════════════════════════════════════

const commandAvailableCache = new Map<string, { available: boolean; checkedAt: number }>();
const COMMAND_CACHE_TTL = 60_000;

const DEFAULTS: Record<string, Partial<ServerConfig>> = {
	nixd: { command: "nixd", args: [], fileTypes: [".nix"], rootMarkers: ["flake.nix", "default.nix", "shell.nix"] },
	"typescript-language-server": {
		command: "typescript-language-server", args: ["--stdio"],
		fileTypes: [".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs"],
		rootMarkers: ["tsconfig.json", "package.json", "jsconfig.json"],
	},
	pyright: {
		command: "pyright-langserver", args: ["--stdio"],
		fileTypes: [".py", ".pyi"], rootMarkers: ["pyproject.toml", "pyrightconfig.json", "setup.py", "requirements.txt"],
		settings: { python: { analysis: { autoSearchPaths: true, diagnosticMode: "openFilesOnly", useLibraryCodeForTypes: true } } },
	},
	"rust-analyzer": { command: "rust-analyzer", args: [], fileTypes: [".rs"], rootMarkers: ["Cargo.toml"] },
	gopls: {
		command: "gopls", args: ["serve"], fileTypes: [".go"], rootMarkers: ["go.mod"],
		settings: { gopls: { analyses: { unusedparams: true, shadow: true }, staticcheck: true } },
	},
	clangd: {
		command: "clangd", args: ["--background-index"],
		fileTypes: [".c", ".cpp", ".cc", ".cxx", ".h", ".hpp"],
		rootMarkers: ["compile_commands.json", "CMakeLists.txt", "Makefile"],
	},
	bashls: { command: "bash-language-server", args: ["start"], fileTypes: [".sh", ".bash"], rootMarkers: [".git"] },
	lua: {
		command: "lua-language-server", args: [], fileTypes: [".lua"], rootMarkers: [".luarc.json"],
		settings: { Lua: { runtime: { version: "LuaJIT" }, diagnostics: { globals: ["vim"] }, workspace: { checkThirdParty: false } } },
	},
	marksman: { command: "marksman", args: ["server"], fileTypes: [".md", ".markdown"], rootMarkers: [".marksman.toml", ".git"] },
	yamlls: {
		command: "yaml-language-server", args: ["--stdio"], fileTypes: [".yaml", ".yml"], rootMarkers: [".git"],
		settings: { yaml: { validate: true, hover: true, completion: true } },
	},
};

function normalizeServer(name: string, partial: Partial<ServerConfig>): ServerConfig | null {
	const command = partial.command ?? "";
	if (!command || !partial.fileTypes?.length || !partial.rootMarkers?.length) return null;
	return {
		command, args: partial.args ?? [], fileTypes: partial.fileTypes, rootMarkers: partial.rootMarkers,
		disabled: partial.disabled ?? false, settings: partial.settings, initOptions: partial.initOptions,
	};
}

function readConfigFile(filePath: string): Record<string, Partial<ServerConfig>> | null {
	try {
		const parsed = JSON.parse(fs.readFileSync(filePath, "utf-8"));
		if (parsed && typeof parsed === "object") return parsed.servers ?? parsed;
	} catch {}
	return null;
}

function hasRootMarkers(cwd: string, markers: string[]): boolean {
	return markers.some((m) => fs.existsSync(path.join(cwd, m)));
}

function isCommandAvailable(command: string): boolean {
	const now = Date.now();
	const cached = commandAvailableCache.get(command);
	if (cached && now - cached.checkedAt < COMMAND_CACHE_TTL) return cached.available;
	let available = false;
	try {
		const which = process.platform === "win32" ? "where" : "which";
		available = execSync(`${which} ${command}`, { stdio: "pipe" }).toString().trim().length > 0;
	} catch {}
	commandAvailableCache.set(command, { available, checkedAt: now });
	return available;
}

const { execSync } = child_process;

function loadConfig(cwd: string): LspConfig {
	const servers: Record<string, ServerConfig> = {};
	for (const [name, partial] of Object.entries(DEFAULTS)) {
		const normalized = normalizeServer(name, partial);
		if (normalized) servers[name] = normalized;
	}
	const configPaths = [
		path.join(cwd, ".pi", "lsp.json"),
		path.join(cwd, "lsp.json"),
		path.join(process.env.HOME ?? "~", ".pi", "agent", "lsp.json"),
	];
	for (const configPath of configPaths) {
		const overrides = readConfigFile(configPath);
		if (!overrides) continue;
		for (const [name, partial] of Object.entries(overrides)) {
			if (partial.disabled) { delete servers[name]; continue; }
			const normalized = normalizeServer(name, { ...servers[name], ...partial });
			if (normalized) servers[name] = normalized;
		}
	}
	return { servers };
}

function getServersForFile(config: LspConfig, filePath: string, cwd: string): Array<{ name: string; config: ServerConfig }> {
	const ext = path.extname(filePath).toLowerCase();
	const matches: Array<{ name: string; config: ServerConfig }> = [];
	for (const [name, sc] of Object.entries(config.servers)) {
		if (sc.disabled || !sc.fileTypes.includes(ext) || !hasRootMarkers(cwd, sc.rootMarkers) || !isCommandAvailable(sc.command)) continue;
		matches.push({ name, config: sc });
	}
	return matches;
}

function getAllAvailableServers(config: LspConfig, cwd: string): Array<{ name: string; config: ServerConfig }> {
	const available: Array<{ name: string; config: ServerConfig }> = [];
	for (const [name, sc] of Object.entries(config.servers)) {
		if (sc.disabled || !hasRootMarkers(cwd, sc.rootMarkers) || !isCommandAvailable(sc.command)) continue;
		available.push({ name, config: sc });
	}
	return available;
}

// ═══════════════════════════════════════════════════════════════════════════════
// CLIENT
// ═══════════════════════════════════════════════════════════════════════════════

const clients = new Map<string, LspClient>();

function encodeMessage(msg: JsonRpcRequest | JsonRpcNotification | JsonRpcResponse): Buffer {
	const content = JSON.stringify(msg);
	const header = `Content-Length: ${Buffer.byteLength(content, "utf-8")}\r\n\r\n`;
	return Buffer.concat([Buffer.from(header, "utf-8"), Buffer.from(content, "utf-8")]);
}

function parseMessage(buffer: Buffer): { message: JsonRpcResponse; remaining: Buffer } | null {
	for (let i = 0; i < buffer.length - 3; i++) {
		if (buffer[i] === 0x0d && buffer[i + 1] === 0x0a && buffer[i + 2] === 0x0d && buffer[i + 3] === 0x0a) {
			const headerText = buffer.slice(0, i).toString("utf-8");
			const match = headerText.match(/Content-Length:\s*(\d+)/i);
			if (!match) return null;
			const contentLength = parseInt(match[1], 10);
			const messageStart = i + 4;
			const messageEnd = messageStart + contentLength;
			if (buffer.length < messageEnd) return null;
			return { message: JSON.parse(buffer.slice(messageStart, messageEnd).toString("utf-8")), remaining: buffer.slice(messageEnd) };
		}
	}
	return null;
}

async function writeMessage(client: LspClient, msg: JsonRpcRequest | JsonRpcNotification | JsonRpcResponse): Promise<void> {
	const data = encodeMessage(msg);
	const write = client.writeLock.catch(() => {}).then(() => new Promise<void>((resolve, reject) => {
		if (!client.proc.stdin) { reject(new Error("stdin not available")); return; }
		client.proc.stdin.write(data, (err) => { if (err) reject(err); else resolve(); });
	}));
	client.writeLock = write.catch(() => {});
	return write;
}

function routeMessage(client: LspClient, message: JsonRpcResponse): void {
	if ("id" in message && message.id !== undefined && !("method" in message)) {
		const pending = client.pendingRequests.get(message.id);
		if (pending) {
			client.pendingRequests.delete(message.id);
			clearTimeout(pending.timer);
			if (message.error) pending.reject(new Error(`LSP error: ${message.error.message}`));
			else pending.resolve(message.result);
		}
	} else if ("method" in message) {
		handleNotification(client, message as JsonRpcNotification & { id?: number; result?: unknown });
	}
}

function handleNotification(client: LspClient, message: JsonRpcNotification & { id?: number; result?: unknown; error?: unknown }): void {
	if (message.method === "textDocument/publishDiagnostics" && message.params) {
		const params = message.params as { uri: string; diagnostics: unknown[] };
		client.diagnostics.set(params.uri, params.diagnostics as Diagnostic[]);
	} else if (message.method === "window/logMessage" && message.params) {
		if (process.env.PI_LSP_DEBUG) {
			const params = message.params as { type: number; message: string };
			console.error(`[lsp:${client.serverName}] ${params.message}`);
		}
	} else if (message.method === "workspace/configuration" && typeof message.id === "number") {
		const params = message.params as { items?: Array<{ section?: string }> };
		const result = (params?.items ?? []).map((item) => client.config.settings?.[item.section ?? ""] ?? null);
		writeMessage(client, { jsonrpc: "2.0", id: message.id, result });
	}
}

function startMessageReader(client: LspClient): void {
	if (!client.proc.stdout) return;
	let buffer = Buffer.alloc(0);
	client.proc.stdout.on("data", (chunk: Buffer) => {
		buffer = Buffer.concat([buffer, chunk]);
		let parsed = parseMessage(buffer);
		while (parsed) { routeMessage(client, parsed.message); buffer = parsed.remaining; parsed = parseMessage(buffer); }
	});
	client.proc.stderr?.on("data", (chunk: Buffer) => {
		const text = chunk.toString("utf-8").trim();
		if (text && process.env.PI_LSP_DEBUG) console.error(`[lsp:${client.serverName}] stderr: ${text.slice(0, 200)}`);
	});
	client.proc.on("exit", (code) => {
		for (const [, pending] of client.pendingRequests) { pending.reject(new Error(`LSP server exited with code ${code}`)); clearTimeout(pending.timer); }
		client.pendingRequests.clear();
		clients.delete(client.serverName);
	});
}

const CLIENT_CAPABILITIES = {
	textDocument: {
		synchronization: { didSave: true, dynamicRegistration: false },
		hover: { contentFormat: ["markdown", "plaintext"], dynamicRegistration: false },
		definition: { linkSupport: true, dynamicRegistration: false },
		references: { dynamicRegistration: false },
		documentSymbol: { hierarchicalDocumentSymbolSupport: true, dynamicRegistration: false },
		rename: { prepareSupport: true, dynamicRegistration: false },
		codeAction: {
			dynamicRegistration: false,
			codeActionLiteralSupport: { codeActionKind: { valueSet: ["quickfix", "refactor", "refactor.extract", "refactor.inline", "refactor.rewrite", "source", "source.organizeImports"] } },
		},
		publishDiagnostics: { relatedInformation: true, tagSupport: { valueSet: [1, 2] } },
	},
	workspace: { applyEdit: true, workspaceEdit: { documentChanges: true }, configuration: true, symbol: { dynamicRegistration: false } },
};

async function getOrCreateClient(serverName: string, config: ServerConfig, cwd: string, timeoutMs = 15_000): Promise<LspClient> {
	const existing = clients.get(serverName);
	if (existing && existing.initialized) { existing.lastActivity = Date.now(); return existing; }
	if (existing) {
		return new Promise((resolve, reject) => {
			const check = setInterval(() => { const c = clients.get(serverName); if (c?.initialized) { clearInterval(check); resolve(c); } }, 100);
			setTimeout(() => { clearInterval(check); reject(new Error(`Timeout waiting for ${serverName} to initialize`)); }, timeoutMs);
		});
	}
	const proc = child_process.spawn(config.command, config.args ?? [], { cwd, stdio: ["pipe", "pipe", "pipe"], env: { ...process.env } });
	const client: LspClient = {
		proc, serverName, config, cwd, initialized: false, pendingRequests: new Map(), diagnostics: new Map(),
		messageBuffer: Buffer.alloc(0), nextId: 1, lastActivity: Date.now(), writeLock: Promise.resolve(),
	};
	clients.set(serverName, client);
	startMessageReader(client);
	await sendRequest(client, "initialize", {
		processId: process.pid, rootUri: fileToUri(cwd), capabilities: CLIENT_CAPABILITIES, initializationOptions: config.initOptions ?? {},
	}, timeoutMs);
	client.initialized = true;
	await writeMessage(client, { jsonrpc: "2.0", method: "initialized", params: {} });
	return client;
}

function sendRequest(client: LspClient, method: string, params: unknown, timeoutMs = 15_000): Promise<unknown> {
	return new Promise((resolve, reject) => {
		const id = client.nextId++;
		const timer = setTimeout(() => { client.pendingRequests.delete(id); reject(new Error(`LSP request timeout: ${method} (${timeoutMs}ms)`)); }, timeoutMs);
		client.pendingRequests.set(id, { resolve, reject, timer });
		writeMessage(client, { jsonrpc: "2.0", id, method, params }).catch(reject);
	});
}

async function sendNotification(client: LspClient, method: string, params: unknown): Promise<void> {
	await writeMessage(client, { jsonrpc: "2.0", method, params });
}

async function ensureFileOpen(client: LspClient, filePath: string): Promise<void> {
	await sendNotification(client, "textDocument/didOpen", {
		textDocument: { uri: fileToUri(filePath), languageId: detectLanguageId(filePath), version: 0, text: await readFileContent(filePath) },
	});
}

async function notifySaved(client: LspClient, filePath: string): Promise<void> {
	await sendNotification(client, "textDocument/didSave", { textDocument: { uri: fileToUri(filePath) } });
}

async function shutdownClient(serverName: string): Promise<void> {
	const client = clients.get(serverName);
	if (!client) return;
	try { await sendRequest(client, "shutdown", undefined, 3000); } catch {}
	try { await sendNotification(client, "exit", undefined); } catch {}
	client.proc.kill();
	clients.delete(serverName);
}

async function shutdownAll(): Promise<void> {
	await Promise.allSettled([...clients.keys()].map(name => shutdownClient(name)));
}

function getActiveClients(): Map<string, LspClient> { return clients; }

function fileToUri(filePath: string): string {
	const resolved = path.resolve(filePath);
	return process.platform === "win32" ? `file:///${resolved.replace(/\\/g, "/")}` : `file://${resolved}`;
}

function uriToFile(uri: string): string {
	if (!uri.startsWith("file://")) return uri;
	let filePath = decodeURIComponent(uri.slice(7));
	if (process.platform === "win32" && filePath.startsWith("/") && /^[A-Za-z]:/.test(filePath.slice(1))) filePath = filePath.slice(1);
	return filePath;
}

function detectLanguageId(filePath: string): string {
	const ext = path.extname(filePath).toLowerCase();
	const map: Record<string, string> = {
		".ts": "typescript", ".tsx": "typescriptreact", ".js": "javascript", ".jsx": "javascriptreact",
		".py": "python", ".rs": "rust", ".go": "go", ".nix": "nix", ".json": "json",
		".yaml": "yaml", ".yml": "yaml", ".md": "markdown", ".html": "html", ".css": "css",
		".sh": "shellscript", ".bash": "shellscript", ".c": "c", ".cpp": "cpp",
		".h": "c", ".hpp": "cpp", ".java": "java", ".rb": "ruby", ".lua": "lua",
	};
	return map[ext] ?? "plaintext";
}

async function readFileContent(filePath: string): Promise<string> {
	try { return await fsPromises.readFile(filePath, "utf-8"); } catch { return ""; }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EDITS
// ═══════════════════════════════════════════════════════════════════════════════

function applyTextEditsToString(content: string, edits: TextEdit[]): string {
	const lines = content.split("\n");
	const sorted = [...edits].sort((a, b) => {
		if (a.range.start.line !== b.range.start.line) return b.range.start.line - a.range.start.line;
		return b.range.start.character - a.range.start.character;
	});
	for (const edit of sorted) {
		const { start, end } = edit.range;
		if (start.line === end.line) {
			const line = lines[start.line] ?? "";
			lines[start.line] = line.slice(0, start.character) + edit.newText + line.slice(end.character);
		} else {
			const startLine = lines[start.line] ?? "";
			const endLine = lines[end.line] ?? "";
			const newContent = startLine.slice(0, start.character) + edit.newText + endLine.slice(end.character);
			lines.splice(start.line, end.line - start.line + 1, ...newContent.split("\n"));
		}
	}
	return lines.join("\n");
}

async function applyTextEdits(filePath: string, edits: TextEdit[]): Promise<void> {
	const content = await fsPromises.readFile(filePath, "utf-8");
	await fsPromises.writeFile(filePath, applyTextEditsToString(content, edits), "utf-8");
}

async function applyWorkspaceEdit(edit: WorkspaceEdit, cwd: string): Promise<string[]> {
	const applied: string[] = [];
	if (edit.documentChanges) {
		for (const change of edit.documentChanges) {
			if (!change || typeof change !== "object") continue;
			if ("edits" in change && "textDocument" in change) {
				const tde = change as { textDocument: { uri: string }; edits: TextEdit[] };
				const fp = uriToFile(tde.textDocument.uri);
				await applyTextEdits(fp, tde.edits);
				applied.push(`Applied ${tde.edits.length} edit(s) to ${path.relative(cwd, fp)}`);
			} else if ("kind" in change && (change as any).kind === "create") {
				const cf = change as { uri: string; options?: { overwrite?: boolean } };
				try { await fsPromises.writeFile(uriToFile(cf.uri), "", { flag: cf.options?.overwrite ? "w" : "wx" }); } catch {}
				applied.push(`Created ${path.relative(cwd, uriToFile(cf.uri))}`);
			} else if ("kind" in change && (change as any).kind === "rename") {
				const rf = change as { oldUri: string; newUri: string };
				try { await fsPromises.rename(uriToFile(rf.oldUri), uriToFile(rf.newUri)); } catch {}
				applied.push(`Renamed ${path.relative(cwd, uriToFile(rf.oldUri))} → ${path.relative(cwd, uriToFile(rf.newUri))}`);
			} else if ("kind" in change && (change as any).kind === "delete") {
				const df = change as { uri: string };
				try { await fsPromises.unlink(uriToFile(df.uri)); } catch {}
				applied.push(`Deleted ${path.relative(cwd, uriToFile(df.uri))}`);
			}
		}
	} else if (edit.changes) {
		for (const [uri, textEdits] of Object.entries(edit.changes)) {
			const fp = uriToFile(uri);
			await applyTextEdits(fp, textEdits);
			applied.push(`Applied ${textEdits.length} edit(s) to ${path.relative(cwd, fp)}`);
		}
	}
	return applied;
}

// ═══════════════════════════════════════════════════════════════════════════════
// FORMAT
// ═══════════════════════════════════════════════════════════════════════════════

const SEVERITY_ICONS: Record<number, string> = { 1: "✖", 2: "⚠", 3: "ℹ", 4: "💡" };
const SEVERITY_NAMES: Record<number, string> = { 1: "error", 2: "warning", 3: "info", 4: "hint" };
const SYMBOL_KIND_ICONS: Record<number, string> = {
	1: "📁", 2: "📦", 3: "🗂️", 4: "📌", 5: "🔧", 6: "⚙️", 7: "🏗️", 8: "🔢", 9: "🔤",
	10: "🏠", 11: "🎲", 12: "📐", 13: "📐", 14: "⚡", 15: "⚡", 16: "⚡", 17: "⚡",
	18: "⚡", 19: "⚡", 20: "⚡", 21: "⚡", 22: "⚡", 23: "📌", 24: "📋", 25: "📋", 26: "🌐",
};

function formatDiagnostics(diagnostics: Diagnostic[], filePath: string): string {
	if (diagnostics.length === 0) return `No diagnostics for ${filePath}`;
	const lines: string[] = [];
	const sorted = [...diagnostics].sort((a, b) => {
		const sd = (a.severity ?? 1) - (b.severity ?? 1); if (sd !== 0) return sd;
		return a.range.start.line - b.range.start.line;
	});
	for (const d of sorted) {
		const icon = SEVERITY_ICONS[d.severity ?? 1] ?? "•";
		const sev = SEVERITY_NAMES[d.severity ?? 1] ?? "unknown";
		const line = d.range.start.line + 1;
		const col = d.range.start.character + 1;
		const source = d.source ? ` [${d.source}]` : "";
		const code = d.code ? ` (${d.code})` : "";
		lines.push(`${icon} ${line}:${col} ${sev}${source}${code}: ${d.message}`);
		if (d.relatedInformation) {
			for (const rel of d.relatedInformation) {
				lines.push(`  → ${uriToFile(rel.location.uri)}:${rel.location.range.start.line + 1}: ${rel.message}`);
			}
		}
	}
	return lines.join("\n");
}

function formatLocation(loc: Location, cwd: string, contextLines = 3): string {
	const filePath = uriToFile(loc.uri);
	const relPath = path.relative(cwd, filePath);
	const startLine = loc.range.start.line;
	const endLine = loc.range.end.line;
	let result = `${relPath}:${startLine + 1}:${loc.range.start.character + 1}`;
	try {
		const content = fs.readFileSync(filePath, "utf-8");
		const fileLines = content.split("\n");
		const ctxStart = Math.max(0, startLine - contextLines);
		const ctxEnd = Math.min(fileLines.length, endLine + contextLines + 1);
		result += "\n";
		for (let i = ctxStart; i < ctxEnd; i++) {
			const marker = (i >= startLine && i <= endLine) ? "→" : " ";
			result += `  ${marker} ${String(i + 1).padStart(4)} | ${fileLines[i]}\n`;
		}
	} catch {}
	return result;
}

function formatHover(hover: Hover): string {
	if (!hover.contents) return "No hover info available.";
	let text = "";
	if (typeof hover.contents === "string") text = hover.contents;
	else if (Array.isArray(hover.contents)) text = hover.contents.map((c: any) => typeof c === "string" ? c : c.value ?? "").join("\n\n");
	else if (typeof hover.contents === "object" && "kind" in (hover.contents as any)) text = (hover.contents as { value: string }).value;
	else if (typeof hover.contents === "object" && "value" in (hover.contents as any)) text = (hover.contents as { value: string }).value;
	return text || "No hover info available.";
}

function formatSymbols(symbols: (DocumentSymbol | SymbolInformation)[], cwd: string): string {
	if (symbols.length === 0) return "No symbols found.";
	const lines: string[] = [];
	function formatDocSymbol(sym: DocumentSymbol, indent = 0): void {
		const icon = SYMBOL_KIND_ICONS[sym.kind] ?? "•";
		lines.push(`${"  ".repeat(indent)}${icon} ${sym.name} (line ${sym.range.start.line + 1})`);
		if (sym.children) for (const child of sym.children) formatDocSymbol(child, indent + 1);
	}
	for (const sym of symbols) {
		if ("children" in sym) { formatDocSymbol(sym as DocumentSymbol); }
		else {
			const info = sym as SymbolInformation;
			const icon = SYMBOL_KIND_ICONS[info.kind] ?? "•";
			const relPath = path.relative(cwd, uriToFile(info.location.uri));
			const container = info.containerName ? ` in ${info.containerName}` : "";
			lines.push(`${icon} ${info.name}${container} — ${relPath}:${info.location.range.start.line + 1}`);
		}
	}
	return lines.join("\n");
}

function formatCodeActions(actions: CodeAction[]): string {
	if (actions.length === 0) return "No code actions available.";
	return actions.map((a, i) => `${i + 1}. ${a.title}${a.kind ? ` [${a.kind}]` : ""}${a.edit ? " ✓ has edits" : ""}`).join("\n");
}

// ═══════════════════════════════════════════════════════════════════════════════
// EXTENSION ENTRY
// ═══════════════════════════════════════════════════════════════════════════════

const DEFAULT_TIMEOUT_MS = 15_000;

export default function lspExtension(pi: ExtensionAPI) {
	let sessionCwd = process.cwd();
	let currentCtx: any = null;

	pi.registerTool({
		name: "lsp",
		label: "LSP",
		description: `Interact with Language Server Protocol servers for code intelligence.

Actions:
- diagnostics: Get errors/warnings for a file
- definition: Go to definition of a symbol
- references: Find all references to a symbol
- hover: Get type info and documentation
- symbols: List symbols in a file
- rename: Rename a symbol across the codebase
- code_actions: Get available quick-fixes and refactors
- status: Show active LSP servers

Requires a running language server for the target language. Servers auto-start on first use.
Config: ~/.pi/agent/lsp.json for server overrides.`,

		parameters: LspParams,

		async execute(_toolCallId, params, signal, _onUpdate, ctx) {
			currentCtx = ctx;
			const cwd = ctx.cwd ?? sessionCwd;
			const config = loadConfig(cwd);
			const timeoutMs = (params.timeout ?? 15) * 1000 || DEFAULT_TIMEOUT_MS;

			try {
				switch (params.action) {
					case "status": return handleStatus(config, cwd);
					case "diagnostics": return await handleDiagnostics(params, config, cwd, timeoutMs);
					case "definition": return await handleDefinition(params, config, cwd, timeoutMs);
					case "references": return await handleReferences(params, config, cwd, timeoutMs);
					case "hover": return await handleHover(params, config, cwd, timeoutMs);
					case "symbols": return await handleSymbols(params, config, cwd, timeoutMs);
					case "rename": return await handleRename(params, config, cwd, timeoutMs);
					case "code_actions": return await handleCodeActions(params, config, cwd, timeoutMs);
					default: return errorResult(`Unknown action: ${params.action}`);
				}
			} catch (err: any) {
				return errorResult(`LSP error: ${err.message}`);
			}
		},

		renderCall(args: any, theme: any) {
			const action = args.action ?? "status";
			const file = args.file ? path.basename(args.file) : "";
			const line = args.line ? `:${args.line}` : "";
			let text = theme.fg("toolTitle", theme.bold("lsp ")) + theme.fg("accent", action);
			if (file) text += " " + theme.fg("dim", `${file}${line}`);
			return new Text(text, 0, 0);
		},

		renderResult(result: any, { isPartial }: { isPartial: boolean }, theme: any) {
			if (isPartial) return new Text(theme.fg("warning", "LSP request pending..."), 0, 0);
			const text = result.content?.[0]?.text ?? "";
			if (text.startsWith("Error:")) return new Text(theme.fg("error", text), 0, 0);
			const firstLine = text.split("\n")[0] ?? "";
			if (firstLine.includes("diagnostic")) {
				const count = (text.match(/✖|⚠/g) || []).length;
				return new Text(theme.fg(count > 0 ? "warning" : "success", count > 0 ? `${count} diagnostic(s)` : "✓ No diagnostics"), 0, 0);
			}
			if (firstLine.includes("No ") && firstLine.includes("found")) return new Text(theme.fg("dim", firstLine), 0, 0);
			const preview = text.length > 80 ? text.slice(0, 77) + "..." : text;
			return new Text(theme.fg("muted", preview), 0, 0);
		},
	});

	// ── Diagnostics Widget ──────────────────────────────────────────────────

	let lastDiagFile: string | undefined;
	let diagTimer: ReturnType<typeof setInterval> | null = null;

	function refreshDiagWidget(ctx: any, config: LspConfig, cwd: string) {
		if (!lastDiagFile) { ctx.ui.setWidget("lsp-diagnostics", undefined); return; }
		const servers = getServersForFile(config, lastDiagFile, cwd);
		if (servers.length === 0) { ctx.ui.setWidget("lsp-diagnostics", undefined); return; }
		const client = getActiveClients().get(servers[0].name);
		if (!client) { ctx.ui.setWidget("lsp-diagnostics", undefined); return; }
		const uri = fileToUri(lastDiagFile);
		const diags = client.diagnostics.get(uri) ?? [];
		const th = ctx.ui.theme;
		if (diags.length === 0) {
			ctx.ui.setWidget("lsp-diagnostics", [th.fg("success", "✓ No diagnostics") + " " + th.fg("dim", path.relative(cwd, lastDiagFile))]);
			return;
		}
		const errors = diags.filter(d => (d.severity ?? 1) <= 1).length;
		const warnings = diags.filter(d => d.severity === 2).length;
		const lines = [th.fg("warning", `⚠ ${errors}e ${warnings}w`) + " " + th.fg("dim", path.relative(cwd, lastDiagFile))];
		for (const d of diags.slice(0, 5)) {
			const icon = (d.severity ?? 1) <= 1 ? th.fg("error", "✖") : d.severity === 2 ? th.fg("warning", "⚠") : th.fg("dim", "ℹ");
			const line = d.range.start.line + 1;
			const msg = d.message.length > 80 ? d.message.slice(0, 77) + "…" : d.message;
			lines.push(`  ${icon} ${th.fg("dim", `L${line}`)} ${msg}`);
		}
		if (diags.length > 5) lines.push(th.fg("dim", `  … +${diags.length - 5} more`));
		ctx.ui.setWidget("lsp-diagnostics", lines);
	}

	pi.on("tool_execution_start", async (event: any) => {
		if (event.toolName !== "lsp") return;
		const args = event.input;
		if (args?.file) {
			lastDiagFile = resolvePath(args.file, process.cwd());
			if (!diagTimer) {
				diagTimer = setInterval(() => { try { refreshDiagWidget(currentCtx, loadConfig(process.cwd()), process.cwd()); } catch {} }, 3000);
				if (diagTimer.unref) diagTimer.unref();
			}
		}
	});

	pi.on("session_shutdown", async () => {
		if (diagTimer) { clearInterval(diagTimer); diagTimer = null; }
		await shutdownAll();
	});

	// ── Action Handlers ────────────────────────────────────────────────────

	function handleStatus(config: LspConfig, cwd: string) {
		const available = getAllAvailableServers(config, cwd);
		const active = getActiveClients();
		const lines: string[] = [];
		if (available.length === 0) {
			lines.push("No LSP servers detected for this project.");
			lines.push("Install language servers and ensure project markers exist (e.g. flake.nix for nixd).");
		} else {
			lines.push("Available servers:");
			for (const s of available) {
				const isActive = active.has(s.name);
				lines.push(`  ${isActive ? "● active" : "○ available"} ${s.name} (${s.config.fileTypes.join(", ")})`);
			}
		}
		if (active.size > 0) {
			lines.push("");
			lines.push("Active clients:");
			for (const [name, client] of active) lines.push(`  ${name}: ${client.initialized ? "initialized" : "connecting..."}`);
		}
		return textResult(lines.join("\n"));
	}

	async function handleDiagnostics(params: LspParamsType, config: LspConfig, cwd: string, timeoutMs: number) {
		if (!params.file) return errorResult("file is required for diagnostics");
		const filePath = resolvePath(params.file, cwd);
		const servers = getServersForFile(config, filePath, cwd);
		if (servers.length === 0) return errorResult(`No LSP server found for ${params.file}`);
		const allDiagnostics: Diagnostic[] = [];
		for (const server of servers) {
			const client = await getOrCreateClient(server.name, server.config, cwd, timeoutMs);
			await ensureFileOpen(client, filePath);
			await new Promise((r) => setTimeout(r, 500));
			const diags = client.diagnostics.get(fileToUri(filePath)) ?? [];
			allDiagnostics.push(...diags);
		}
		return textResult(formatDiagnostics(allDiagnostics, path.relative(cwd, filePath)));
	}

	async function handleDefinition(params: LspParamsType, config: LspConfig, cwd: string, timeoutMs: number) {
		if (!params.file || !params.line) return errorResult("file and line are required for definition");
		const { client, filePath, position } = await resolvePosition(params, config, cwd, timeoutMs);
		const result = await sendRequest(client, "textDocument/definition", { textDocument: { uri: fileToUri(filePath) }, position }, timeoutMs);
		if (!result) return textResult("No definition found.");
		const locations = Array.isArray(result) ? result : [result];
		const formatted = locations.map((loc: any) => {
			if (loc.targetUri) return formatLocation({ uri: loc.targetUri, range: loc.targetSelectionRange ?? loc.targetRange }, cwd);
			return formatLocation(loc as Location, cwd);
		}).join("\n\n");
		return textResult(formatted || "No definition found.");
	}

	async function handleReferences(params: LspParamsType, config: LspConfig, cwd: string, timeoutMs: number) {
		if (!params.file || !params.line) return errorResult("file and line are required for references");
		const { client, filePath, position } = await resolvePosition(params, config, cwd, timeoutMs);
		const result = await sendRequest(client, "textDocument/references", { textDocument: { uri: fileToUri(filePath) }, position, context: { includeDeclaration: true } }, timeoutMs);
		if (!result || !Array.isArray(result) || result.length === 0) return textResult("No references found.");
		const formatted = (result as Location[]).slice(0, 50).map((loc) => formatLocation(loc, cwd)).join("\n\n");
		const extra = result.length > 50 ? `\n\n... and ${result.length - 50} more` : "";
		return textResult(formatted + extra);
	}

	async function handleHover(params: LspParamsType, config: LspConfig, cwd: string, timeoutMs: number) {
		if (!params.file || !params.line) return errorResult("file and line are required for hover");
		const { client, filePath, position } = await resolvePosition(params, config, cwd, timeoutMs);
		const result = await sendRequest(client, "textDocument/hover", { textDocument: { uri: fileToUri(filePath) }, position }, timeoutMs);
		if (!result) return textResult("No hover info available.");
		return textResult(formatHover(result as Hover));
	}

	async function handleSymbols(params: LspParamsType, config: LspConfig, cwd: string, timeoutMs: number) {
		if (!params.file) return errorResult("file is required for symbols");
		const filePath = resolvePath(params.file, cwd);
		const servers = getServersForFile(config, filePath, cwd);
		if (servers.length === 0) return errorResult(`No LSP server found for ${params.file}`);
		const client = await getOrCreateClient(servers[0].name, servers[0].config, cwd, timeoutMs);
		await ensureFileOpen(client, filePath);
		const result = await sendRequest(client, "textDocument/documentSymbol", { textDocument: { uri: fileToUri(filePath) } }, timeoutMs);
		if (!result || !Array.isArray(result) || result.length === 0) return textResult("No symbols found.");
		return textResult(formatSymbols(result as (DocumentSymbol | SymbolInformation)[], cwd));
	}

	async function handleRename(params: LspParamsType, config: LspConfig, cwd: string, timeoutMs: number) {
		if (!params.file || !params.line || !params.new_name) return errorResult("file, line, and new_name are required for rename");
		const { client, filePath, position } = await resolvePosition(params, config, cwd, timeoutMs);
		const result = await sendRequest(client, "textDocument/rename", { textDocument: { uri: fileToUri(filePath) }, position, newName: params.new_name }, timeoutMs);
		if (!result) return textResult("Rename not available at this position.");
		const edit = result as WorkspaceEdit;
		if (params.apply !== false && (edit.changes || edit.documentChanges)) {
			const applied = await applyWorkspaceEdit(edit, cwd);
			return textResult(`Renamed to "${params.new_name}"\n${applied.join("\n")}`);
		}
		const lines: string[] = [`Preview: rename to "${params.new_name}"`];
		if (edit.changes) {
			for (const [uri, edits] of Object.entries(edit.changes)) {
				lines.push(`  ${path.relative(cwd, uriToFile(uri))}: ${(edits as TextEdit[]).length} change(s)`);
			}
		}
		return textResult(lines.join("\n"));
	}

	async function handleCodeActions(params: LspParamsType, config: LspConfig, cwd: string, timeoutMs: number) {
		if (!params.file || !params.line) return errorResult("file and line are required for code_actions");
		const { client, filePath, position } = await resolvePosition(params, config, cwd, timeoutMs);
		const result = await sendRequest(client, "textDocument/codeAction", {
			textDocument: { uri: fileToUri(filePath) }, range: { start: position, end: position },
			context: { diagnostics: [], only: params.query ? [params.query] : undefined },
		}, timeoutMs);
		if (!result || !Array.isArray(result) || result.length === 0) return textResult("No code actions available at this position.");
		const actions = result as CodeAction[];
		if (params.apply !== false && params.query) {
			const idx = parseInt(params.query) - 1;
			const matched = actions[idx] ?? actions.find((a) => a.title.includes(params.query!));
			if (matched?.edit) {
				const applied = await applyWorkspaceEdit(matched.edit, cwd);
				return textResult(`Applied: ${matched.title}\n${applied.join("\n")}`);
			}
		}
		return textResult(formatCodeActions(actions));
	}

	// ── Helpers ────────────────────────────────────────────────────────────

	async function resolvePosition(params: LspParamsType, config: LspConfig, cwd: string, timeoutMs: number) {
		const filePath = resolvePath(params.file!, cwd);
		const servers = getServersForFile(config, filePath, cwd);
		if (servers.length === 0) throw new Error(`No LSP server found for ${params.file}`);
		const client = await getOrCreateClient(servers[0].name, servers[0].config, cwd, timeoutMs);
		await ensureFileOpen(client, filePath);
		const line = (params.line ?? 1) - 1;
		let character = 0;
		if (params.symbol && line >= 0) character = resolveSymbolColumn(filePath, line, params.symbol);
		return { client, filePath, position: { line, character } };
	}

	function resolveSymbolColumn(filePath: string, line: number, symbol: string): number {
		try {
			const lineText = fs.readFileSync(filePath, "utf-8").split("\n")[line];
			if (lineText) { const idx = lineText.indexOf(symbol); if (idx >= 0) return idx; }
		} catch {}
		return 0;
	}

	function resolvePath(file: string, cwd: string): string {
		return path.isAbsolute(file) ? file : path.resolve(cwd, file);
	}

	function textResult(text: string) {
		return { content: [{ type: "text" as const, text }], details: {} };
	}

	function errorResult(message: string) {
		return { content: [{ type: "text" as const, text: `Error: ${message}` }], details: {} };
	}
}
