import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth, wrapTextWithAnsi } from "@mariozechner/pi-tui";

const mocha = {
	lavender: "180;190;254",
	green: "166;227;161",
	yellow: "249;226;175",
	peach: "250;179;135",
	red: "243;139;168",
	sky: "137;220;235",
	text: "205;214;244",
	overlay: "88;91;112",
	surface: "49;50;68",
	crust: "17;17;27",
};

export interface FooterStats {
	branch?: string | null;
	sessionName?: string;
	modelId: string;
	thinkingLevel?: string;
	used: number | null;
	total: number;
	quotaStatus?: string;
}

function fg(color: keyof typeof mocha, text: string): string {
	return `\x1b[38;2;${mocha[color]}m${text}\x1b[0m`;
}

function clean(text: string): string {
	return text.replace(/[\x00-\x1f\x7f-\x9f]/g, " ").replace(/\s+/g, " ").trim();
}

function tab(icon: string, text: string): string {
	return fg("lavender", "")
		+ `\x1b[48;2;${mocha.lavender}m\x1b[38;2;${mocha.crust}m\x1b[1m ${icon} \x1b[0m`
		+ `\x1b[48;2;${mocha.surface}m\x1b[38;2;${mocha.text}m ${text} \x1b[0m`
		+ fg("surface", "");
}

const separator = fg("overlay", " │ ");

function fmtK(n: number): string {
	return `${Math.round(n / 1000)}k`;
}

function wrap(text: string, width: number): string[] {
	return wrapTextWithAnsi(text, width).map(line => truncateToWidth(line, width, ""));
}

export function renderFooterLines(data: FooterStats, width: number): string[] {
	if (width <= 0) return [];
	const pct = data.used === null ? null : Math.max(0, Math.min(100, data.total > 0 ? data.used / data.total * 100 : 0));
	const color = pct === null ? "sky" : pct >= 90 ? "red" : pct >= 70 ? "peach" : pct >= 40 ? "yellow" : "green";
	const filled = pct === null ? 0 : Math.floor(pct / 10);
	const bar = fg(color, "▓".repeat(filled)) + fg("overlay", "░".repeat(10 - filled));
	const usedLabel = data.used === null ? "--" : fmtK(data.used);
	const context = `${fg(color, "")} ${bar} ${fg(color, `${usedLabel}/${fmtK(data.total)}`)}`;
	const thinking = data.thinkingLevel && data.thinkingLevel !== "off" ? ` ·${clean(data.thinkingLevel)}` : "";
	const model = fg("lavender", `󰚩 ${clean(data.modelId)}${thinking}`);
	const stats = [context, data.quotaStatus, model].filter((part): part is string => Boolean(part));
	const right = stats.join(separator);
	const names = [
		{ icon: "", text: clean(data.branch ?? "") },
		{ icon: "", text: clean(data.sessionName ?? "") },
	].filter(name => name.text);
	const left = names.map(name => tab(name.icon, name.text)).join(" ");
	const gap = width - visibleWidth(left) - visibleWidth(right);
	if (gap >= 1) return [left ? `${left}${" ".repeat(gap)}${right}` : right];

	const lines: string[] = [];
	if (left && visibleWidth(left) <= width) {
		lines.push(left);
	} else {
		const name = names.find(name => name.icon === "") ?? names[0];
		if (name) {
			const bodyWidth = width - visibleWidth(tab(name.icon, ""));
			lines.push(...(bodyWidth > 0
				? wrap(name.text, bodyWidth).map(part => tab(name.icon, part))
				: wrap(name.text, width)));
		}
	}
	let line = "";
	for (const part of stats) {
		const next = line ? `${line}${separator}${part}` : part;
		if (visibleWidth(next) <= width) {
			line = next;
		} else {
			if (line) lines.push(line);
			const wrapped = wrap(part, width);
			lines.push(...wrapped.slice(0, -1));
			line = wrapped.at(-1) ?? "";
		}
	}
	if (line) lines.push(line);
	return lines;
}

export default function statusline(pi: ExtensionAPI) {
	let enabled = false;

	function buildFooter(ctx: ExtensionContext) {
		let currentCtx = ctx;
		return (tui: { requestRender(): void }, _theme: unknown, footerData: {
			getGitBranch(): string | null;
			getExtensionStatuses(): ReadonlyMap<string, string>;
			onBranchChange(callback: () => void): () => void;
		}) => {
			const refresh = (_event: unknown, nextCtx: ExtensionContext) => {
				currentCtx = nextCtx;
				tui.requestRender();
			};
			const unsub = [
				pi.on("turn_start", refresh),
				pi.on("turn_end", refresh),
				pi.on("model_select", refresh),
				pi.on("session_info_changed", refresh),
				footerData.onBranchChange(() => tui.requestRender()),
			];
			return {
				dispose() { unsub.forEach(fn => fn()); },
				invalidate() {},
				render(width: number): string[] {
					const usage = currentCtx.getContextUsage();
					return renderFooterLines({
						used: usage?.tokens ?? null,
						total: usage?.contextWindow ?? currentCtx.model?.contextWindow ?? 128000,
						branch: footerData.getGitBranch(),
						sessionName: pi.getSessionName(),
						modelId: currentCtx.model?.id || "no-model",
						thinkingLevel: pi.getThinkingLevel(),
						quotaStatus: footerData.getExtensionStatuses().get("provider-quota"),
					}, width);
				},
			};
		};
	}

	pi.registerCommand("statusline", {
		description: "Toggle statusline footer bar",
		handler: async (_args: string, ctx: ExtensionContext) => {
			enabled = !enabled;
			ctx.ui.setFooter(enabled ? buildFooter(ctx) : undefined);
			ctx.ui.notify(enabled ? "Statusline enabled" : "Default footer restored", "info");
		},
	});

	pi.on("session_start", async (_event, ctx) => {
		if (!ctx.hasUI) return;
		enabled = true;
		ctx.ui.setFooter(buildFooter(ctx));
	});
}
