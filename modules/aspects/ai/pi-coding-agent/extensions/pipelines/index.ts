// extensions/pipelines/index.ts
// pi-pipelines: interactive subagents + gated dependency pipelines.
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { StringEnum, Type } from "@mariozechner/pi-ai";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { discoverAgents } from "./agents.ts";
import { currentBackend, getRun, listRuns, resumePaneRun, spawnRun, type ResolvedSpawn } from "./backends.ts";
import { registerCommands } from "./commands.ts";
import { loadConfig, resolveModel } from "./config.ts";
import { aggregateText, PipelineEngine, type PipelineHooks, type PipelineState, type StageSpec, type StageState } from "./pipeline.ts";
import { buildResearchTask, chooseResearchAgent } from "./research.ts";
import { savePipeline } from "./store.ts";
import type { CompletionResult, RunHandle } from "./types.ts";
import { registerWidget, type WidgetModel } from "./widget.ts";

const EXT_DIR = dirname(fileURLToPath(import.meta.url));
const CHILD_EXT = join(EXT_DIR, "child.ts");
const THINKING_LEVELS = ["off", "minimal", "low", "medium", "high", "xhigh", "max"] as const;

function clip(text: string, n = 8000): string {
  return text.length > n ? `${text.slice(0, n)}\n…(truncated ${text.length - n} chars)` : text;
}

function agentRoot(): string {
  return process.env.PI_CODING_AGENT_DIR ?? join(homedir(), ".pi", "agent");
}

function skillPath(skillName: string): string {
  if (skillName.startsWith("/")) return skillName;
  return join(agentRoot(), "skills", skillName, "SKILL.md");
}

function extensionPath(extensionName: string): string {
  if (extensionName.startsWith("/")) return extensionName;
  return join(agentRoot(), "extensions", extensionName);
}

function newId(prefix: string): string {
  return `${prefix}-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`;
}

type StandaloneSteer = "always" | "pane-only" | "never";

interface RunMeta {
  handle: RunHandle;
  req: ResolvedSpawn;
  stageLabel?: string; // `${pipelineId}:${stageId}` when spawned by a pipeline
  retainedPing?: boolean;
}

export default function pipelinesExtension(pi: ExtensionAPI): void {
  const cwd = process.cwd();
  const agents = discoverAgents(cwd);
  const cfg = loadConfig();
  const byName = new Map(agents.map((agent) => [agent.name, agent]));
  const runs = new Map<string, RunMeta>();

  function steer(kind: string, text: string, details?: Record<string, unknown>): void {
    try {
      pi.sendMessage(
        { customType: "pipelines", content: text, display: true, details: { kind, ...details } },
        { triggerTurn: true, deliverAs: "steer" },
      );
    } catch {
      // Steering is advisory; do not break child/pipeline completion if pi rejects it during teardown.
    }
  }

  function makeResolved(
    id: string,
    opts: {
      name: string;
      agentName?: string;
      task: string;
      model?: string;
      thinking?: string;
      tools?: string[];
      skills?: string[];
      extensions?: string[];
      systemPromptAppend?: string;
      autoExit?: boolean;
      sessionPath?: string;
    },
  ): ResolvedSpawn {
    const agent = opts.agentName ? byName.get(opts.agentName) : undefined;
    if (opts.agentName && !agent) {
      throw new Error(`Unknown agent "${opts.agentName}". Available: ${agents.map((a) => a.name).join(", ")}`);
    }
    return {
      id,
      name: opts.name,
      agentName: opts.agentName ?? agent?.name,
      agent,
      task: opts.task,
      cwd: agent?.cwd ?? cwd,
      harness: agent?.cli ?? "pi",
      model: resolveModel(cfg, opts.agentName, agent?.model, opts.model, undefined),
      thinking: opts.thinking ?? agent?.thinking,
      tools: opts.tools ?? agent?.tools,
      skills: (opts.skills ?? agent?.skills)?.map(skillPath),
      extensions: (opts.extensions ?? agent?.extensions)?.map(extensionPath),
      systemPromptAppend: opts.systemPromptAppend,
      autoExit: opts.autoExit ?? agent?.autoExit ?? true,
      childExtPath: CHILD_EXT,
      sessionPath: opts.sessionPath,
    };
  }

  function steerResultStandalone(id: string, handle: RunHandle, result: CompletionResult): void {
    if (result.reason === "ping") {
      steer(
        "help",
        `Subagent "${handle.name}" needs help: ${result.ping?.message ?? ""}\nResume with subagent_resume({ id: "${id}", message: "..." })`,
        { runId: id },
      );
      return;
    }
    if (result.reason === "error") {
      steer("failure", `Subagent "${handle.name}" FAILED: ${result.errorMessage ?? "unknown error"}`, { runId: id });
      return;
    }
    steer("result", `Subagent "${handle.name}" done:\n${result.output ?? ""}`, {
      runId: id,
      backend: handle.backend,
      sessionPath: handle.sessionPath,
    });
  }

  function shouldSteerStandalone(policy: StandaloneSteer, handle: RunHandle): boolean {
    return policy === "always" || (policy === "pane-only" && handle.backend === "pane");
  }

  function watchCompletion(
    handle: RunHandle,
    req: ResolvedSpawn,
    stageLabel?: string,
    standaloneSteer: StandaloneSteer = "pane-only",
  ): void {
    runs.set(handle.id, { handle, req, stageLabel });
    handle.completion
      .then((result) => {
        if (runs.get(handle.id)?.handle !== handle) return;
        if (!stageLabel) {
          if (shouldSteerStandalone(standaloneSteer, handle)) steerResultStandalone(handle.id, handle, result);
          if (result.reason === "ping") runs.set(handle.id, { handle, req, retainedPing: true });
          else runs.delete(handle.id);
          return;
        }
        const split = stageLabel.indexOf(":");
        if (split > 0) engine.complete(stageLabel.slice(0, split), stageLabel.slice(split + 1), result);
        runs.delete(handle.id);
      })
      .catch((error) => {
        if (runs.get(handle.id)?.handle !== handle) return;
        const message = error instanceof Error ? error.message : String(error);
        if (!stageLabel) {
          if (shouldSteerStandalone(standaloneSteer, handle)) steer("failure", `Subagent "${handle.name}" FAILED: ${message}`, { runId: handle.id });
          runs.delete(handle.id);
          return;
        }
        const split = stageLabel.indexOf(":");
        if (split > 0) {
          engine.complete(stageLabel.slice(0, split), stageLabel.slice(split + 1), {
            reason: "error",
            exitCode: 1,
            errorMessage: message,
          });
        }
        runs.delete(handle.id);
      });
  }

  function launch(id: string, opts: Parameters<typeof makeResolved>[1], stageLabel?: string, standaloneSteer: StandaloneSteer = "pane-only"): RunHandle {
    const req = makeResolved(id, opts);
    const handle = spawnRun(req);
    watchCompletion(handle, req, stageLabel, standaloneSteer);
    return handle;
  }

  function stageLabelOf(pipelineId: string, stageId: string): string {
    return `${pipelineId}:${stageId}`;
  }

  function findStageRunMeta(pipelineId: string, stageId: string): [string, RunMeta] | undefined {
    const label = stageLabelOf(pipelineId, stageId);
    return [...runs.entries()].find(([, meta]) => meta.stageLabel === label && !meta.retainedPing);
  }

  function cancelPipeline(id: string): boolean {
    const pipeline = engine.get(id);
    if (!pipeline || pipeline.status !== "active") return false;
    const prefix = `${id}:`;
    for (const [runId, meta] of runs.entries()) {
      if (!meta.stageLabel?.startsWith(prefix)) continue;
      runs.delete(runId);
      void meta.handle.interrupt().catch(() => {});
    }
    engine.cancel(id);
    return true;
  }

  const hooks: PipelineHooks = {
    spawn(p: PipelineState, s: StageState): void {
      launch(
        `${p.id}-${s.id}-${s.attempt}`,
        { name: s.id, agentName: s.agent, task: s.task, autoExit: true },
        `${p.id}:${s.id}`,
      );
    },
    notify(p: PipelineState): void {
      savePipeline(p);
      if (p.status !== "active") setTimeout(() => savePipeline(p), 0);
    },
    steer(p: PipelineState, s: StageState | undefined, kind, text): void {
      if (currentBackend() === "headless") return;
      if (kind === "gate" && s) {
        steer(
          "gate",
          `Gate "${s.id}" in pipeline "${p.name}" is waiting for your go-ahead.\n\n${clip(text, 2000)}\n\nProceed with subagent_resume({ pipelineId: "${p.id}", stageId: "${s.id}" }) when ready.`,
          { pipelineId: p.id, stageId: s.id },
        );
        return;
      }
      steer(kind, text, { pipelineId: p.id, stageId: s?.id });
    },
    gatePrompt(): void {
      // PipelineEngine already emits hooks.steer(..., "gate", ...); avoid duplicate prompts.
    },
  };
  const engine = new PipelineEngine(hooks);

  const widgetModel = (): WidgetModel => ({
    pipelines: engine.list(),
    runs: [...runs.values()].filter((run) => !run.retainedPing).map((run) => ({ handle: run.handle, stageLabel: run.stageLabel })),
  });
  registerWidget(pi, widgetModel, { collapsedDefault: cfg.widget?.collapsed ?? false });

  pi.registerTool({
    name: "subagent_spawn",
    label: "Subagent Spawn",
    description:
      "Spawn a subagent to work on a task. In herdr it runs in a live pane; outside herdr it runs headless. Results steer back unless await_result is true.",
    parameters: Type.Object({
      name: Type.Optional(Type.String({ description: "Display name for the run (default: agent name)" })),
      agent: Type.Optional(Type.String({ description: "Agent definition name (see subagents_list)" })),
      task: Type.String({ description: "Complete task instructions for the subagent" }),
      model: Type.Optional(Type.String({ description: "Model override" })),
      thinking: Type.Optional(StringEnum(THINKING_LEVELS)),
      tools: Type.Optional(Type.String({ description: "Comma-separated tool allowlist" })),
      await_result: Type.Optional(Type.Boolean({ description: "Wait for completion and return the result" })),
    }),
    async execute(_toolCallId, params, _signal, onUpdate) {
      const agentName = params.agent ?? "scout";
      const id = newId("run");
      const standaloneSteer: StandaloneSteer = params.await_result === true ? "never" : params.await_result === false ? "always" : "pane-only";
      const handle = launch(id, {
        name: params.name ?? agentName,
        agentName,
        task: params.task,
        model: params.model,
        thinking: params.thinking,
        tools: params.tools?.split(",").map((tool) => tool.trim()).filter(Boolean),
      }, undefined, standaloneSteer);
      const wantResult = params.await_result ?? handle.backend === "headless";
      if (!wantResult) {
        return {
          content: [{ type: "text" as const, text: `Spawned "${handle.name}" (${handle.id}) in ${handle.backend} mode. Results steer back on completion.` }],
          details: { id: handle.id, backend: handle.backend },
        };
      }
      onUpdate?.({ content: [{ type: "text", text: `waiting for ${handle.name}…` }] });
      const result = await handle.completion;
      if (result.reason === "ping") {
        return {
          content: [{ type: "text" as const, text: `Subagent needs help: ${result.ping?.message ?? ""}` }],
          details: { id: handle.id, backend: handle.backend, sessionPath: handle.sessionPath, ping: result.ping },
        };
      }
      return {
        content: [{ type: "text" as const, text: result.reason === "error" ? `Subagent failed: ${result.errorMessage ?? "unknown error"}` : clip(result.output ?? "(no output)") }],
        isError: result.reason === "error",
        details: { id: handle.id, backend: handle.backend, sessionPath: handle.sessionPath },
      };
    },
  });

  pi.registerTool({
    name: "pipeline",
    label: "Pipeline",
    description:
      "Declare a dependency graph of subagent stages and return immediately. gate:true stages pause for a user go-ahead via subagent_resume.",
    parameters: Type.Object({
      name: Type.String({ description: "Pipeline display name" }),
      stages: Type.Array(
        Type.Object({
          id: Type.String({ description: "Unique stage id" }),
          agent: Type.Optional(Type.String({ description: "Agent definition name (omit for gate stages)" })),
          task: Type.String({ description: "Task for this stage" }),
          dependsOn: Type.Optional(Type.Array(Type.String(), { description: "Stage ids that must complete first" })),
          gate: Type.Optional(Type.Boolean({ description: "Pause for user go-ahead after dependencies complete" })),
        }),
        { minItems: 1 },
      ),
    }),
    async execute(_toolCallId, params) {
      const specs = params.stages as StageSpec[];
      const unknownAgents = [...new Set(specs.map((stage) => stage.agent).filter((agent): agent is string => !!agent && !byName.has(agent)))];
      if (unknownAgents.length > 0) {
        return {
          content: [{ type: "text" as const, text: `Unknown stage agent(s): ${unknownAgents.join(", ")}. Available: ${agents.map((agent) => agent.name).join(", ")}` }],
          isError: true,
        };
      }
      let pipeline: PipelineState;
      try {
        pipeline = engine.create(newId("pl"), params.name, specs);
        engine.start(pipeline.id);
      } catch (error) {
        return {
          content: [{ type: "text" as const, text: `Pipeline rejected: ${error instanceof Error ? error.message : String(error)}` }],
          isError: true,
        };
      }
      if (currentBackend() === "headless") {
        for (;;) {
          const latest = engine.get(pipeline.id) ?? pipeline;
          const waiting = latest.stages.find((stage) => stage.status === "waiting-gate" || stage.status === "waiting-help");
          if (latest.status !== "active" || waiting) {
            const text = waiting
              ? `Pipeline "${params.name}" (${pipeline.id}) is waiting at ${waiting.id}.\n${aggregateText(latest)}`
              : aggregateText(latest);
            return { content: [{ type: "text" as const, text }], details: { id: pipeline.id, status: latest.status } };
          }
          await new Promise((resolve) => setTimeout(resolve, 250));
        }
      }
      const table = pipeline.stages
        .map((stage) => `  ${stage.id}: ${stage.status}${stage.agent ? ` (agent: ${stage.agent})` : " (gate)"}`)
        .join("\n");
      return {
        content: [{ type: "text" as const, text: `Pipeline "${params.name}" (${pipeline.id}) started. Stages steer back as they complete.\n${table}` }],
        details: { id: pipeline.id },
      };
    },
  });

  pi.registerTool({
    name: "pipeline_cancel",
    label: "Pipeline Cancel",
    description: "Cancel a running pipeline and halt any unsettled stages.",
    parameters: Type.Object({
      pipelineId: Type.String({ description: "Pipeline id to cancel" }),
    }),
    async execute(_toolCallId, params) {
      return cancelPipeline(params.pipelineId)
        ? { content: [{ type: "text" as const, text: `Cancelled pipeline "${params.pipelineId}".` }] }
        : { content: [{ type: "text" as const, text: `No active pipeline "${params.pipelineId}" to cancel.` }], isError: true };
    },
  });

  pi.registerTool({
    name: "subagent_interrupt",
    label: "Subagent Interrupt",
    description: "Interrupt a running subagent's current turn. The session stays open and resumable.",
    parameters: Type.Object({
      id: Type.Optional(Type.String({ description: "Run id from subagents_list" })),
      pipelineId: Type.Optional(Type.String()),
      stageId: Type.Optional(Type.String()),
    }),
    async execute(_toolCallId, params) {
      let id = params.id;
      if (!id && params.pipelineId && params.stageId) {
        const pipeline = engine.get(params.pipelineId);
        const stage = pipeline?.stages.find((candidate) => candidate.id === params.stageId);
        const live = findStageRunMeta(params.pipelineId, params.stageId);
        if (live) {
          id = live[0];
        } else if (stage?.status === "running") {
          return {
            content: [{ type: "text" as const, text: `Stage "${stage.id}" is marked running but has no live run. Resume it to relaunch the orphaned stage.` }],
            isError: true,
          };
        }
      }
      const handle = id ? runs.get(id)?.handle : undefined;
      if (!handle) return { content: [{ type: "text" as const, text: `No run found for ${id ?? "given args"}.` }], isError: true };
      if (handle.backend === "headless") {
        return {
          content: [{ type: "text" as const, text: `Run ${id} is headless; interrupt would terminate it and cannot be resumed by id.` }],
          isError: true,
        };
      }
      await handle.interrupt();
      return { content: [{ type: "text" as const, text: `Interrupted "${handle.name}" (${id}). Session remains resumable.` }] };
    },
  });

  pi.registerTool({
    name: "subagent_resume",
    label: "Subagent Resume",
    description: "Resume a standalone pane run, pass a pipeline gate, or answer a waiting-help stage.",
    parameters: Type.Object({
      id: Type.Optional(Type.String({ description: "Run id (standalone run)" })),
      pipelineId: Type.Optional(Type.String()),
      stageId: Type.Optional(Type.String()),
      sessionPath: Type.Optional(Type.String({ description: "Child session file to continue" })),
      message: Type.Optional(Type.String({ description: "Guidance for the resumed child" })),
    }),
    async execute(_toolCallId, params) {
      if (params.pipelineId && params.stageId) {
        const pipeline = engine.get(params.pipelineId);
        const stage = pipeline?.stages.find((candidate) => candidate.id === params.stageId);
        if (!pipeline || !stage) return { content: [{ type: "text" as const, text: `No stage ${params.stageId} in ${params.pipelineId}.` }], isError: true };
        if (stage.status === "waiting-gate") {
          engine.proceedGate(params.pipelineId, params.stageId);
          return { content: [{ type: "text" as const, text: `Gate "${stage.id}" passed; pipeline continues.` }] };
        }
        if (stage.status === "waiting-help") {
          engine.resumeHelped(params.pipelineId, params.stageId, params.message);
          return { content: [{ type: "text" as const, text: `Resuming stage "${stage.id}" with your guidance.` }] };
        }
        if (stage.status === "running") {
          const live = findStageRunMeta(params.pipelineId, params.stageId);
          if (!live) {
            engine.resumeRunning(params.pipelineId, params.stageId, params.message);
            return { content: [{ type: "text" as const, text: `Relaunched orphaned stage "${stage.id}".` }] };
          }
          const [runId, meta] = live;
          const resumed = resumePaneRun(runId, params.message ?? "continue");
          if (resumed) {
            runs.delete(runId);
            const req: ResolvedSpawn = {
              ...meta.req,
              id: resumed.id,
              task: params.message ?? "continue",
              sessionPath: resumed.sessionPath ?? meta.req.sessionPath,
            };
            watchCompletion(resumed, req, stageLabelOf(params.pipelineId, params.stageId));
            return { content: [{ type: "text" as const, text: `Resumed stage "${stage.id}" in its pane (${resumed.id}).` }] };
          }
          if (meta.handle.sessionPath) {
            const req: ResolvedSpawn = {
              ...meta.req,
              id: `${meta.req.id}-r${Date.now().toString(36)}`,
              task: params.message ?? "continue",
              sessionPath: meta.handle.sessionPath,
            };
            const handle = spawnRun(req);
            runs.delete(runId);
            watchCompletion(handle, req, stageLabelOf(params.pipelineId, params.stageId));
            return { content: [{ type: "text" as const, text: `Resumed stage "${stage.id}" in ${handle.backend} mode (${handle.id}).` }] };
          }
        }
        return { content: [{ type: "text" as const, text: `Stage "${stage.id}" is ${stage.status} — nothing to resume.` }], isError: true };
      }

      if (params.id) {
        const meta = runs.get(params.id);
        const resumed = resumePaneRun(params.id, params.message ?? "continue");
        if (resumed && meta) {
          runs.delete(params.id);
          watchCompletion(resumed, { ...meta.req, id: resumed.id, task: params.message ?? "continue" }, undefined, "always");
          return { content: [{ type: "text" as const, text: `Resumed "${resumed.name}" in its pane (${resumed.id}).` }] };
        }
        if (meta?.handle.sessionPath) {
          const req: ResolvedSpawn = {
            ...meta.req,
            id: newId("run"),
            task: params.message ?? "continue",
            sessionPath: meta.handle.sessionPath,
          };
          const handle = spawnRun(req);
          runs.delete(params.id);
          watchCompletion(handle, req, undefined, "always");
          return { content: [{ type: "text" as const, text: `Resumed session in ${handle.backend} mode (${handle.id}).` }] };
        }
      }

      if (params.sessionPath) {
        const handle = launch(newId("run"), {
          name: "resumed",
          task: params.message ?? "continue the task",
          sessionPath: params.sessionPath,
        }, undefined, "always");
        return { content: [{ type: "text" as const, text: `Resumed session in ${handle.backend} mode (${handle.id}).` }] };
      }
      if (params.id) {
        const rec = getRun(params.id);
        if (rec?.handle.sessionPath) {
          const req: ResolvedSpawn = {
            ...rec.req,
            id: newId("run"),
            task: params.message ?? "continue the task",
            sessionPath: rec.handle.sessionPath,
          };
          const handle = spawnRun(req);
          watchCompletion(handle, req, undefined, "always");
          return { content: [{ type: "text" as const, text: `Resumed session in ${handle.backend} mode (${handle.id}).` }] };
        }
        return { content: [{ type: "text" as const, text: `Run ${params.id} is not a resumable pane run and has no sessionPath.` }], isError: true };
      }
      return { content: [{ type: "text" as const, text: "Provide id, sessionPath, or pipelineId+stageId." }], isError: true };
    },
  });

  pi.registerTool({
    name: "subagents_list",
    label: "Subagents List",
    description: "List agent definitions, active runs, and active pipelines.",
    parameters: Type.Object({}),
    async execute() {
      const lines: string[] = [];
      lines.push("Agents:", ...agents.map((agent) => `  ${agent.name} [${agent.source}] — ${agent.description}`));
      const backendRuns = listRuns();
      const seen = new Set(backendRuns.map((run) => run.handle.id));
      const retainedPings = [...runs.values()].filter((run) => run.retainedPing && !seen.has(run.handle.id));
      const active = [
        ...backendRuns.map((run) => `  ${run.handle.id} ${run.handle.name} (${run.handle.backend})`),
        ...retainedPings.map((run) => `  ${run.handle.id} ${run.handle.name} (${run.handle.backend}, pinged)`),
      ];
      lines.push("Runs:", ...(active.length ? active : ["  (none)"]));
      lines.push("Pipelines:", ...(engine.list().length ? engine.list().map((pipeline) => `  ${pipeline.id} "${pipeline.name}" (${pipeline.status})`) : ["  (none)"]));
      return { content: [{ type: "text" as const, text: lines.join("\n") }] };
    },
  });

  pi.registerTool({
    name: "subagent_research",
    label: "Subagent Research",
    description: "Run a research subagent and return its supervisor summary. Always waits for the result.",
    parameters: Type.Object({
      task: Type.String({ description: "Research question or scouting task" }),
      agent: Type.Optional(Type.String({ description: "Agent to use (default: auto-pick from task)" })),
    }),
    async execute(_toolCallId, params, _signal, onUpdate) {
      const picked = params.agent ?? chooseResearchAgent(params.task) ?? "scout";
      const agentName = !params.agent && (picked === "reviewer" || !byName.has(picked)) ? "scout" : picked;
      const handle = launch(newId("run"), {
        name: `research-${agentName}`,
        agentName,
        task: buildResearchTask(params.task),
      }, undefined, "never");
      onUpdate?.({ content: [{ type: "text", text: `research running via ${agentName}…` }] });
      const result = await handle.completion;
      if (result.reason === "ping") {
        return {
          content: [{ type: "text" as const, text: `Research subagent needs help: ${result.ping?.message ?? ""}` }],
          details: { agent: agentName, id: handle.id, sessionPath: handle.sessionPath, ping: result.ping },
        };
      }
      return {
        content: [{ type: "text" as const, text: result.reason === "error" ? `Research failed: ${result.errorMessage ?? "unknown error"}` : clip(result.output ?? "(no output)") }],
        isError: result.reason === "error",
        details: { agent: agentName, id: handle.id, sessionPath: handle.sessionPath },
      };
    },
  });

  const sub = async (agentName: string, task: string): Promise<string> => {
    const handle = launch(newId("run"), { name: agentName, agentName, task });
    if (handle.backend === "headless") {
      const result = await handle.completion;
      if (result.reason === "ping") {
        return `NEEDS HELP (${handle.id}): ${result.ping?.message ?? ""}\nResume with subagent_resume({ id: "${handle.id}", message: "..." })`;
      }
      return result.reason === "error" ? `FAILED: ${result.errorMessage ?? "unknown error"}` : clip(result.output ?? "(no output)");
    }
    return `Spawned "${agentName}" (${handle.id}) in a pane; results steer back on completion.`;
  };

  function startPlanPreset(goal: string): string {
    const id = newId("pl");
    const planner = byName.has("planner") ? "planner" : "scout";
    const worker = byName.has("worker") ? "worker" : "coder";
    const reviewer = byName.has("adversarial-qa") ? "adversarial-qa" : byName.has("reviewer") ? "reviewer" : "scout";
    const tester = byName.has("test-automation-engineer") ? "test-automation-engineer" : byName.has("visual-tester") ? "visual-tester" : "scout";
    engine.create(id, goal.slice(0, 24) || "plan", [
      {
        id: "plan",
        agent: planner,
        task: `Produce an implementation plan for: ${goal}\n\nOutput: 1) one-paragraph approach, 2) numbered todos (max 15, each concrete and verifiable), 3) top-3 risks.`,
      },
      { id: "confirm", gate: true, task: "Review the plan with the user before implementation.", dependsOn: ["plan"] },
      {
        id: "implement",
        agent: worker,
        task: `Implement the approved plan for: ${goal}\n\nPlan/context:\n{stage:plan}`,
        dependsOn: ["confirm"],
      },
      {
        id: "review",
        agent: reviewer,
        task: `Review the implementation for: ${goal}\n\nImplementation summary:\n{stage:implement}`,
        dependsOn: ["implement"],
      },
      {
        id: "test",
        agent: tester,
        task: `Verify/test the implementation for: ${goal}\n\nReview notes:\n{stage:review}`,
        dependsOn: ["review"],
      },
    ]);
    engine.start(id);
    return id;
  }

  function startIteratePreset(instruction: string): string {
    const id = newId("pl");
    const worker = byName.has("worker") ? "worker" : "coder";
    const reviewer = byName.has("adversarial-qa") ? "adversarial-qa" : byName.has("reviewer") ? "reviewer" : "scout";
    engine.create(id, `iterate: ${instruction}`.slice(0, 24), [
      { id: "fix", agent: worker, task: instruction },
      {
        id: "review",
        agent: reviewer,
        task: `Review this quick fix and report issues only:\n{stage:fix}`,
        dependsOn: ["fix"],
      },
    ]);
    engine.start(id);
    return id;
  }

  registerCommands(pi, {
    agents,
    listPipelines: () => engine.list(),
    cancelPipeline,
    startPlanPreset,
    startIteratePreset,
    sub,
  });

  (globalThis as { __pipelinesStartPlan?: (goal: { goal: string }) => string }).__pipelinesStartPlan = ({ goal }) =>
    startPlanPreset(goal);
}
