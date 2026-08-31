// extensions/pipelines/child-helpers.ts
// Pure decision helpers for the child-side extension.

export function shouldMarkUserTookOver(agentStarted: boolean): boolean {
  return agentStarted;
}

export interface SubagentErrorInfo {
  errorMessage: string;
  stopReason: "error";
}

export function findLatestAssistantError(
  messages: any[] | undefined,
): SubagentErrorInfo | null {
  if (!messages) return null;
  for (let i = messages.length - 1; i >= 0; i--) {
    const msg = messages[i];
    if (msg?.role !== "assistant") continue;
    // pi's stopReason union is "pending" | "stop" | "length" | "toolUse" |
    // "error" | "aborted" | "deferred". length/deferred mean the run did
    // NOT complete normally (context limit / deferred turn) — classify them
    // as error so a truncated run can't report done.
    if (msg.stopReason === "length" || msg.stopReason === "deferred") {
      return msg.stopReason === "length"
        ? { errorMessage: "context length limit reached (stopReason=length)", stopReason: "error" }
        : { errorMessage: "run deferred before completion (stopReason=deferred)", stopReason: "error" };
    }
    if (msg.stopReason !== "error") return null;
    const raw = typeof msg.errorMessage === "string" ? msg.errorMessage.trim() : "";
    return {
      errorMessage: raw || "child agent loop ended with stopReason=error (no errorMessage field).",
      stopReason: "error",
    };
  }
  return null;
}

export function shouldAutoExitOnAgentEnd(
  _userTookOver: boolean,
  messages: any[] | undefined,
): boolean {
  // Manual input must not strand an auto-exit child: exit on the latest
  // normally-completed agent turn, but leave aborted sessions open.
  if (messages) {
    for (let i = messages.length - 1; i >= 0; i--) {
      if (messages[i]?.role === "assistant") {
        return messages[i].stopReason !== "aborted";
      }
    }
  }
  return true;
}

export function buildCompletionSidecar(
  messages: any[] | undefined,
): { type: "done" } | { type: "error"; errorMessage: string; stopReason: "error" } {
  const errorInfo = findLatestAssistantError(messages);
  return errorInfo ? { type: "error", ...errorInfo } : { type: "done" };
}