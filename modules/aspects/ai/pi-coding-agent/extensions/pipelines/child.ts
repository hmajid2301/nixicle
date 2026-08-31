// extensions/pipelines/child.ts
// Loaded into every pi child session via `-e <path>`.
// Reads PI_SUBAGENT_* env; writes the exit sidecar; registers control tools.
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@mariozechner/pi-ai";
import { writeFileSync } from "node:fs";
import {
  buildCompletionSidecar,
  shouldAutoExitOnAgentEnd,
  shouldMarkUserTookOver,
} from "./child-helpers.ts";

const exitFile = process.env.PI_SUBAGENT_EXIT_FILE;
const autoExit = process.env.PI_SUBAGENT_AUTO_EXIT === "1";
const subagentName = process.env.PI_SUBAGENT_NAME ?? "subagent";

let explicitSidecarWritten = false;

function writeExit(payload: unknown, explicit = false): void {
  if (!exitFile) return;
  try {
    writeFileSync(exitFile, JSON.stringify(payload));
    if (explicit) explicitSidecarWritten = true;
  } catch {
    // best effort — parent falls back to the screen sentinel
  }
}

export default function (pi: ExtensionAPI): void {
  let userTookOver = false;
  let agentStarted = false;
  let latest: any[] | undefined;

  pi.on("input", () => {
    if (shouldMarkUserTookOver(agentStarted)) userTookOver = true;
  });

  pi.on("agent_start", () => {
    agentStarted = true;
  });

  pi.on("agent_end", (event: any) => {
    // agent_end is not terminal (compaction retries) — keep latest only.
    latest = event?.messages;
  });

  pi.on("agent_settled", (_event: any, ctx: any) => {
    if (!autoExit) return;
    if (!shouldAutoExitOnAgentEnd(userTookOver, latest)) {
      userTookOver = false;
      return;
    }
    if (!explicitSidecarWritten) writeExit(buildCompletionSidecar(latest));
    ctx.shutdown();
  });

  pi.registerTool({
    name: "caller_ping",
    label: "Caller Ping",
    description:
      "Send a help request to the parent agent, then exit this session. " +
      "The parent is notified and can resume this session with guidance.",
    parameters: Type.Object({
      message: Type.String({ description: "What you need help with" }),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      writeExit({ type: "ping", name: subagentName, message: params.message }, true);
      ctx.shutdown();
      return {
        content: [{ type: "text", text: "Ping sent to parent; session exiting." }],
        terminate: true,
      };
    },
  });

  pi.registerTool({
    name: "subagent_done",
    label: "Subagent Done",
    description:
      "Call when your task is complete. Closes this session. If `output` is " +
      "provided, it is returned to the parent; otherwise the parent falls " +
      "back to the final assistant message from the child session.",
    parameters: Type.Object({
      output: Type.Optional(Type.String({ description: "Optional final result text to return to the parent" })),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      writeExit(
        {
          type: "done",
          output: typeof params.output === "string" ? params.output : undefined,
        },
        true,
      );
      ctx.shutdown();
      return {
        content: [{ type: "text", text: "Session exiting; results returned to parent." }],
        terminate: true,
      };
    },
  });
}