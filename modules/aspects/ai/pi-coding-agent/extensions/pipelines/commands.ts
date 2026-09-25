// extensions/pipelines/commands.ts
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import type { PipelineState } from "./pipeline.ts";
import type { AgentConfig } from "./types.ts";

export interface CommandDeps {
	agents: AgentConfig[];
	listPipelines: () => PipelineState[];
	cancelPipeline: (id: string) => boolean;
	startPlanPreset: (goal: string) => string;
	startIteratePreset: (instruction: string) => string;
	sub: (agent: string, task: string) => Promise<string>;
	startBtw: (question: string, sessionFile?: string) => string;
	closeBtw: () => boolean;
}

function agentLines(agents: AgentConfig[]): string[] {
	const bySource: Record<AgentConfig["source"], AgentConfig[]> = {
		project: [],
		user: [],
		bundled: [],
	};
	for (const agent of agents) bySource[agent.source]?.push(agent);

	const lines = ["Agents:"];
	for (const source of ["project", "user", "bundled"] as const) {
		for (const agent of bySource[source]) {
			const cli = agent.cli && agent.cli !== "pi" ? ` (cli:${agent.cli})` : "";
			lines.push(`  [${source}] ${agent.name}${cli} — ${agent.description || "(no description)"}`);
		}
	}
	return lines;
}

function pipelineLines(pipeline: PipelineState): string[] {
	const rows = pipeline.stages.map((stage) => {
		const tail = stage.status === "failed"
			? ` — ${stage.error ?? "failed"}`
			: stage.status === "done"
				? ` — ${(stage.result ?? "").slice(0, 60)}`
				: "";
		return `  ${stage.id} [${stage.status}]${tail}`;
	});
	return [`Pipeline ${pipeline.id} "${pipeline.name}" (${pipeline.status}):`, ...rows];
}

export function registerCommands(pi: ExtensionAPI, deps: CommandDeps): void {
	pi.registerCommand("agents", {
		description: "List available subagent definitions",
		handler: async (_args: string, ctx: any) => {
			ctx.ui.notify(agentLines(deps.agents).join("\n"), "info");
		},
	});

	pi.registerCommand("sub", {
		description: "Spawn a subagent: /sub <agent> <task>",
		handler: async (args: string, ctx: any) => {
			const [agent, ...rest] = args.trim().split(/\s+/);
			const task = rest.join(" ").trim();
			if (!agent || !task) {
				ctx.ui.notify("Usage: /sub <agent> <task>", "warning");
				return;
			}
			ctx.ui.notify(await deps.sub(agent, task), "info");
		},
	});

	pi.registerCommand("pipeline", {
		description: "List active pipelines, inspect one, or cancel one: /pipeline [id] | /pipeline cancel <id>",
		handler: async (args: string, ctx: any) => {
			const trimmed = args.trim();
			if (trimmed.startsWith("cancel ")) {
				const id = trimmed.slice("cancel ".length).trim();
				if (!id) {
					ctx.ui.notify("Usage: /pipeline cancel <id>", "warning");
					return;
				}
				const cancelled = deps.cancelPipeline(id);
				ctx.ui.notify(
					cancelled ? `Cancelled pipeline "${id}".` : `No active pipeline "${id}" to cancel.`,
					cancelled ? "info" : "warning",
				);
				return;
			}
			const id = trimmed;
			const pipelines = deps.listPipelines();
			if (id) {
				const pipeline = pipelines.find((p) => p.id === id);
				ctx.ui.notify(pipeline ? pipelineLines(pipeline).join("\n") : `No pipeline "${id}"`, pipeline ? "info" : "warning");
				return;
			}

			const active = pipelines.filter((p) => p.status === "active");
			if (active.length === 0) {
				ctx.ui.notify("No active pipelines. Start one via the pipeline tool or /plan <goal>.", "info");
				return;
			}
			ctx.ui.notify(active.flatMap(pipelineLines).join("\n"), "info");
		},
	});

	pi.registerCommand("btw", {
		description: "Ask a side question in a Herdr side pane: /btw <question>",
		handler: async (args: string, ctx: any) => {
			try {
				const id = deps.startBtw(args, ctx.sessionManager?.getSessionFile?.());
				ctx.ui.notify(
					`Opened /btw side thread (${id}). Run /btw-merge <prompt> in that pane to fold it back.`,
					"info",
				);
			} catch (error) {
				ctx.ui.notify(error instanceof Error ? error.message : String(error), "warning");
			}
		},
	});

	pi.registerCommand("btw-close", {
		description: "Close the current /btw side thread",
		handler: async (_args: string, ctx: any) => {
			ctx.ui.notify(deps.closeBtw() ? "Closed /btw side thread." : "No /btw side thread is open.", "info");
		},
	});

	pi.registerCommand("iterate", {
		description: "Quick surgical fix by a worker subagent: /iterate <instruction>",
		handler: async (args: string, ctx: any) => {
			const instruction = args.trim();
			if (!instruction) {
				ctx.ui.notify("Usage: /iterate <instruction>", "warning");
				return;
			}
			const id = deps.startIteratePreset(instruction);
			ctx.ui.notify(`Started quick-fix pipeline ${id}`, "info");
		},
	});
}
