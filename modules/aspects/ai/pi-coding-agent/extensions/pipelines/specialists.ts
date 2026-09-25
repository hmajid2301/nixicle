// extensions/pipelines/specialists.ts
// Persistent-specialist tools: send a follow-up task to a retained run, or stop it.
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@mariozechner/pi-ai";
import type { ResolvedSpawn } from "./backends.ts";
import type { RunHandle } from "./types.ts";

export interface SpecialistRun {
  req: ResolvedSpawn;
  handle: RunHandle;
  /** True only once the run has settled and its pane is free to resume. */
  retained?: boolean;
}

export interface SpecialistDeps {
  find(idOrName: string | undefined): { runId: string; run: SpecialistRun } | undefined;
  send(runId: string, run: SpecialistRun, message: string): RunHandle | null;
  stop(runId: string): void;
}

function fail(text: string) {
  return { content: [{ type: "text" as const, text }], isError: true };
}

export function registerSpecialistTools(pi: ExtensionAPI, deps: SpecialistDeps): void {
  pi.registerTool({
    name: "subagent_send",
    label: "Subagent Send",
    description: "Deliver a follow-up task to an idle persistent specialist (spawned with persistent: true).",
    parameters: Type.Object({
      id: Type.Optional(Type.String({ description: "Specialist run id or name" })),
      message: Type.String({ description: "Follow-up task" }),
    }),
    async execute(_toolCallId, params) {
      const found = deps.find(params.id);
      if (!found) return fail(`No specialist matches "${params.id ?? ""}".`);
      if (!found.run.req.retainPane) return fail(`Run ${found.runId} is not a persistent specialist.`);
      if (!found.run.retained) return fail(`Run ${found.runId} is still working; wait for it to settle first.`);
      const resumed = deps.send(found.runId, found.run, params.message);
      if (!resumed) return fail(`Specialist ${found.runId} has no resumable pane.`);
      return {
        content: [{ type: "text" as const, text: `Sent to "${resumed.name}" (${resumed.id}). Results steer back on completion.` }],
      };
    },
  });

  pi.registerTool({
    name: "subagent_stop",
    label: "Subagent Stop",
    description: "Stop an idle persistent specialist and close its pane.",
    parameters: Type.Object({
      id: Type.Optional(Type.String({ description: "Specialist run id or name" })),
    }),
    async execute(_toolCallId, params) {
      const found = deps.find(params.id);
      if (!found) return fail(`No specialist matches "${params.id ?? ""}".`);
      if (!found.run.req.retainPane) return fail(`Run ${found.runId} is not a persistent specialist.`);
      if (!found.run.retained) return fail(`Run ${found.runId} is still working; wait for it to settle first.`);
      deps.stop(found.runId);
      return { content: [{ type: "text" as const, text: `Stopped specialist "${found.run.handle.name}" (${found.runId}).` }] };
    },
  });
}
