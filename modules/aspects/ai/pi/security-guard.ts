/**
 * Security Guard Extension
 *
 * Protects against destructive operations, sensitive file access,
 * and container escapes using structural command parsing.
 *
 * Two subsystems:
 * 1. Permission Gate — structural matching of dangerous bash commands
 *    with interactive TUI confirmation widget (scrollable command preview)
 * 2. File Policies — named rules with glob patterns and protection levels
 *
 * Config: ~/.pi/agent/security-guard.json (deployed via nix)
 */

import { DynamicBorder, type ExtensionAPI } from "@mariozechner/pi-coding-agent";
import {
	Container,
	Key,
	matchesKey,
	Spacer,
	Text,
	visibleWidth,
	wrapTextWithAnsi,
} from "@mariozechner/pi-tui";
import * as fs from "node:fs";
import * as path from "node:path";
import { homedir } from "node:os";
import { matchesGlob } from "node:path";

// ── Types ─────────────────────────────────────────────────────────────────────

type Protection = "none" | "readOnly" | "noAccess";

interface Pattern {
	pattern: string;
	regex?: boolean;
}

interface PolicyRule {
	id: string;
	description?: string;
	patterns: Pattern[];
	allowedPatterns?: Pattern[];
	protection: Protection;
	onlyIfExists?: boolean;
	blockMessage?: string;
	enabled?: boolean;
}

interface PermissionRule {
	pattern: string;
	description?: string;
	action: "prompt" | "block" | "allow";
}

interface SecurityConfig {
	enabled?: boolean;
	features?: {
		permissionGate?: boolean;
		policies?: boolean;
	};
	permissionGate: {
		patterns: PermissionRule[];
		requireConfirmation?: boolean;
	};
	policies: {
		rules: PolicyRule[];
	};
}

// ── Defaults ──────────────────────────────────────────────────────────────────

const DEFAULT_CONFIG: SecurityConfig = {
	enabled: true,
	features: { permissionGate: true, policies: true },
	permissionGate: {
		requireConfirmation: true,
		patterns: [
			{ pattern: "rm -rf /", description: "Recursive force root delete", action: "block" },
			{ pattern: "rm -rf ~", description: "Recursive force home delete", action: "block" },
			{ pattern: "rm -rf", description: "Recursive force delete", action: "prompt" },
			{ pattern: "sudo rm", description: "Privileged delete", action: "block" },
			{ pattern: "sudo", description: "Privileged command", action: "prompt" },
			{ pattern: "dd of=", description: "Disk write", action: "block" },
			{ pattern: "dd if=", description: "Disk imaging", action: "prompt" },
			{ pattern: "mkfs", description: "Filesystem format", action: "block" },
			{ pattern: "shred", description: "Secure overwrite", action: "block" },
			{ pattern: "wipefs", description: "FS signature wipe", action: "block" },
			{ pattern: "blkdiscard", description: "Block device discard", action: "block" },
			{ pattern: "fdisk", description: "Disk partitioning", action: "block" },
			{ pattern: "parted", description: "Disk partitioning", action: "block" },
			{ pattern: "chmod -R 777", description: "Insecure permissions", action: "prompt" },
			{ pattern: "chmod 777", description: "World-writable permissions", action: "prompt" },
			{ pattern: "chown -R", description: "Recursive ownership change", action: "block" },
			{ pattern: "git push --force", description: "Force push", action: "prompt" },
			{ pattern: "git push -f", description: "Force push", action: "prompt" },
			{ pattern: "curl.*\| sh", description: "Pipe download to shell", action: "block" },
			{ pattern: "curl.*\| bash", description: "Pipe download to shell", action: "block" },
			{ pattern: "wget.*\| sh", description: "Pipe download to shell", action: "block" },
			{ pattern: "wget.*\| bash", description: "Pipe download to shell", action: "block" },
			{ pattern: "reboot", description: "System reboot", action: "block" },
			{ pattern: "shutdown", description: "System shutdown", action: "block" },
			{ pattern: "docker run --privileged", description: "Privileged container", action: "block" },
			{ pattern: "--pid=host", description: "Host PID namespace", action: "block" },
			{ pattern: "--network=host", description: "Host network", action: "prompt" },
			{ pattern: "docker.sock", description: "Docker socket mount", action: "prompt" },
		],
	},
	policies: {
		rules: [
			{
				id: "secret-files",
				description: "Secret environment files",
				patterns: [
					{ pattern: ".env" },
					{ pattern: ".env.local" },
					{ pattern: ".env.production" },
					{ pattern: ".env.prod" },
					{ pattern: ".dev.vars" },
				],
				allowedPatterns: [
					{ pattern: ".env.example" },
					{ pattern: ".env.sample" },
					{ pattern: ".env.test" },
				],
				protection: "noAccess",
				onlyIfExists: false,
				blockMessage: "Accessing {file} is not allowed — it may contain secrets.",
			},
			{
				id: "ssh-keys",
				description: "SSH keys",
				patterns: [{ pattern: "~/.ssh/**" }],
				allowedPatterns: [
					{ pattern: "~/.ssh/*.pub" },
					{ pattern: "~/.ssh/config" },
					{ pattern: "~/.ssh/known_hosts" },
				],
				protection: "noAccess",
				onlyIfExists: true,
				blockMessage: "Accessing {file} is not allowed — SSH private keys.",
			},
			{
				id: "cloud-creds",
				description: "Cloud credentials",
				patterns: [
					{ pattern: "~/.aws/**" },
					{ pattern: "~/.config/gcloud/**" },
					{ pattern: "~/.config/sops/**" },
				],
				protection: "noAccess",
				onlyIfExists: true,
				blockMessage: "Accessing {file} is not allowed — cloud credentials.",
			},
			{
				id: "gpg-keys",
				description: "GPG keys",
				patterns: [{ pattern: "~/.gnupg/**" }],
				protection: "noAccess",
				onlyIfExists: true,
				blockMessage: "Accessing {file} is not allowed — GPG keys.",
			},
			{
				id: "system-config",
				description: "System configuration",
				patterns: [
					{ pattern: "/etc/**" },
					{ pattern: "/boot/**" },
					{ pattern: "/usr/**" },
				],
				protection: "readOnly",
				onlyIfExists: true,
				blockMessage: "Writing to {file} is not allowed — system directory.",
			},
		],
	},
};

// ── Config Loading ────────────────────────────────────────────────────────────

function getConfigPath(): string {
	return path.join(homedir(), ".pi", "agent", "security-guard.json");
}

function loadConfig(): SecurityConfig {
	try {
		const raw = fs.readFileSync(getConfigPath(), "utf-8");
		const parsed = JSON.parse(raw);
		return {
			enabled: parsed.enabled ?? DEFAULT_CONFIG.enabled,
			features: { ...DEFAULT_CONFIG.features, ...parsed.features },
			permissionGate: {
				requireConfirmation: parsed.permissionGate?.requireConfirmation ?? DEFAULT_CONFIG.permissionGate.requireConfirmation,
				patterns: parsed.permissionGate?.patterns?.length
					? parsed.permissionGate.patterns
					: DEFAULT_CONFIG.permissionGate.patterns,
			},
			policies: parsed.policies?.rules?.length
				? parsed.policies
				: DEFAULT_CONFIG.policies,
		};
	} catch {
		return DEFAULT_CONFIG;
	}
}

// ── Pattern Matching ─────────────────────────────────────────────────────────

function normalizePath(p: string): string {
	return p.replace(/\\/g, "/").replace(/\/+/g, "/");
}

function matchGlobPattern(filePath: string, pattern: string): boolean {
	const norm = normalizePath(filePath);
	const fullMatch = pattern.includes("/");
	const candidate = fullMatch ? norm : (norm.split("/").pop() ?? norm);
	return matchesGlob(candidate, pattern);
}

function matchesFilePattern(filePath: string, pattern: Pattern): boolean {
	const expanded = filePath.replace(homedir(), "~");
	if (pattern.regex) {
		try {
			return new RegExp(pattern.pattern, "i").test(normalizePath(expanded));
		} catch {
			return false;
		}
	}
	return matchGlobPattern(expanded, pattern.pattern);
}

function expandHome(p: string): string {
	if (p === "~") return homedir();
	if (p.startsWith("~/")) return path.join(homedir(), p.slice(2));
	return p;
}

// ── Structural Command Parsing ────────────────────────────────────────────────

function parseCommand(command: string): string[] {
	const tokens: string[] = [];
	let current = "";
	let inQuote: string | null = null;

	for (const ch of command) {
		if (inQuote) {
			if (ch === inQuote) {
				inQuote = null;
			} else {
				current += ch;
			}
			continue;
		}

		if (ch === '"' || ch === "'") {
			inQuote = ch;
			continue;
		}

		if (/\s/.test(ch)) {
			if (current.length > 0) {
				tokens.push(current);
				current = "";
			}
			continue;
		}

		current += ch;
	}

	if (current.length > 0) tokens.push(current);
	return tokens;
}

function hasFlag(words: string[], flag: string): boolean {
	return words.some(
		(w) => w === `-${flag}`,
	);
}

function hasLongOpt(words: string[], opt: string): boolean {
	return words.some((w) => w === `--${opt}`);
}

interface StructuralMatch {
	description: string;
	pattern: string;
}

function matchStructural(command: string): StructuralMatch | undefined {
	const words = parseCommand(command);
	const cmd = words[0];
	if (!cmd) return undefined;

	if (cmd === "rm") {
		const recursive = hasFlag(words, "r") || hasFlag(words, "R") || hasLongOpt(words, "recursive");
		const force = hasFlag(words, "f") || hasLongOpt(words, "force");
		const target = words.slice(1).find((w) => !w.startsWith("-")) || "";
		if (recursive && force && (target === "/" || target.startsWith("/")))
			return { description: "Recursive force root delete", pattern: "rm -rf /" };
		if (recursive && force && (target === "~" || target.startsWith("~")))
			return { description: "Recursive force home delete", pattern: "rm -rf ~" };
		if (recursive && force)
			return { description: "Recursive force delete", pattern: "rm -rf" };
	}

	if (cmd === "sudo") {
		if (words[1] === "rm") return { description: "Privileged delete", pattern: "sudo rm" };
		return { description: "Privileged command", pattern: "sudo" };
	}

	if (cmd === "dd") {
		if (words.some((w) => w.startsWith("of="))) return { description: "Disk write operation", pattern: "dd of=" };
		if (words.some((w) => w.startsWith("if="))) return { description: "Disk imaging", pattern: "dd if=" };
	}

	if (cmd === "mkfs" || cmd?.startsWith("mkfs.")) return { description: "Filesystem format", pattern: "mkfs" };
	if (cmd === "shred") return { description: "Secure file overwrite", pattern: "shred" };
	if (cmd === "wipefs") return { description: "FS signature wipe", pattern: "wipefs" };
	if (cmd === "blkdiscard") return { description: "Block device discard", pattern: "blkdiscard" };
	if (cmd === "fdisk" || cmd === "sfdisk" || cmd === "cfdisk") return { description: "Disk partitioning", pattern: "fdisk" };
	if (cmd === "parted" || cmd === "sgdisk") return { description: "Disk partitioning", pattern: "parted" };

	if (cmd === "chmod") {
		const recursive = hasFlag(words, "r") || hasLongOpt(words, "recursive");
		const hasMode = words.slice(1).some((w) => /^0?777$/.test(w));
		if (recursive && hasMode) return { description: "Insecure recursive permissions", pattern: "chmod -R 777" };
		if (hasMode) return { description: "World-writable permissions", pattern: "chmod 777" };
	}

	if (cmd === "chown") {
		const recursive = hasFlag(words, "r") || hasFlag(words, "R") || hasLongOpt(words, "recursive");
		if (recursive) return { description: "Recursive ownership change", pattern: "chown -R" };
	}

	if (cmd === "shutdown") return { description: "System shutdown", pattern: "shutdown" };
	if (cmd === "reboot") return { description: "System reboot", pattern: "reboot" };

	if (cmd === "docker" || cmd === "podman") {
		const sub = words[1];
		if (sub === "run" || sub === "create") {
			if (words.some((w) => w === "--privileged")) return { description: "Privileged container", pattern: "docker run --privileged" };
			if (words.some((w) => w.startsWith("--pid=host"))) return { description: "Host PID namespace", pattern: "--pid=host" };
			if (words.some((w) => w.startsWith("--network=host"))) return { description: "Host network access", pattern: "--network=host" };
			if (words.some((w) => w.startsWith("--userns=host"))) return { description: "Host user namespace", pattern: "--userns=host" };
			if (words.some((w) => w.includes("docker.sock"))) return { description: "Docker socket mount", pattern: "docker.sock" };
			if (words.some((w) => w.startsWith("-v/:") || w.startsWith("--volume=/:"))) return { description: "Root filesystem mount in container", pattern: "docker run -v /" };
		}
	}

	return undefined;
}

// ── Interactive Confirmation Widget ───────────────────────────────────────────

type ConfirmResult = "allow" | "deny";
type ThemeLike = { fg(color: string, text: string): string; bg(color: string, text: string): string; bold(text: string): string };

const COMMAND_VIEWPORT_LINES = 12;

function createConfirmComponent(
	command: string,
	description: string,
) {
	return (
		_tui: { terminal: { rows: number; columns: number }; requestRender(): void },
		theme: ThemeLike,
		_kb: unknown,
		done: (result: ConfirmResult) => void,
	) => {
		const container = new Container();
		const redBorder = (s: string) => theme.fg("error", s);
		const dimBorder = (s: string) => theme.fg("dim", s);
		let scrollOffset = 0;

		// Header
		container.addChild(new DynamicBorder(redBorder));
		container.addChild(new Text(theme.fg("error", theme.bold("⛔  Dangerous Command Detected")), 1, 0));
		container.addChild(new Spacer(1));
		container.addChild(new Text(theme.fg("warning", `This command contains: ${description}`), 1, 0));
		container.addChild(new Spacer(1));

		// Command preview (scrollable)
		const cmdTopBorder = new Text("", 0, 0);
		container.addChild(cmdTopBorder);
		const cmdText = new Text("", 1, 0);
		container.addChild(cmdText);
		const cmdBottomBorder = new Text("", 0, 0);
		container.addChild(cmdBottomBorder);
		container.addChild(new Spacer(1));

		// Prompt
		container.addChild(new Text(theme.fg("text", "Allow execution?"), 1, 0));
		container.addChild(new Spacer(1));
		container.addChild(new Text(theme.fg("dim", "↑/↓ or j/k: scroll • y/enter: allow • n/esc: deny"), 1, 0));
		container.addChild(new DynamicBorder(redBorder));

		function buildWrappedLines(contentWidth: number): Array<{ rendered: string; lineNum: number }> {
			const logicalLines = command.split("\n");
			const numWidth = Math.max(2, String(logicalLines.length).length);
			const textWidth = Math.max(1, contentWidth - numWidth - 1);
			const rows: Array<{ rendered: string; lineNum: number }> = [];
			for (const [idx, line] of logicalLines.entries()) {
				const wrapped = wrapTextWithAnsi(theme.fg("text", line), textWidth);
				const wrappedArr = wrapped.length > 0 ? wrapped : [""];
				const prefix = theme.fg("dim", String(idx + 1).padStart(numWidth));
				for (const wl of wrappedArr) {
					rows.push({ rendered: `${prefix} ${wl}`, lineNum: idx + 1 });
				}
			}
			return rows;
		}

		return {
			render: (width: number) => {
				const contentWidth = Math.max(1, width - 4);
				const rows = buildWrappedLines(contentWidth);
				const pinned = rows.filter((r) => r.lineNum === 1);
				const scrollable = rows.filter((r) => r.lineNum !== 1);
				const scrollWindow = Math.max(0, COMMAND_VIEWPORT_LINES - pinned.length);
				const maxScroll = Math.max(0, scrollable.length - scrollWindow);
				scrollOffset = Math.max(0, Math.min(scrollOffset, maxScroll));

				const visibleScroll = scrollable.slice(scrollOffset, scrollOffset + scrollWindow);
				const visible = [...pinned, ...visibleScroll];
				const linesBelow = Math.max(0, scrollable.length - (scrollOffset + visibleScroll.length));

				cmdTopBorder.setText(
					scrollOffset > 0
						? dimBorder(`├${"─".repeat(Math.max(0, width - 3))}↑ ${scrollOffset} more`)
						: dimBorder(`┌${"─".repeat(Math.max(0, width - 2))}┐`),
				);
				cmdText.setText(visible.map((r) => r.rendered).join("\n"));
				cmdBottomBorder.setText(
					linesBelow > 0
						? dimBorder(`├${"─".repeat(Math.max(0, width - 3))}↓ ${linesBelow} more`)
						: dimBorder(`└${"─".repeat(Math.max(0, width - 2))}┘`),
				);

				return container.render(width);
			},
			invalidate: () => container.invalidate(),
			handleInput: (data: string) => {
				if (matchesKey(data, Key.up) || data === "k") {
					scrollOffset = Math.max(0, scrollOffset - 1);
					_tui.requestRender();
				} else if (matchesKey(data, Key.down) || data === "j") {
					scrollOffset += 1;
					_tui.requestRender();
				} else if (matchesKey(data, Key.enter) || data === "y" || data === "Y") {
					done("allow");
				} else if (matchesKey(data, Key.escape) || data === "n" || data === "N") {
					done("deny");
				}
			},
		};
	};
}

// ── Permission Gate Hook ──────────────────────────────────────────────────────

function setupPermissionGate(pi: ExtensionAPI, config: SecurityConfig): void {
	if (!config.features?.permissionGate) return;

	pi.on("tool_call", async (event, ctx) => {
		if (event.toolName !== "bash") return;

		const command = String((event.input as Record<string, unknown>).command ?? "");
		if (!command) return;

		// Try structural matching first
		const structural = matchStructural(command);
		let matchedRule: PermissionRule | undefined;

		if (structural) {
			matchedRule = config.permissionGate.patterns.find(
				(r) => r.pattern === structural.pattern,
			);
		} else {
			// Fallback to substring matching
			matchedRule = config.permissionGate.patterns.find(
				(r) => command.includes(r.pattern),
			);
		}

		if (!matchedRule) return;
		const action = matchedRule.action;
		const description = matchedRule.description ?? matchedRule.pattern;

		if (action === "allow") return;

		if (action === "block") {
			ctx.ui.notify(`⛔ Blocked: ${description}`, "error");
			return { block: true, reason: `Security guard: ${description}` };
		}

		// action === "prompt" — interactive confirmation
		if (config.permissionGate.requireConfirmation && ctx.hasUI) {
			let result = await ctx.ui.custom<ConfirmResult>(
				createConfirmComponent(command, description),
			);

			// Fallback for RPC/headless where custom() returns undefined
			if (result === undefined) {
				try {
					const selection = await ctx.ui.select(
						`Dangerous command: ${description}`,
						["Allow once", "Deny"],
					);
					result = selection === "Allow once" ? "allow" : "deny";
				} catch {
					result = "deny";
				}
			}

			if (result === "deny") {
				return { block: true, reason: `User denied: ${description}` };
			}
			// allowed — continue
			return;
		}

		// No confirmation required or no UI — just warn
		ctx.ui.notify(`⚠️  Dangerous: ${description}`, "warning");
	});
}

// ── File Policies Hook ────────────────────────────────────────────────────────

const BLOCKED_TOOLS: Record<Protection, Set<string>> = {
	noAccess: new Set(["read", "write", "edit", "bash"]),
	readOnly: new Set(["write", "edit", "bash"]),
	none: new Set(),
};

async function fileExists(filePath: string): Promise<boolean> {
	try {
		await fs.promises.stat(expandHome(filePath));
		return true;
	} catch {
		return false;
	}
}

function extractPathFromInput(toolName: string, input: Record<string, unknown>): string {
	return String(input.file_path ?? input.path ?? "").trim();
}

function setupPolicies(pi: ExtensionAPI, config: SecurityConfig): void {
	if (!config.features?.policies) return;

	const rules = config.policies.rules.filter(
		(r) => r.enabled !== false && r.protection !== "none",
	);

	pi.on("tool_call", async (event, ctx) => {
		const toolName = event.toolName;
		const input = event.input as Record<string, unknown>;

		let targetPath = "";
		if (["read", "write", "edit"].includes(toolName)) {
			targetPath = extractPathFromInput(toolName, input);
		} else if (toolName === "bash") {
			return; // bash handled by permission gate
		} else {
			return;
		}

		if (!targetPath) return;

		const absPath = path.isAbsolute(targetPath)
			? targetPath
			: path.resolve(ctx.cwd, targetPath);

		for (const rule of rules) {
			const matched = rule.patterns.some((p) => matchesFilePattern(absPath, p));
			if (!matched) continue;

			const allowed = (rule.allowedPatterns ?? []).some((p) => matchesFilePattern(absPath, p));
			if (allowed) continue;

			if (rule.onlyIfExists && !(await fileExists(absPath))) continue;

			const blockedTools = BLOCKED_TOOLS[rule.protection];
			if (!blockedTools?.has(toolName)) continue;

			const msg = (rule.blockMessage ?? "Access denied").replace("{file}", targetPath);
			ctx.ui.notify(`⛔ ${msg} (${rule.id})`, "error");
			return { block: true, reason: msg };
		}
	});
}

// ── Extension Entry ───────────────────────────────────────────────────────────

export default function register(pi: ExtensionAPI): void {
	const config = loadConfig();

	if (!config.enabled) return;

	pi.on("session_start", () => {
		const message = `[security-guard] Active — ${config.permissionGate.patterns.length} command rules, ${config.policies.rules.length} file policies`;
		pi.logger?.info?.(message);
	});

	setupPermissionGate(pi, config);
	setupPolicies(pi, config);
}
