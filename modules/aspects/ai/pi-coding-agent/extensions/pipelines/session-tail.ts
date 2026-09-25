// extensions/pipelines/session-tail.ts
// Reads the tail of a child pi session (JSONL) for widget + result data.
import { readSessionEntries, textOf } from "./session-log.ts";

export interface TailInfo {
  lastText: string;
  lastTool?: string;
  tokens?: number;
}

function tokensOf(usage: any): number | undefined {
  if (!usage || typeof usage !== "object") return undefined;
  const total = usage.totalTokens ?? usage.total_tokens;
  if (typeof total === "number" && total > 0) return total;
  const inTok = usage.inputTokens ?? usage.input_tokens ?? usage.input;
  const outTok = usage.outputTokens ?? usage.output_tokens ?? usage.output;
  if (typeof inTok === "number" || typeof outTok === "number") {
    return (typeof inTok === "number" ? inTok : 0) + (typeof outTok === "number" ? outTok : 0);
  }
  return undefined;
}

function toolNameOf(content: unknown): string | undefined {
  if (!Array.isArray(content)) return undefined;
  const calls = content.filter(
    (c: any) => c?.type === "toolCall" || c?.type === "tool_call" || c?.type === "toolUse",
  );
  const last = calls[calls.length - 1] as any;
  return last?.name;
}

export function readSessionTail(sessionFile: string, maxLines = 400): TailInfo | null {
  let lastText = "";
  let lastTool: string | undefined;
  let tokens: number | undefined;
  for (const entry of readSessionEntries(sessionFile, maxLines)) {
    const msg = entry?.message ?? entry;
    if (msg?.role === "assistant") {
      const text = textOf(msg.content);
      if (text.trim()) lastText = text;
      const tok = tokensOf(msg.usage);
      if (tok !== undefined) tokens = tok;
      const tool = toolNameOf(msg.content);
      if (tool) lastTool = tool;
    } else if (msg?.type === "tool_call" || msg?.type === "toolCall" || msg?.type === "toolUse") {
      if (msg?.name) lastTool = msg.name;
    }
  }
  if (!lastText && lastTool === undefined && tokens === undefined) return null;
  return { lastText, lastTool, tokens };
}
