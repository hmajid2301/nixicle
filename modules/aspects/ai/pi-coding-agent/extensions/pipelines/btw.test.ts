// extensions/pipelines/btw.test.ts
import { beforeAll, describe, expect, test } from "bun:test";
import { existsSync, mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
  buildContextDocument,
  buildMergeTranscript,
  clearMergeRequest,
  formatMergeMessage,
  mergeFileFor,
  readMergeRequest,
  readTurns,
  writeMergeRequest,
} from "./btw.ts";

let dir: string;

beforeAll(() => {
  dir = mkdtempSync(join(tmpdir(), "pipelines-btw-"));
});

function sessionFile(lines: unknown[]): string {
  const file = join(dir, `session-${Math.random().toString(36).slice(2)}.jsonl`);
  writeFileSync(file, lines.map((l) => JSON.stringify(l)).join("\n") + "\n");
  return file;
}

describe("readTurns", () => {
  test("keeps user/assistant text and skips tool/other entries", () => {
    const file = sessionFile([
      { type: "message", message: { role: "user", content: "hi" } },
      { type: "message", message: { role: "assistant", content: [{ type: "text", text: "hello" }, { type: "toolCall", name: "bash" }] } },
      { type: "message", message: { role: "tool", content: "ignored" } },
      { role: "assistant", content: "bare" },
      "not json",
    ]);
    expect(readTurns(file)).toEqual([
      { role: "user", text: "hi" },
      { role: "assistant", text: "hello" },
      { role: "assistant", text: "bare" },
    ]);
  });

  test("empty for a missing file", () => {
    expect(readTurns(join(dir, "nope.jsonl"))).toEqual([]);
  });
});

describe("buildMergeTranscript", () => {
  test("labels roles and trims from the head under budget", () => {
    const file = sessionFile([
      { message: { role: "user", content: "a".repeat(100) } },
      { message: { role: "assistant", content: "answer" } },
    ]);
    const transcript = buildMergeTranscript(file, 60);
    expect(transcript).toContain("Assistant: answer");
    expect(transcript).toContain("earlier text truncated");
    expect(transcript.length).toBeLessThanOrEqual(60 + "…(earlier text truncated)…\n".length);
  });
});

describe("buildContextDocument", () => {
  test("includes the snapshot header and turns", () => {
    const file = sessionFile([{ message: { role: "user", content: "context question" } }]);
    const doc = buildContextDocument(file);
    expect(doc).toContain("# Parent conversation (snapshot)");
    expect(doc).toContain("**User:** context question");
  });
});

describe("formatMergeMessage", () => {
  test("wraps the transcript in merge tags", () => {
    expect(formatMergeMessage("hi")).toContain("<btw-merge>\nhi\n</btw-merge>");
  });
});

describe("merge mailbox", () => {
  test("write, read and clear", () => {
    const path = mergeFileFor(join(dir, "run-1.json"));
    expect(path).toBe(join(dir, "run-1.json.merge.json"));
    writeMergeRequest(path, "apply it");
    expect(readMergeRequest(path)).toEqual({ prompt: "apply it" });
    clearMergeRequest(path);
    expect(existsSync(path)).toBe(false);
  });
  test("null for missing, junk, or empty prompt", () => {
    expect(readMergeRequest(join(dir, "missing.merge.json"))).toBeNull();
    const junk = join(dir, "junk.merge.json");
    writeFileSync(junk, "not json");
    expect(readMergeRequest(junk)).toBeNull();
    writeMergeRequest(junk, "");
    expect(readMergeRequest(junk)).toBeNull();
  });
});
