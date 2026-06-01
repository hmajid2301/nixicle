/**
 * Debug Extension for pi-coding-agent
 *
 * Provides a `debug` tool backed by DAP.
 * Single-file extension so pi can load it directly.
 *
 * Actions:
 * - launch / attach
 * - set_breakpoint / remove_breakpoint
 * - set_instruction_breakpoint / remove_instruction_breakpoint
 * - data_breakpoint_info / set_data_breakpoint / remove_data_breakpoint
 * - continue / pause / step_over / step_in / step_out
 * - threads / stack_trace / scopes / variables / evaluate
 * - disassemble / read_memory / write_memory
 * - modules / loaded_sources / custom_request
 * - output / terminate / sessions
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { StringEnum } from "@mariozechner/pi-ai";
import { Text } from "@mariozechner/pi-tui";
import { type Static, Type } from "typebox";
import * as child_process from "node:child_process";
import * as fs from "node:fs";
import * as net from "node:net";
import * as path from "node:path";

const DebugParams = Type.Object({
	action: StringEnum(
		[
			"launch",
			"attach",
			"set_breakpoint",
			"remove_breakpoint",
			"set_instruction_breakpoint",
			"remove_instruction_breakpoint",
			"data_breakpoint_info",
			"set_data_breakpoint",
			"remove_data_breakpoint",
			"continue",
			"pause",
			"step_over",
			"step_in",
			"step_out",
			"threads",
			"stack_trace",
			"scopes",
			"variables",
			"evaluate",
			"disassemble",
			"read_memory",
			"write_memory",
			"modules",
			"loaded_sources",
			"custom_request",
			"output",
			"terminate",
			"sessions",
		] as const,
		{ description: "DAP operation to perform" },
	),
	program: Type.Optional(Type.String({ description: "Launch target path. Required for launch." })),
	args: Type.Optional(Type.Array(Type.String(), { description: "Program argv for launch" })),
	adapter: Type.Optional(Type.String({ description: "Explicit adapter name" })),
	cwd: Type.Optional(Type.String({ description: "Working directory for launch/attach" })),
	file: Type.Optional(Type.String({ description: "Source file path for breakpoints" })),
	line: Type.Optional(Type.Number({ description: "1-indexed source line for breakpoints" })),
	function: Type.Optional(Type.String({ description: "Function name for function breakpoints" })),
	condition: Type.Optional(Type.String({ description: "Breakpoint condition" })),
	hit_condition: Type.Optional(Type.String({ description: "Breakpoint hit condition" })),
	name: Type.Optional(Type.String({ description: "Target name for data_breakpoint_info" })),
	expression: Type.Optional(Type.String({ description: "Expression for evaluate" })),
	context: Type.Optional(Type.String({ description: "Evaluate context (default: repl)" })),
	pid: Type.Optional(Type.Number({ description: "Local process id for attach" })),
	port: Type.Optional(Type.Number({ description: "Remote attach port" })),
	host: Type.Optional(Type.String({ description: "Remote attach host" })),
	levels: Type.Optional(Type.Number({ description: "Stack frame count for stack_trace" })),
	thread_id: Type.Optional(Type.Number({ description: "Thread id for stack_trace/continue/pause/step_*" })),
	frame_id: Type.Optional(Type.Number({ description: "Frame id for scopes/evaluate/data_breakpoint_info" })),
	scope_id: Type.Optional(Type.Number({ description: "Scope or variables reference for variables/data_breakpoint_info" })),
	variable_ref: Type.Optional(Type.Number({ description: "variablesReference for variables" })),
	instruction_reference: Type.Optional(Type.String({ description: "Instruction reference for instruction breakpoints / disassemble" })),
	memory_reference: Type.Optional(Type.String({ description: "Memory reference for disassemble / read_memory / write_memory" })),
	instruction_count: Type.Optional(Type.Number({ description: "Instruction count for disassemble" })),
	instruction_offset: Type.Optional(Type.Number({ description: "Instruction offset for disassemble" })),
	offset: Type.Optional(Type.Number({ description: "Offset for instruction breakpoints / memory ops" })),
	count: Type.Optional(Type.Number({ description: "Byte count for read_memory" })),
	data: Type.Optional(Type.String({ description: "Base64 payload for write_memory" })),
	data_id: Type.Optional(Type.String({ description: "Data breakpoint id" })),
	access_type: Type.Optional(StringEnum(["read", "write", "readWrite"] as const, { description: "Access type for data breakpoints" })),
	allow_partial: Type.Optional(Type.Boolean({ description: "Allow partial writes for write_memory" })),
	resolve_symbols: Type.Optional(Type.Boolean({ description: "Resolve symbols during disassemble" })),
	start_module: Type.Optional(Type.Number({ description: "Start module index for modules" })),
	module_count: Type.Optional(Type.Number({ description: "Module count for modules" })),
	command: Type.Optional(Type.String({ description: "Custom DAP request command" })),
	arguments: Type.Optional(Type.Any({ description: "Custom DAP request arguments" })),
	timeout: Type.Optional(Type.Number({ description: "Request timeout in seconds (default: 30)" })),
});

type DebugParamsType = Static<typeof DebugParams>;

type ConnectMode = "stdio" | "tcp-listen";

interface AdapterConfig {
	command: string;
	args?: string[];
	connectMode?: ConnectMode;
	fileTypes: string[];
	rootMarkers: string[];
	launchDefaults?: Record<string, unknown>;
	attachDefaults?: Record<string, unknown>;
	disabled?: boolean;
}

interface DebugConfig {
	adapters: Record<string, AdapterConfig>;
}

interface PendingRequest {
	resolve: (value: unknown) => void;
	reject: (err: Error) => void;
	timer: ReturnType<typeof setTimeout>;
}

interface SourceBreakpoint {
	line: number;
	condition?: string;
}

interface FunctionBreakpoint {
	name: string;
	condition?: string;
}

interface InstructionBreakpoint {
	instructionReference: string;
	offset?: number;
	condition?: string;
	hitCondition?: string;
}

interface DataBreakpoint {
	dataId: string;
	accessType?: "read" | "write" | "readWrite";
	condition?: string;
	hitCondition?: string;
}

interface DebugSession {
	id: string;
	adapterName: string;
	adapterConfig: AdapterConfig;
	cwd: string;
	proc: child_process.ChildProcess;
	socket?: net.Socket;
	stdin?: NodeJS.WritableStream;
	stdout?: NodeJS.ReadableStream;
	seq: number;
	pending: Map<number, PendingRequest>;
	eventWaiters: Map<string, Array<(event: DapEvent) => void>>;
	capabilities: Record<string, unknown>;
	initialized: boolean;
	configurationDoneSent: boolean;
	breakpoints: Map<string, SourceBreakpoint[]>;
	functionBreakpoints: FunctionBreakpoint[];
	instructionBreakpoints: InstructionBreakpoint[];
	dataBreakpoints: DataBreakpoint[];
	currentThreadId?: number;
	currentFrameId?: number;
	currentFrames: any[];
	output: string;
	lastStopReason?: string;
	terminated: boolean;
	writeLock: Promise<void>;
}

interface DapRequest {
	seq: number;
	type: "request";
	command: string;
	arguments?: unknown;
}

interface DapResponse {
	seq: number;
	type: "response";
	request_seq: number;
	success: boolean;
	command: string;
	message?: string;
	body?: any;
}

interface DapEvent {
	seq: number;
	type: "event";
	event: string;
	body?: any;
}

interface DapReverseRequest {
	seq: number;
	type: "request";
	command: string;
	arguments?: any;
}

const DEFAULT_TIMEOUT_MS = 30_000;
const OUTPUT_LIMIT = 128 * 1024;
const EVENT_TIMEOUT_MS = 5_000;

const DEFAULTS: Record<string, AdapterConfig> = {
	dlv: {
		command: "dlv",
		args: ["dap"],
		connectMode: "tcp-listen",
		fileTypes: [".go"],
		rootMarkers: ["go.mod", "go.sum", "go.work"],
		launchDefaults: { request: "launch", mode: "debug", stopOnEntry: true },
		attachDefaults: { request: "attach", mode: "local" },
	},
	debugpy: {
		command: "python",
		args: ["-m", "debugpy.adapter"],
		connectMode: "stdio",
		fileTypes: [".py"],
		rootMarkers: ["pyproject.toml", "setup.py", "requirements.txt"],
		launchDefaults: { request: "launch", justMyCode: false, stopOnEntry: true },
		attachDefaults: { request: "attach", justMyCode: false },
	},
	"lldb-dap": {
		command: "lldb-dap",
		args: [],
		connectMode: "stdio",
		fileTypes: [".c", ".cc", ".cpp", ".cxx", ".m", ".mm", ".rs", ".swift", ".zig"],
		rootMarkers: ["Cargo.toml", "CMakeLists.txt", "Makefile", "Package.swift", "build.zig"],
		launchDefaults: { request: "launch", stopOnEntry: true },
		attachDefaults: { request: "attach" },
	},
	gdb: {
		command: "gdb",
		args: ["-i", "dap"],
		connectMode: "stdio",
		fileTypes: [".c", ".cc", ".cpp", ".cxx", ".h", ".hpp", ".rs"],
		rootMarkers: ["Cargo.toml", "CMakeLists.txt", "Makefile", "compile_commands.json"],
		launchDefaults: { request: "launch", stopOnEntry: true },
		attachDefaults: { request: "attach" },
	},
	codelldb: {
		command: "codelldb",
		args: ["--port", "0"],
		connectMode: "tcp-listen",
		fileTypes: [".rs", ".c", ".cc", ".cpp", ".cxx", ".zig"],
		rootMarkers: ["Cargo.toml", "CMakeLists.txt", "Makefile", "build.zig"],
		launchDefaults: { request: "launch", stopOnEntry: true },
		attachDefaults: { request: "attach" },
	},
};

const commandAvailableCache = new Map<string, { available: boolean; checkedAt: number }>();
const COMMAND_CACHE_TTL = 60_000;
let activeSession: DebugSession | null = null;

function loadConfig(cwd: string): DebugConfig {
	const adapters: Record<string, AdapterConfig> = JSON.parse(JSON.stringify(DEFAULTS));
	const configPaths = [
		path.join(cwd, ".pi", "debug.json"),
		path.join(cwd, "debug.json"),
		path.join(process.env.HOME ?? "~", ".pi", "agent", "debug.json"),
	];
	for (const configPath of configPaths) {
		try {
			const parsed = JSON.parse(fs.readFileSync(configPath, "utf-8"));
			const overrides = parsed.adapters ?? parsed;
			for (const [name, value] of Object.entries(overrides)) {
				if (!value || typeof value !== "object") continue;
				if ((value as any).disabled) {
					delete adapters[name];
					continue;
				}
				adapters[name] = { ...(adapters[name] ?? {}), ...(value as Partial<AdapterConfig>) } as AdapterConfig;
			}
		} catch {}
	}
	return { adapters };
}

function isCommandAvailable(command: string): boolean {
	const now = Date.now();
	const cached = commandAvailableCache.get(command);
	if (cached && now - cached.checkedAt < COMMAND_CACHE_TTL) return cached.available;
	let available = false;
	try {
		const which = process.platform === "win32" ? "where" : "which";
		available = child_process.execSync(`${which} ${command}`, { stdio: "pipe" }).toString().trim().length > 0;
	} catch {}
	commandAvailableCache.set(command, { available, checkedAt: now });
	return available;
}

function hasRootMarkers(dir: string, markers: string[]): boolean {
	return markers.some((marker) => {
		if (marker.includes("*")) return false;
		return fs.existsSync(path.join(dir, marker));
	});
}

function findProjectRoot(startDir: string, markers: string[]): string {
	let dir = path.resolve(startDir);
	while (true) {
		if (hasRootMarkers(dir, markers)) return dir;
		const parent = path.dirname(dir);
		if (parent === dir) return path.resolve(startDir);
		dir = parent;
	}
}

function getAdapterForTarget(config: DebugConfig, params: DebugParamsType, sessionCwd: string): { name: string; config: AdapterConfig; root: string } | null {
	if (params.adapter) {
		const adapter = config.adapters[params.adapter];
		if (!adapter || !isCommandAvailable(adapter.command)) return null;
		const root = findProjectRoot(resolveWorkingDir(params, sessionCwd), adapter.rootMarkers ?? []);
		return { name: params.adapter, config: adapter, root };
	}

	const probePath = params.program ?? params.file;
	const ext = probePath ? path.extname(probePath).toLowerCase() : "";
	const cwd = resolveWorkingDir(params, sessionCwd);

	for (const [name, adapter] of Object.entries(config.adapters)) {
		if (adapter.disabled || !isCommandAvailable(adapter.command)) continue;
		if (ext && !adapter.fileTypes.includes(ext)) continue;
		const root = findProjectRoot(cwd, adapter.rootMarkers ?? []);
		if (!hasRootMarkers(root, adapter.rootMarkers ?? [])) continue;
		return { name, config: adapter, root };
	}

	if (!ext) {
		for (const [name, adapter] of Object.entries(config.adapters)) {
			if (adapter.disabled || !isCommandAvailable(adapter.command)) continue;
			const root = findProjectRoot(cwd, adapter.rootMarkers ?? []);
			if (!hasRootMarkers(root, adapter.rootMarkers ?? [])) continue;
			return { name, config: adapter, root };
		}
	}

	return null;
}

function resolveWorkingDir(params: DebugParamsType, sessionCwd: string): string {
	return path.resolve(params.cwd ? path.resolve(sessionCwd, params.cwd) : sessionCwd);
}

function encodeMessage(msg: DapRequest | DapResponse | DapEvent): Buffer {
	const content = JSON.stringify(msg);
	const header = `Content-Length: ${Buffer.byteLength(content, "utf-8")}\r\n\r\n`;
	return Buffer.concat([Buffer.from(header, "utf-8"), Buffer.from(content, "utf-8")]);
}

function parseMessage(buffer: Buffer): { message: DapResponse | DapEvent | DapReverseRequest; remaining: Buffer } | null {
	// O(n) per call: scans until the first header terminator, then returns immediately.
	for (let i = 0; i < buffer.length - 3; i++) {
		if (buffer[i] === 0x0d && buffer[i + 1] === 0x0a && buffer[i + 2] === 0x0d && buffer[i + 3] === 0x0a) {
			const headerText = buffer.slice(0, i).toString("utf-8");
			const match = headerText.match(/Content-Length:\s*(\d+)/i);
			if (!match) return null;
			const contentLength = parseInt(match[1], 10);
			const messageStart = i + 4;
			const messageEnd = messageStart + contentLength;
			if (buffer.length < messageEnd) return null;
			return {
				message: JSON.parse(buffer.slice(messageStart, messageEnd).toString("utf-8")),
				remaining: buffer.slice(messageEnd),
			};
		}
	}
	return null;
}

async function writeMessage(session: DebugSession, msg: DapRequest | DapResponse | DapEvent): Promise<void> {
	const data = encodeMessage(msg);
	const target = session.socket ?? session.stdin;
	if (!target) throw new Error("DAP transport not ready");
	const write = session.writeLock.catch(() => {}).then(() => new Promise<void>((resolve, reject) => {
		(target as any).write(data, (err: Error | null | undefined) => {
			if (err) reject(err);
			else resolve();
		});
	}));
	session.writeLock = write.catch(() => {});
	return write;
}

function appendOutput(session: DebugSession, text: string): void {
	if (!text) return;
	session.output += text;
	if (Buffer.byteLength(session.output, "utf-8") > OUTPUT_LIMIT) {
		session.output = Buffer.from(session.output, "utf-8").slice(-OUTPUT_LIMIT).toString("utf-8");
	}
}

function setupMessageReader(session: DebugSession): void {
	const stream = session.stdout ?? session.socket;
	if (!stream) return;
	let buffer = Buffer.alloc(0);
	stream.on("data", (chunk: Buffer | string) => {
		buffer = Buffer.concat([buffer, Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk)]);
		let parsed = parseMessage(buffer);
		while (parsed) {
			routeMessage(session, parsed.message);
			buffer = parsed.remaining;
			parsed = parseMessage(buffer);
		}
	});

	session.proc.stderr?.on("data", (chunk: Buffer) => {
		appendOutput(session, chunk.toString("utf-8"));
	});

	session.proc.on("exit", (code) => {
		session.terminated = true;
		for (const [, pending] of session.pending) {
			clearTimeout(pending.timer);
			pending.reject(new Error(`DAP adapter exited with code ${code}`));
		}
		session.pending.clear();
		if (activeSession?.id === session.id) activeSession = null;
	});
}

function routeMessage(session: DebugSession, message: DapResponse | DapEvent | DapReverseRequest): void {
	if (message.type === "response") {
		const pending = session.pending.get(message.request_seq);
		if (!pending) return;
		session.pending.delete(message.request_seq);
		clearTimeout(pending.timer);
		if (!message.success) pending.reject(new Error(message.message || `${message.command} failed`));
		else pending.resolve(message.body);
		return;
	}

	if (message.type === "request") {
		void handleReverseRequest(session, message);
		return;
	}

	handleEvent(session, message);
}

function resolveEventWaiters(session: DebugSession, event: DapEvent): void {
	const waiters = session.eventWaiters.get(event.event) ?? [];
	session.eventWaiters.delete(event.event);
	for (const waiter of waiters) waiter(event);
}

function handleEvent(session: DebugSession, event: DapEvent): void {
	if (event.event === "initialized") {
		session.initialized = true;
	} else if (event.event === "output") {
		appendOutput(session, event.body?.output ?? "");
	} else if (event.event === "stopped") {
		session.currentThreadId = event.body?.threadId;
		session.lastStopReason = event.body?.reason;
	} else if (event.event === "continued") {
		session.currentFrameId = undefined;
		session.currentFrames = [];
	} else if (event.event === "terminated" || event.event === "exited") {
		session.terminated = true;
	}
	resolveEventWaiters(session, event);
}

interface EventWaiterRegistration {
	eventName: string;
	waiter: (event: DapEvent) => void;
	cleanup: () => void;
	promise: Promise<DapEvent>;
}

function registerEventWaiter(session: DebugSession, eventName: string, timeoutMs = EVENT_TIMEOUT_MS): EventWaiterRegistration {
	let done = false;
	let timer: ReturnType<typeof setTimeout>;
	let waiter: (event: DapEvent) => void = () => {};
	const cleanup = () => {
		if (done) return;
		done = true;
		clearTimeout(timer);
		const waiters = session.eventWaiters.get(eventName);
		if (!waiters) return;
		const next = waiters.filter((entry) => entry !== waiter);
		if (next.length === 0) session.eventWaiters.delete(eventName);
		else session.eventWaiters.set(eventName, next);
	};
	const promise = new Promise<DapEvent>((resolve, reject) => {
		timer = setTimeout(() => {
			cleanup();
			reject(new Error(`DAP event timed out: ${eventName}`));
		}, timeoutMs);
		waiter = (event: DapEvent) => {
			if (done) return;
			done = true;
			clearTimeout(timer);
			resolve(event);
		};
		const waiters = session.eventWaiters.get(eventName) ?? [];
		waiters.push(waiter);
		session.eventWaiters.set(eventName, waiters);
	});
	return { eventName, waiter, cleanup, promise };
}

function waitForEvent(session: DebugSession, eventName: string, timeoutMs = EVENT_TIMEOUT_MS): Promise<DapEvent> {
	return registerEventWaiter(session, eventName, timeoutMs).promise;
}

function sendRequest(session: DebugSession, command: string, args?: unknown, timeoutMs = DEFAULT_TIMEOUT_MS): Promise<any> {
	return new Promise((resolve, reject) => {
		const seq = session.seq++;
		const timer = setTimeout(() => {
			session.pending.delete(seq);
			reject(new Error(`DAP request timed out after ${timeoutMs}ms: ${command}`));
		}, timeoutMs);
		session.pending.set(seq, { resolve, reject, timer });
		writeMessage(session, { seq, type: "request", command, arguments: args }).catch((err) => {
			session.pending.delete(seq);
			clearTimeout(timer);
			reject(err instanceof Error ? err : new Error(String(err)));
		});
	});
}

async function handleReverseRequest(session: DebugSession, request: DapReverseRequest): Promise<void> {
	if (request.command === "runInTerminal") {
		const args = request.arguments ?? {};
		const argv = Array.isArray(args.args) ? args.args.map((value: unknown) => String(value)) : [];
		const cwd = typeof args.cwd === "string" ? args.cwd : session.cwd;
		const env = args.env && typeof args.env === "object" ? { ...process.env, ...args.env } : process.env;
		let processId: number | undefined;
		try {
			if (argv.length > 0) {
				const child = child_process.spawn(argv[0], argv.slice(1), {
					cwd,
					env,
					stdio: "ignore",
					detached: true,
				});
				child.unref();
				processId = child.pid;
			}
			await writeMessage(session, {
				seq: session.seq++,
				type: "response",
				request_seq: request.seq,
				success: true,
				command: request.command,
				body: processId ? { processId } : {},
			});
		} catch (err: any) {
			await writeMessage(session, {
				seq: session.seq++,
				type: "response",
				request_seq: request.seq,
				success: false,
				command: request.command,
				message: err?.message ?? "runInTerminal failed",
			});
		}
		return;
	}

	if (request.command === "startDebugging") {
		await writeMessage(session, {
			seq: session.seq++,
			type: "response",
			request_seq: request.seq,
			success: true,
			command: request.command,
			body: { success: false },
		});
		return;
	}

	await writeMessage(session, {
		seq: session.seq++,
		type: "response",
		request_seq: request.seq,
		success: false,
		command: request.command,
		message: `Unsupported reverse request: ${request.command}`,
	});
}

async function connectTcpAdapter(session: DebugSession, adapter: AdapterConfig, cwd: string): Promise<{ socket: net.Socket; proc: child_process.ChildProcess }> {
	if (adapter.command === "dlv") {
		const host = "127.0.0.1";
		const port = await getFreePort();
		const proc = child_process.spawn(adapter.command, [...(adapter.args ?? []), `--listen=${host}:${port}`], {
			cwd,
			env: process.env,
			stdio: ["ignore", "pipe", "pipe"],
		});
		const socket = await waitForSocket(host, port, proc, 10_000);
		return { socket, proc };
	}

	if (adapter.command === "codelldb") {
		const proc = child_process.spawn(adapter.command, adapter.args ?? [], {
			cwd,
			env: process.env,
			stdio: ["ignore", "pipe", "pipe"],
		});
		const port = await parsePortFromOutput(proc, 10_000);
		const socket = await waitForSocket("127.0.0.1", port, proc, 10_000);
		return { socket, proc };
	}

	throw new Error(`Unsupported tcp-listen adapter: ${adapter.command}`);
}

function waitForSocket(host: string, port: number, proc: child_process.ChildProcess, timeoutMs: number): Promise<net.Socket> {
	return new Promise((resolve, reject) => {
		const start = Date.now();
		let settled = false;
		const finishResolve = (socket: net.Socket) => {
			if (settled) return;
			settled = true;
			proc.off("error", onProcError);
			resolve(socket);
		};
		const finishReject = (err: Error) => {
			if (settled) return;
			settled = true;
			proc.off("error", onProcError);
			reject(err);
		};
		const onProcError = (err: Error) => finishReject(new Error(`Adapter failed to start: ${err.message}`));
		proc.once("error", onProcError);
		const attempt = () => {
			const socket = net.createConnection({ host, port });
			socket.once("connect", () => finishResolve(socket));
			socket.once("error", (err) => {
				socket.destroy();
				if (proc.exitCode !== null) {
					finishReject(new Error(`DAP adapter exited before socket connect (${proc.exitCode})`));
					return;
				}
				if (Date.now() - start > timeoutMs) {
					finishReject(err instanceof Error ? err : new Error(String(err)));
					return;
				}
				setTimeout(attempt, 150);
			});
		};
		attempt();
	});
}

function parsePortFromOutput(proc: child_process.ChildProcess, timeoutMs: number): Promise<number> {
	return new Promise((resolve, reject) => {
		let stderr = "";
		let stdout = "";
		let settled = false;
		const finishReject = (err: Error) => {
			if (settled) return;
			settled = true;
			clearTimeout(timer);
			reject(err);
		};
		const finishResolve = (port: number) => {
			if (settled) return;
			settled = true;
			clearTimeout(timer);
			resolve(port);
		};
		const timer = setTimeout(() => finishReject(new Error("Timed out waiting for adapter port")), timeoutMs);
		const parse = (text: string) => {
			const match = text.match(/(?::|on\s)port\s*(\d+)/i) || text.match(/127\.0\.0\.1:(\d+)/);
			if (!match) return;
			finishResolve(parseInt(match[1], 10));
		};
		proc.stdout?.on("data", (chunk: Buffer) => {
			stdout += chunk.toString("utf-8");
			parse(stdout);
		});
		proc.stderr?.on("data", (chunk: Buffer) => {
			stderr += chunk.toString("utf-8");
			parse(stderr);
		});
		proc.once("error", (err) => finishReject(new Error(`Adapter failed to start: ${err.message}`)));
		proc.once("exit", (code) => finishReject(new Error(`Adapter exited before exposing port (${code})`)));
	});
}

function getFreePort(): Promise<number> {
	return new Promise((resolve, reject) => {
		const server = net.createServer();
		server.listen(0, "127.0.0.1", () => {
			const addr = server.address();
			if (!addr || typeof addr === "string") {
				server.close();
				reject(new Error("Failed to allocate TCP port"));
				return;
			}
			const port = addr.port;
			server.close((err) => err ? reject(err) : resolve(port));
		});
		server.on("error", reject);
	});
}

async function createSession(adapterName: string, adapter: AdapterConfig, cwd: string): Promise<DebugSession> {
	let proc: child_process.ChildProcess;
	let socket: net.Socket | undefined;
	let stdin: NodeJS.WritableStream | undefined;
	let stdout: NodeJS.ReadableStream | undefined;

	if ((adapter.connectMode ?? "stdio") === "tcp-listen") {
		const connected = await connectTcpAdapter({} as DebugSession, adapter, cwd);
		proc = connected.proc;
		socket = connected.socket;
	} else {
		proc = child_process.spawn(adapter.command, adapter.args ?? [], {
			cwd,
			env: process.env,
			stdio: ["pipe", "pipe", "pipe"],
		});
		stdin = proc.stdin ?? undefined;
		stdout = proc.stdout ?? undefined;
	}

	const session: DebugSession = {
		id: `${adapterName}-${Date.now()}`,
		adapterName,
		adapterConfig: adapter,
		cwd,
		proc,
		socket,
		stdin,
		stdout,
		seq: 1,
		pending: new Map(),
		eventWaiters: new Map(),
		capabilities: {},
		initialized: false,
		configurationDoneSent: false,
		breakpoints: new Map(),
		functionBreakpoints: [],
		instructionBreakpoints: [],
		dataBreakpoints: [],
		currentFrames: [],
		output: "",
		terminated: false,
		writeLock: Promise.resolve(),
	};

	setupMessageReader(session);
	const onProcError = (err: Error) => {
		const startupError = new Error(`DAP adapter failed to start (${adapterName}): ${err.message}`);
		for (const [, pending] of session.pending) {
			clearTimeout(pending.timer);
			pending.reject(startupError);
		}
		session.pending.clear();
	};
	proc.once("error", onProcError);
	try {
		const initBody = await sendRequest(session, "initialize", {
			clientID: "pi",
			clientName: "pi",
			adapterID: adapterName,
			pathFormat: "path",
			linesStartAt1: true,
			columnsStartAt1: true,
			supportsVariableType: true,
			supportsVariablePaging: true,
			supportsRunInTerminalRequest: true,
		}, DEFAULT_TIMEOUT_MS);
		if (initBody && typeof initBody === "object") session.capabilities = initBody;
		try { await waitForEvent(session, "initialized", 2_000); } catch {}
		return session;
	} finally {
		proc.off("error", onProcError);
	}
}

async function ensureConfigurationDone(session: DebugSession, timeoutMs: number): Promise<void> {
	if (session.configurationDoneSent) return;
	const supports = Boolean((session.capabilities as any)?.supportsConfigurationDoneRequest);
	if (supports) await sendRequest(session, "configurationDone", {}, timeoutMs);
	session.configurationDoneSent = true;
}

async function launchSession(params: DebugParamsType, config: DebugConfig, sessionCwd: string, timeoutMs: number) {
	if (!params.program) throw new Error("program is required for launch");
	if (activeSession && !activeSession.terminated) throw new Error("Debug session is still active. Terminate it before launching another.");

	const selected = getAdapterForTarget(config, params, sessionCwd);
	if (!selected) throw new Error(`No debugger adapter available for ${params.program}`);
	const cwd = resolveWorkingDir(params, selected.root);
	const session = await createSession(selected.name, selected.config, cwd);
	const program = path.isAbsolute(params.program) ? params.program : path.resolve(cwd, params.program);
	const request = {
		...(selected.config.launchDefaults ?? {}),
		name: `pi:${path.basename(program)}`,
		program,
		cwd,
		args: params.args ?? [],
	};
	await sendRequest(session, "launch", request, timeoutMs);
	await ensureConfigurationDone(session, timeoutMs);
	activeSession = session;
	return textResult(
		[
			`Launched ${path.relative(cwd, program) || program}`,
			`adapter: ${selected.name}`,
			`cwd: ${cwd}`,
		].join("\n"),
		{ action: "launch", adapter: selected.name, session: summarizeSession(session) },
	);
}

async function attachSession(params: DebugParamsType, config: DebugConfig, sessionCwd: string, timeoutMs: number) {
	if (params.pid === undefined && params.port === undefined) throw new Error("attach requires pid or port");
	if (params.pid !== undefined && (!Number.isInteger(params.pid) || params.pid <= 0)) throw new Error("pid must be a positive integer");
	if (activeSession && !activeSession.terminated) throw new Error("Debug session is still active. Terminate it before launching another.");

	const selected = getAdapterForTarget(config, params, sessionCwd) ?? defaultAttachAdapter(config, params, sessionCwd);
	if (!selected) throw new Error("No debugger adapter available for attach");
	const cwd = resolveWorkingDir(params, selected.root);
	const session = await createSession(selected.name, selected.config, cwd);
	const request = {
		...(selected.config.attachDefaults ?? {}),
		cwd,
		processId: params.pid,
		pid: params.pid,
		host: params.host ?? "127.0.0.1",
		port: params.port,
	};
	await sendRequest(session, "attach", request, timeoutMs);
	await ensureConfigurationDone(session, timeoutMs);
	activeSession = session;
	return textResult(
		[
			`Attached with ${selected.name}`,
			params.pid !== undefined ? `pid: ${params.pid}` : `port: ${params.host ?? "127.0.0.1"}:${params.port}`,
			`cwd: ${cwd}`,
		].join("\n"),
		{ action: "attach", adapter: selected.name, session: summarizeSession(session) },
	);
}

function defaultAttachAdapter(config: DebugConfig, params: DebugParamsType, sessionCwd: string): { name: string; config: AdapterConfig; root: string } | null {
	if (params.port !== undefined && config.adapters.debugpy && isCommandAvailable(config.adapters.debugpy.command)) {
		const root = findProjectRoot(resolveWorkingDir(params, sessionCwd), config.adapters.debugpy.rootMarkers);
		return { name: "debugpy", config: config.adapters.debugpy, root };
	}
	for (const [name, adapter] of Object.entries(config.adapters)) {
		if (!isCommandAvailable(adapter.command)) continue;
		const root = findProjectRoot(resolveWorkingDir(params, sessionCwd), adapter.rootMarkers ?? []);
		if (!hasRootMarkers(root, adapter.rootMarkers ?? [])) continue;
		return { name, config: adapter, root };
	}
	return null;
}

function requireSession(): DebugSession {
	if (!activeSession || activeSession.terminated) throw new Error("No active debug session. Launch or attach first.");
	return activeSession;
}

async function setBreakpoint(params: DebugParamsType, timeoutMs: number) {
	const session = requireSession();
	// Note: breakpoints MUST be set before configurationDone per DAP spec
	// We delay configurationDone until launch/attach completes
	if (params.function) {
		const next = dedupeFunctionBreakpoints([
			...session.functionBreakpoints,
			{ name: params.function, condition: params.condition },
		]);
		const body = await sendRequest(session, "setFunctionBreakpoints", { breakpoints: next.map((bp) => ({ name: bp.name, condition: bp.condition })) }, timeoutMs);
		session.functionBreakpoints = next;
		return textResult(formatFunctionBreakpointResult(session.functionBreakpoints), { action: "set_breakpoint", functionBreakpoints: body?.breakpoints ?? [] });
	}
	if (!params.file || !params.line) throw new Error("set_breakpoint requires file+line or function");
	const filePath = path.isAbsolute(params.file) ? params.file : path.resolve(session.cwd, params.file);
	const next = dedupeSourceBreakpoints([
		...(session.breakpoints.get(filePath) ?? []),
		{ line: params.line, condition: params.condition },
	]);
		const body = await sendRequest(session, "setBreakpoints", {
			source: { path: filePath },
			breakpoints: next.map((bp) => ({ line: bp.line, condition: bp.condition })),
		}, timeoutMs);
		session.breakpoints.set(filePath, next);
	return textResult(formatSourceBreakpointResult(filePath, next, session.cwd), { action: "set_breakpoint", breakpoints: body?.breakpoints ?? [] });
}

async function removeBreakpoint(params: DebugParamsType, timeoutMs: number) {
	const session = requireSession();
	if (params.function) {
		session.functionBreakpoints = session.functionBreakpoints.filter((bp) => bp.name !== params.function);
		const body = await sendRequest(session, "setFunctionBreakpoints", { breakpoints: session.functionBreakpoints.map((bp) => ({ name: bp.name, condition: bp.condition })) }, timeoutMs);
		return textResult(formatFunctionBreakpointResult(session.functionBreakpoints), { action: "remove_breakpoint", functionBreakpoints: body?.breakpoints ?? [] });
	}
	if (!params.file || !params.line) throw new Error("remove_breakpoint requires file+line or function");
	const filePath = path.isAbsolute(params.file) ? params.file : path.resolve(session.cwd, params.file);
	const next = (session.breakpoints.get(filePath) ?? []).filter((bp) => bp.line !== params.line);
	await sendRequest(session, "setBreakpoints", {
		source: { path: filePath },
		breakpoints: next.map((bp) => ({ line: bp.line, condition: bp.condition })),
	}, timeoutMs);
	if (next.length === 0) session.breakpoints.delete(filePath);
	else session.breakpoints.set(filePath, next);
	return textResult(formatSourceBreakpointResult(filePath, next, session.cwd), { action: "remove_breakpoint" });
}

function requireCapability(session: DebugSession, key: string, message: string): void {
	if (!(session.capabilities as any)?.[key]) throw new Error(message);
}

async function setInstructionBreakpoint(params: DebugParamsType, timeoutMs: number) {
	const session = requireSession();
	await ensureConfigurationDone(session, timeoutMs);
	requireCapability(session, "supportsInstructionBreakpoints", "Active adapter does not support instruction breakpoints.");
	if (!params.instruction_reference) throw new Error("instruction_reference is required for set_instruction_breakpoint");
	const next = dedupeInstructionBreakpoints([
		...session.instructionBreakpoints,
		{ instructionReference: params.instruction_reference, offset: params.offset, condition: params.condition, hitCondition: params.hit_condition },
	]);
	const body = await sendRequest(session, "setInstructionBreakpoints", {
		breakpoints: next.map((bp) => ({ instructionReference: bp.instructionReference, offset: bp.offset, condition: bp.condition, hitCondition: bp.hitCondition })),
	}, timeoutMs);
	session.instructionBreakpoints = next;
	return textResult(formatInstructionBreakpointResult(next), { action: "set_instruction_breakpoint", instructionBreakpoints: body?.breakpoints ?? [] });
}

async function removeInstructionBreakpoint(params: DebugParamsType, timeoutMs: number) {
	const session = requireSession();
	await ensureConfigurationDone(session, timeoutMs);
	requireCapability(session, "supportsInstructionBreakpoints", "Active adapter does not support instruction breakpoints.");
	if (!params.instruction_reference) throw new Error("instruction_reference is required for remove_instruction_breakpoint");
	const next = session.instructionBreakpoints.filter((bp) => !(bp.instructionReference === params.instruction_reference && (params.offset === undefined || bp.offset === params.offset)));
	const body = await sendRequest(session, "setInstructionBreakpoints", {
		breakpoints: next.map((bp) => ({ instructionReference: bp.instructionReference, offset: bp.offset, condition: bp.condition, hitCondition: bp.hitCondition })),
	}, timeoutMs);
	session.instructionBreakpoints = next;
	return textResult(formatInstructionBreakpointResult(next), { action: "remove_instruction_breakpoint", instructionBreakpoints: body?.breakpoints ?? [] });
}

async function getDataBreakpointInfo(params: DebugParamsType, timeoutMs: number) {
	const session = requireSession();
	await ensureConfigurationDone(session, timeoutMs);
	requireCapability(session, "supportsDataBreakpoints", "Active adapter does not support data breakpoints.");
	if (!params.name) throw new Error("name is required for data_breakpoint_info");
	const variablesReference = params.variable_ref ?? params.scope_id ?? 0;
	const body = await sendRequest(session, "dataBreakpointInfo", {
		name: params.name,
		frameId: params.frame_id ?? session.currentFrameId,
		variablesReference,
	}, timeoutMs);
	return textResult(formatDataBreakpointInfo(body), { action: "data_breakpoint_info", dataBreakpointInfo: body });
}

async function setDataBreakpoint(params: DebugParamsType, timeoutMs: number) {
	const session = requireSession();
	await ensureConfigurationDone(session, timeoutMs);
	requireCapability(session, "supportsDataBreakpoints", "Active adapter does not support data breakpoints.");
	if (!params.data_id) throw new Error("data_id is required for set_data_breakpoint");
	const next = dedupeDataBreakpoints([
		...session.dataBreakpoints,
		{ dataId: params.data_id, accessType: params.access_type as any, condition: params.condition, hitCondition: params.hit_condition },
	]);
	const body = await sendRequest(session, "setDataBreakpoints", {
		breakpoints: next.map((bp) => ({ dataId: bp.dataId, accessType: bp.accessType, condition: bp.condition, hitCondition: bp.hitCondition })),
	}, timeoutMs);
	session.dataBreakpoints = next;
	return textResult(formatDataBreakpointResult(next), { action: "set_data_breakpoint", dataBreakpoints: body?.breakpoints ?? [] });
}

async function removeDataBreakpoint(params: DebugParamsType, timeoutMs: number) {
	const session = requireSession();
	await ensureConfigurationDone(session, timeoutMs);
	requireCapability(session, "supportsDataBreakpoints", "Active adapter does not support data breakpoints.");
	if (!params.data_id) throw new Error("data_id is required for remove_data_breakpoint");
	const next = session.dataBreakpoints.filter((bp) => bp.dataId !== params.data_id);
	const body = await sendRequest(session, "setDataBreakpoints", {
		breakpoints: next.map((bp) => ({ dataId: bp.dataId, accessType: bp.accessType, condition: bp.condition, hitCondition: bp.hitCondition })),
	}, timeoutMs);
	session.dataBreakpoints = next;
	return textResult(formatDataBreakpointResult(next), { action: "remove_data_breakpoint", dataBreakpoints: body?.breakpoints ?? [] });
}

async function executionAction(command: "continue" | "next" | "stepIn" | "stepOut" | "pause", params: DebugParamsType, timeoutMs: number) {
	const session = requireSession();
	await ensureConfigurationDone(session, timeoutMs);
	const threadId = params.thread_id ?? session.currentThreadId;
	if (threadId === undefined) throw new Error("No active thread. Run threads first or stop program.");
	const args = command === "pause" ? { threadId } : { threadId, singleThread: false };
	const waiters = [
		registerEventWaiter(session, "stopped", timeoutMs),
		registerEventWaiter(session, "terminated", timeoutMs),
		registerEventWaiter(session, "exited", timeoutMs),
	];
	const wait = Promise.race(waiters.map((waiter) => waiter.promise)).catch(() => null);
	try {
		await sendRequest(session, command, args, timeoutMs);
		const outcome = await wait;
		if (!outcome) return textResult("Program still running.", { action: command, state: "running", timedOut: true });
		if (outcome.event === "stopped") {
			// Auto-refresh: fetch threads and top frame
			const tid = outcome.body?.threadId ?? threadId;
			session.currentThreadId = tid;
			const details: string[] = [`Stopped: ${outcome.body?.reason ?? "breakpoint"} (thread ${tid})`];
			try {
				const stRes = await sendRequest(session, "stackTrace", { threadId: tid, startFrame: 0, levels: 3 }, 5_000);
				if (stRes?.stackFrames?.length) {
					session.currentFrameId = stRes.stackFrames[0].id;
					details.push("Stack:");
					for (const f of stRes.stackFrames.slice(0, 3)) {
						const loc = f.source ? `${path.basename(f.source.name ?? f.source.path ?? "?")}:${f.line}` : "<no source>";
						details.push(`  ${f.name} at ${loc}`);
					}
				}
			} catch {}
			return textResult(details.join("\n"), { action: command, state: "stopped", timedOut: false, threadId: tid });
		}
		return textResult(`Program ${outcome.event}.`, { action: command, state: outcome.event, timedOut: false });
	} finally {
		for (const waiter of waiters) waiter.cleanup();
	}
}

async function getThreads(timeoutMs: number) {
	const session = requireSession();
	await ensureConfigurationDone(session, timeoutMs);
	const body = await sendRequest(session, "threads", {}, timeoutMs);
	const threads = body?.threads ?? [];
	return textResult(formatThreads(threads), { action: "threads", threads });
}

async function getStackTrace(params: DebugParamsType, timeoutMs: number) {
	const session = requireSession();
	await ensureConfigurationDone(session, timeoutMs);
	const threadId = params.thread_id ?? session.currentThreadId;
	if (threadId === undefined) throw new Error("No active thread. Run threads first or stop program.");
	const body = await sendRequest(session, "stackTrace", { threadId, levels: params.levels ?? 20 }, timeoutMs);
	const frames = body?.stackFrames ?? [];
	session.currentFrames = frames;
	session.currentFrameId = frames[0]?.id;
	return textResult(formatStackFrames(frames, session.cwd), { action: "stack_trace", stackFrames: frames });
}

async function getScopes(params: DebugParamsType, timeoutMs: number) {
	const session = requireSession();
	await ensureConfigurationDone(session, timeoutMs);
	const frameId = params.frame_id ?? session.currentFrameId;
	if (frameId === undefined) throw new Error("No active stack frame. Run stack_trace first or supply frame_id.");
	const body = await sendRequest(session, "scopes", { frameId }, timeoutMs);
	const scopes = body?.scopes ?? [];
	return textResult(formatScopes(scopes), { action: "scopes", scopes });
}

async function getVariables(params: DebugParamsType, timeoutMs: number) {
	const session = requireSession();
	await ensureConfigurationDone(session, timeoutMs);
	const variableRef = params.variable_ref ?? params.scope_id;
	if (variableRef === undefined) throw new Error("variables requires variable_ref or scope_id");
	const body = await sendRequest(session, "variables", { variablesReference: variableRef }, timeoutMs);
	const variables = body?.variables ?? [];
	return textResult(formatVariables(variables), { action: "variables", variables });
}

async function evaluateExpression(params: DebugParamsType, timeoutMs: number) {
	const session = requireSession();
	await ensureConfigurationDone(session, timeoutMs);
	if (!params.expression) throw new Error("expression is required for evaluate");
	const frameId = params.frame_id ?? session.currentFrameId;
	const body = await sendRequest(session, "evaluate", {
		expression: params.expression,
		context: params.context ?? "repl",
		frameId,
	}, timeoutMs);
	return textResult(formatEvaluation(body), { action: "evaluate", evaluation: body });
}

async function disassembleMemory(params: DebugParamsType, timeoutMs: number) {
	const session = requireSession();
	await ensureConfigurationDone(session, timeoutMs);
	requireCapability(session, "supportsDisassembleRequest", "Active adapter does not support disassemble.");
	const memoryReference = params.memory_reference ?? params.instruction_reference;
	if (!memoryReference) throw new Error("memory_reference or instruction_reference is required for disassemble");
	if (params.instruction_count === undefined) throw new Error("instruction_count is required for disassemble");
	const body = await sendRequest(session, "disassemble", {
		memoryReference,
		offset: params.offset,
		instructionOffset: params.instruction_offset,
		instructionCount: params.instruction_count,
		resolveSymbols: params.resolve_symbols,
	}, timeoutMs);
	const instructions = body?.instructions ?? [];
	return textResult(formatDisassembly(instructions), { action: "disassemble", disassembly: instructions });
}

async function readMemory(params: DebugParamsType, timeoutMs: number) {
	const session = requireSession();
	await ensureConfigurationDone(session, timeoutMs);
	requireCapability(session, "supportsReadMemoryRequest", "Active adapter does not support memory reads.");
	if (!params.memory_reference) throw new Error("memory_reference is required for read_memory");
	if (params.count === undefined) throw new Error("count is required for read_memory");
	const body = await sendRequest(session, "readMemory", {
		memoryReference: params.memory_reference,
		offset: params.offset,
		count: params.count,
	}, timeoutMs);
	return textResult(formatReadMemory(body), { action: "read_memory", memoryAddress: body?.address, memoryData: body?.data, unreadableBytes: body?.unreadableBytes });
}

async function writeMemory(params: DebugParamsType, timeoutMs: number) {
	const session = requireSession();
	await ensureConfigurationDone(session, timeoutMs);
	requireCapability(session, "supportsWriteMemoryRequest", "Active adapter does not support memory writes.");
	if (!params.memory_reference) throw new Error("memory_reference is required for write_memory");
	if (!params.data) throw new Error("data is required for write_memory");
	const body = await sendRequest(session, "writeMemory", {
		memoryReference: params.memory_reference,
		offset: params.offset,
		data: params.data,
		allowPartial: params.allow_partial,
	}, timeoutMs);
	return textResult(formatWriteMemory(body), { action: "write_memory", bytesWritten: body?.bytesWritten, offset: body?.offset });
}

async function listModules(params: DebugParamsType, timeoutMs: number) {
	const session = requireSession();
	await ensureConfigurationDone(session, timeoutMs);
	requireCapability(session, "supportsModulesRequest", "Active adapter does not support modules.");
	const body = await sendRequest(session, "modules", { startModule: params.start_module, moduleCount: params.module_count }, timeoutMs);
	const modules = body?.modules ?? [];
	return textResult(formatModules(modules), { action: "modules", modules });
}

async function listLoadedSources(timeoutMs: number) {
	const session = requireSession();
	await ensureConfigurationDone(session, timeoutMs);
	requireCapability(session, "supportsLoadedSourcesRequest", "Active adapter does not support loaded sources.");
	const body = await sendRequest(session, "loadedSources", {}, timeoutMs);
	const sources = body?.sources ?? [];
	return textResult(formatLoadedSources(sources), { action: "loaded_sources", sources });
}

async function customRequest(params: DebugParamsType, timeoutMs: number) {
	const session = requireSession();
	await ensureConfigurationDone(session, timeoutMs);
	if (!params.command) throw new Error("command is required for custom_request");
	const body = await sendRequest(session, params.command, params.arguments ?? {}, timeoutMs);
	return textResult(formatGeneric(body), { action: "custom_request", customBody: body });
}

async function terminateSession(timeoutMs: number) {
	const session = activeSession;
	if (!session) return textResult("No debug session to terminate.", { action: "terminate" });
	try {
		await ensureConfigurationDone(session, timeoutMs);
		if ((session.capabilities as any)?.supportsTerminateRequest) {
			await sendRequest(session, "terminate", {}, Math.min(timeoutMs, 5_000));
		}
	} catch {}
	try {
		await sendRequest(session, "disconnect", { terminateDebuggee: true }, Math.min(timeoutMs, 5_000));
	} catch {}
	try { session.socket?.destroy(); } catch {}
	try { session.proc.kill(); } catch {}
	session.terminated = true;
	activeSession = null;
	return textResult("Debug session terminated.", { action: "terminate", session: summarizeSession(session) });
}

function listSessions() {
	if (!activeSession) return textResult("No active debug sessions.", { action: "sessions", sessions: [] });
	return textResult(formatSessionSummary(activeSession), { action: "sessions", sessions: [summarizeSession(activeSession)] });
}

function summarizeSession(session: DebugSession) {
	return {
		id: session.id,
		adapter: session.adapterName,
		cwd: session.cwd,
		terminated: session.terminated,
		currentThreadId: session.currentThreadId,
		currentFrameId: session.currentFrameId,
		lastStopReason: session.lastStopReason,
	};
}

function dedupeSourceBreakpoints(bps: SourceBreakpoint[]): SourceBreakpoint[] {
	const map = new Map<string, SourceBreakpoint>();
	for (const bp of bps) map.set(`${bp.line}:${bp.condition ?? ""}`, bp);
	return [...map.values()].sort((a, b) => a.line - b.line);
}

function dedupeFunctionBreakpoints(bps: FunctionBreakpoint[]): FunctionBreakpoint[] {
	const map = new Map<string, FunctionBreakpoint>();
	for (const bp of bps) map.set(`${bp.name}:${bp.condition ?? ""}`, bp);
	return [...map.values()].sort((a, b) => a.name.localeCompare(b.name));
}

function dedupeInstructionBreakpoints(bps: InstructionBreakpoint[]): InstructionBreakpoint[] {
	const map = new Map<string, InstructionBreakpoint>();
	for (const bp of bps) map.set(`${bp.instructionReference}:${bp.offset ?? 0}:${bp.condition ?? ""}:${bp.hitCondition ?? ""}`, bp);
	return [...map.values()].sort((a, b) => `${a.instructionReference}:${a.offset ?? 0}`.localeCompare(`${b.instructionReference}:${b.offset ?? 0}`));
}

function dedupeDataBreakpoints(bps: DataBreakpoint[]): DataBreakpoint[] {
	const map = new Map<string, DataBreakpoint>();
	for (const bp of bps) map.set(`${bp.dataId}:${bp.accessType ?? ""}:${bp.condition ?? ""}:${bp.hitCondition ?? ""}`, bp);
	return [...map.values()].sort((a, b) => a.dataId.localeCompare(b.dataId));
}

function formatSourceBreakpointResult(filePath: string, breakpoints: SourceBreakpoint[], cwd: string): string {
	const rel = path.relative(cwd, filePath);
	if (breakpoints.length === 0) return `No breakpoints for ${rel}`;
	return [`Breakpoints for ${rel}:`, ...breakpoints.map((bp) => `  - line ${bp.line}${bp.condition ? ` if ${bp.condition}` : ""}`)].join("\n");
}

function formatFunctionBreakpointResult(breakpoints: FunctionBreakpoint[]): string {
	if (breakpoints.length === 0) return "No function breakpoints.";
	return ["Function breakpoints:", ...breakpoints.map((bp) => `  - ${bp.name}${bp.condition ? ` if ${bp.condition}` : ""}`)].join("\n");
}

function formatInstructionBreakpointResult(breakpoints: InstructionBreakpoint[]): string {
	if (breakpoints.length === 0) return "No instruction breakpoints.";
	return ["Instruction breakpoints:", ...breakpoints.map((bp) => `  - ${bp.instructionReference}${bp.offset !== undefined ? `+${bp.offset}` : ""}${bp.condition ? ` if ${bp.condition}` : ""}${bp.hitCondition ? ` hit ${bp.hitCondition}` : ""}`)].join("\n");
}

function formatDataBreakpointInfo(body: any): string {
	if (!body) return "No data breakpoint info.";
	const lines = [
		`dataId: ${body.dataId ?? "<none>"}`,
		`description: ${body.description ?? ""}`.trim(),
	];
	if (Array.isArray(body.accessTypes) && body.accessTypes.length > 0) lines.push(`accessTypes: ${body.accessTypes.join(", ")}`);
	if (body.canPersist !== undefined) lines.push(`canPersist: ${body.canPersist}`);
	return lines.filter(Boolean).join("\n");
}

function formatDataBreakpointResult(breakpoints: DataBreakpoint[]): string {
	if (breakpoints.length === 0) return "No data breakpoints.";
	return ["Data breakpoints:", ...breakpoints.map((bp) => `  - ${bp.dataId}${bp.accessType ? ` [${bp.accessType}]` : ""}${bp.condition ? ` if ${bp.condition}` : ""}${bp.hitCondition ? ` hit ${bp.hitCondition}` : ""}`)].join("\n");
}

function formatThreads(threads: any[]): string {
	if (!threads.length) return "Debugger reported no threads.";
	return threads.map((thread) => `- ${thread.id}: ${thread.name ?? "thread"}`).join("\n");
}

function formatStackFrames(frames: any[], cwd: string): string {
	if (!frames.length) return "No stack frames.";
	return frames.map((frame) => {
		const src = frame.source?.path ? path.relative(cwd, frame.source.path) : frame.source?.name ?? "<unknown>";
		return `- ${frame.id}: ${frame.name} — ${src}:${frame.line ?? "?"}`;
	}).join("\n");
}

function formatScopes(scopes: any[]): string {
	if (!scopes.length) return "No scopes.";
	return scopes.map((scope) => `- ${scope.name}: variable_ref=${scope.variablesReference}`).join("\n");
}

function formatVariables(variables: any[]): string {
	if (!variables.length) return "No variables.";
	return variables.map((variable) => {
		const suffix = variable.variablesReference ? ` (ref ${variable.variablesReference})` : "";
		return `- ${variable.name} = ${variable.value}${suffix}`;
	}).join("\n");
}

function formatEvaluation(body: any): string {
	if (!body) return "No evaluation result.";
	const type = body.type ? ` [${body.type}]` : "";
	const ref = body.variablesReference ? ` (ref ${body.variablesReference})` : "";
	return `${body.result ?? ""}${type}${ref}`.trim() || "No evaluation result.";
}

function formatDisassembly(instructions: any[]): string {
	if (!instructions.length) return "No disassembly.";
	return instructions.map((inst) => `- ${inst.address ?? "?"} ${inst.instruction ?? inst.instructionBytes ?? ""}${inst.symbol ? ` (${inst.symbol})` : ""}`).join("\n");
}

function formatReadMemory(body: any): string {
	if (!body) return "No memory read result.";
	const lines = [`address: ${body.address ?? "?"}`, `data(base64): ${body.data ?? ""}`];
	if (body.unreadableBytes !== undefined) lines.push(`unreadableBytes: ${body.unreadableBytes}`);
	return lines.join("\n");
}

function formatWriteMemory(body: any): string {
	if (!body) return "No memory write result.";
	return `bytesWritten: ${body.bytesWritten ?? 0}${body.offset !== undefined ? `\noffset: ${body.offset}` : ""}`;
}

function formatModules(modules: any[]): string {
	if (!modules.length) return "No modules.";
	return modules.map((m) => `- ${m.id ?? "?"}: ${m.name ?? "<unnamed>"}${m.path ? ` — ${m.path}` : ""}`).join("\n");
}

function formatLoadedSources(sources: any[]): string {
	if (!sources.length) return "No loaded sources.";
	return sources.map((s) => `- ${s.name ?? path.basename(s.path ?? "<unknown>")}${s.path ? ` — ${s.path}` : ""}`).join("\n");
}

function formatGeneric(body: any): string {
	if (body === undefined) return "null";
	if (typeof body === "string") return body;
	return JSON.stringify(body, null, 2);
}

function formatSessionSummary(session: DebugSession): string {
	const lines = [
		`Session: ${session.id}`,
		`adapter: ${session.adapterName}`,
		`cwd: ${session.cwd}`,
		`state: ${session.terminated ? "terminated" : "active"}`,
	];
	if (session.currentThreadId !== undefined) lines.push(`thread: ${session.currentThreadId}`);
	if (session.currentFrameId !== undefined) lines.push(`frame: ${session.currentFrameId}`);
	if (session.lastStopReason) lines.push(`last stop: ${session.lastStopReason}`);
	return lines.join("\n");
}

function textResult(text: string, details: Record<string, unknown> = {}) {
	return { content: [{ type: "text" as const, text }], details };
}

function errorResult(message: string) {
	return textResult(`Error: ${message}`);
}

export default function debugExtension(pi: ExtensionAPI) {
	let sessionCwd = process.cwd();

	pi.on("session_start", async (_event, ctx) => {
		sessionCwd = ctx.cwd ?? process.cwd();
	});

	pi.on("session_shutdown", async () => {
		if (!activeSession) return;
		try { activeSession.socket?.destroy(); } catch {}
		try { activeSession.proc.kill(); } catch {}
		activeSession = null;
	});

	pi.registerTool({
		name: "debug",
		label: "Debug",
		description: `Drive one DAP debug session.

Actions:
- launch / attach
- set_breakpoint / remove_breakpoint
- set_instruction_breakpoint / remove_instruction_breakpoint
- data_breakpoint_info / set_data_breakpoint / remove_data_breakpoint
- continue / pause / step_over / step_in / step_out
- threads / stack_trace / scopes / variables / evaluate
- disassemble / read_memory / write_memory
- modules / loaded_sources / custom_request
- output / terminate / sessions

Requires debugger adapters like dlv, debugpy, lldb-dap, gdb, or codelldb on PATH.`,
		parameters: DebugParams,

		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			sessionCwd = ctx.cwd ?? sessionCwd;
			const config = loadConfig(sessionCwd);
			const timeoutMs = Math.max(5, Math.min(300, params.timeout ?? 30)) * 1000;
			try {
				switch (params.action) {
					case "launch": return await launchSession(params, config, sessionCwd, timeoutMs);
					case "attach": return await attachSession(params, config, sessionCwd, timeoutMs);
					case "set_breakpoint": return await setBreakpoint(params, timeoutMs);
					case "remove_breakpoint": return await removeBreakpoint(params, timeoutMs);
					case "set_instruction_breakpoint": return await setInstructionBreakpoint(params, timeoutMs);
					case "remove_instruction_breakpoint": return await removeInstructionBreakpoint(params, timeoutMs);
					case "data_breakpoint_info": return await getDataBreakpointInfo(params, timeoutMs);
					case "set_data_breakpoint": return await setDataBreakpoint(params, timeoutMs);
					case "remove_data_breakpoint": return await removeDataBreakpoint(params, timeoutMs);
					case "continue": return await executionAction("continue", params, timeoutMs);
					case "pause": return await executionAction("pause", params, timeoutMs);
					case "step_over": return await executionAction("next", params, timeoutMs);
					case "step_in": return await executionAction("stepIn", params, timeoutMs);
					case "step_out": return await executionAction("stepOut", params, timeoutMs);
					case "threads": return await getThreads(timeoutMs);
					case "stack_trace": return await getStackTrace(params, timeoutMs);
					case "scopes": return await getScopes(params, timeoutMs);
					case "variables": return await getVariables(params, timeoutMs);
					case "evaluate": return await evaluateExpression(params, timeoutMs);
					case "disassemble": return await disassembleMemory(params, timeoutMs);
					case "read_memory": return await readMemory(params, timeoutMs);
					case "write_memory": return await writeMemory(params, timeoutMs);
					case "modules": return await listModules(params, timeoutMs);
					case "loaded_sources": return await listLoadedSources(timeoutMs);
					case "custom_request": return await customRequest(params, timeoutMs);
					case "output":
						if (!activeSession || activeSession.terminated) return errorResult("No active debug session");
						return textResult(activeSession.output.trim() || "No debug output.", { action: "output" });
					case "terminate": return await terminateSession(timeoutMs);
					case "sessions": return listSessions();
					default: return errorResult(`Unknown action: ${(params as any).action}`);
				}
			} catch (err: any) {
				return errorResult(`DAP error: ${err.message}`);
			}
		},

		renderCall(args: any, theme: any) {
			const action = args.action ?? "sessions";
			const adapter = args.adapter ? ` ${args.adapter}` : "";
			const file = args.file ? ` ${path.basename(args.file)}${args.line ? `:${args.line}` : ""}` : "";
			return new Text(theme.fg("toolTitle", theme.bold("debug ")) + theme.fg("accent", `${action}${adapter}`) + theme.fg("dim", file), 0, 0);
		},

		renderResult(result: any, { isPartial }: { isPartial: boolean }, theme: any) {
			if (isPartial) return new Text(theme.fg("warning", "Debug request pending..."), 0, 0);
			const text = result.content?.[0]?.text ?? "";
			if (text.startsWith("Error:")) return new Text(theme.fg("error", text), 0, 0);
			const firstLine = text.split("\n")[0] ?? "";
			return new Text(theme.fg("muted", firstLine.length > 90 ? `${firstLine.slice(0, 87)}...` : firstLine), 0, 0);
		},
	});
}
