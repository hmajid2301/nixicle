// extensions/pipelines/child-helpers.ts
// Pure decision helpers for the child-side extension.

export function shouldMarkUserTookOver(agentStarted: boolean): boolean {
  return agentStarted;
}

export interface SubagentErrorInfo {
  errorMessage: string;
  stopReason: "error";
  isCreditLimit?: boolean;
}

const CREDIT_LIMIT_RE =
  /(insufficient balance|insufficient credits|credits?error|billing|credit limit|out of credits|no credits|payment required|402)/i;

export function isCreditLimitError(message: string): boolean {
  return CREDIT_LIMIT_RE.test(message);
}

// Transient failures worth retrying: overload, rate limiting, transient
// network errors, or a busy backend. Deliberately conservative so permanent
// errors (syntax, validation, auth) are not retried.
const TRANSIENT_RE =
  /(overloaded|rate.?limit|too many requests|429|503|temporarily|try again|retry|econnreset|etimedout|connection reset|busy|unavailable|timeout)/i;

export function isTransientError(message: string): boolean {
  return TRANSIENT_RE.test(message);
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
    const info: SubagentErrorInfo = {
      errorMessage: raw || "child agent loop ended with stopReason=error (no errorMessage field).",
      stopReason: "error",
    };
    if (isCreditLimitError(raw)) info.isCreditLimit = true;
    return info;
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