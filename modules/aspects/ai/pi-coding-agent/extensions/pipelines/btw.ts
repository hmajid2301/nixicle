// extensions/pipelines/btw.ts
// /btw side-thread helpers: parent-context document, transcript folding, and
// the child->parent merge mailbox.
import { existsSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { readSessionEntries, textOf } from "./session-log.ts";

export const MERGE_TAG_OPEN = "<btw-merge>";
export const MERGE_TAG_CLOSE = "</btw-merge>";
const TRANSCRIPT_BUDGET = 48 * 1024;
const SNAPSHOT_BUDGET = 32 * 1024;

export interface BtwTurn {
  role: "user" | "assistant";
  text: string;
}

export interface MergeRequest {
  prompt: string;
}

/** Read user/assistant text turns from a pi session JSONL, oldest first. */
export function readTurns(sessionFile: string, maxLines = 800): BtwTurn[] {
  const turns: BtwTurn[] = [];
  for (const entry of readSessionEntries(sessionFile, maxLines)) {
    const msg = entry?.message ?? entry;
    const role = msg?.role;
    if (role !== "user" && role !== "assistant") continue;
    const text = textOf(msg.content).trim();
    if (text) turns.push({ role, text });
  }
  return turns;
}

function tailClip(text: string, budget: number): string {
  if (text.length <= budget) return text;
  return `…(earlier text truncated)…\n${text.slice(text.length - budget)}`;
}

/** Fold a child side-thread into user/assistant text, trimmed from the head. */
export function buildMergeTranscript(sessionFile: string, budget = TRANSCRIPT_BUDGET): string {
  const body = readTurns(sessionFile)
    .map((t) => `${t.role === "user" ? "User" : "Assistant"}: ${t.text}`)
    .join("\n\n");
  return tailClip(body, budget);
}

export function formatMergeMessage(transcript: string): string {
  return `Merged from /btw side thread:\n${MERGE_TAG_OPEN}\n${transcript}\n${MERGE_TAG_CLOSE}`;
}

/** Build the reference document appended to a side thread's system prompt. */
export function buildContextDocument(sessionFile: string, budget = SNAPSHOT_BUDGET): string {
  const body = readTurns(sessionFile)
    .map((t) => `**${t.role === "user" ? "User" : "Assistant"}:** ${t.text}`)
    .join("\n\n");
  return [
    "# Parent conversation (snapshot)",
    "",
    "This is a /btw side thread opened from the conversation below. Treat it as reference. " +
      "Unless you run /btw-merge, the parent will not see anything you do here.",
    "",
    tailClip(body, budget),
  ].join("\n");
}

/** The child writes its merge request beside its exit sidecar; the parent reads it. */
export function mergeFileFor(exitFile: string): string {
  return `${exitFile}.merge.json`;
}

export function writeMergeRequest(path: string, prompt: string): void {
  writeFileSync(path, JSON.stringify({ prompt } satisfies MergeRequest), "utf8");
}

export function readMergeRequest(path: string): MergeRequest | null {
  if (!existsSync(path)) return null;
  try {
    const parsed = JSON.parse(readFileSync(path, "utf8"));
    return typeof parsed?.prompt === "string" && parsed.prompt ? { prompt: parsed.prompt } : null;
  } catch {
    return null;
  }
}

export function clearMergeRequest(path: string): void {
  try {
    rmSync(path, { force: true });
  } catch {
    // best effort — merge mailboxes are disposable
  }
}
