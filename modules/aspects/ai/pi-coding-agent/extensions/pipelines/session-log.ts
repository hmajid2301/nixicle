// extensions/pipelines/session-log.ts
// Shared pi-session JSONL parsing for session-tail and /btw.
import { closeSync, openSync, readSync, statSync } from "node:fs";

// Only the tail is ever needed; cap the read so large sessions don't block the UI.
const MAX_TAIL_BYTES = 512 * 1024;

export function textOf(content: unknown): string {
  if (typeof content === "string") return content;
  if (Array.isArray(content)) {
    return content
      .filter((c: any) => c?.type === "text")
      .map((c: any) => c.text ?? "")
      .join("\n");
  }
  return "";
}

/** Parse the last `maxLines` JSONL entries of a pi session file (junk lines skipped). */
export function readSessionEntries(sessionFile: string, maxLines = 800): any[] {
  let text: string;
  try {
    const { size } = statSync(sessionFile);
    const start = Math.max(0, size - MAX_TAIL_BYTES);
    const length = size - start;
    const fd = openSync(sessionFile, "r");
    try {
      const buffer = Buffer.allocUnsafe(length);
      readSync(fd, buffer, 0, length, start);
      text = buffer.toString("utf8");
    } finally {
      closeSync(fd);
    }
    // A nonzero start can land mid-line; drop that partial first line.
    if (start > 0) text = text.slice(text.indexOf("\n") + 1);
  } catch {
    return [];
  }
  const entries: any[] = [];
  const lines = text.split("\n").filter((line) => line.trim());
  for (const line of lines.slice(-maxLines)) {
    try {
      entries.push(JSON.parse(line));
    } catch {
      // partial trailing write — skip
    }
  }
  return entries;
}
