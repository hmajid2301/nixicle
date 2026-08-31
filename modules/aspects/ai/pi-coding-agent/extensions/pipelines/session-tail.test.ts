// extensions/pipelines/session-tail.test.ts
import { describe, expect, test } from "bun:test";
import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { readSessionTail } from "./session-tail.ts";

describe("readSessionTail", () => {
  test("bare-message entries: last assistant text, tool name, tokens", () => {
    const dir = mkdtempSync(join(tmpdir(), "pipelines-tail-"));
    const file = join(dir, "s.jsonl");
    writeFileSync(file, [
      JSON.stringify({ role: "user", content: [{ type: "text", text: "hi" }] }),
      JSON.stringify({ role: "assistant", content: [{ type: "text", text: "first answer" }], usage: { inputTokens: 100, outputTokens: 50 } }),
      JSON.stringify({ role: "assistant", content: [{ type: "toolCall", name: "edit" }, { type: "text", text: "final answer" }], usage: { inputTokens: 200, outputTokens: 80 } }),
    ].join("\n"));
    const info = readSessionTail(file)!;
    expect(info.lastText).toBe("final answer");
    expect(info.lastTool).toBe("edit");
    expect(info.tokens).toBe(280);
  });

  test("wrapped entries ({type:'message', message:{...}})", () => {
    const dir = mkdtempSync(join(tmpdir(), "pipelines-tail-"));
    const file = join(dir, "s.jsonl");
    writeFileSync(file, [
      JSON.stringify({ type: "message", message: { role: "assistant", content: [{ type: "text", text: "wrapped" }], usage: { inputTokens: 10, outputTokens: 5 } } }),
    ].join("\n"));
    const info = readSessionTail(file)!;
    expect(info.lastText).toBe("wrapped");
    expect(info.tokens).toBe(15);
  });

  test("junk lines ignored", () => {
    const dir = mkdtempSync(join(tmpdir(), "pipelines-tail-"));
    const file = join(dir, "s.jsonl");
    writeFileSync(file, [
      "not json",
      JSON.stringify({ role: "assistant", content: "string content", usage: { totalTokens: 42 } }),
    ].join("\n"));
    const info = readSessionTail(file)!;
    expect(info.lastText).toBe("string content");
    expect(info.tokens).toBe(42);
  });

  test("null when missing or empty", () => {
    expect(readSessionTail("/nonexistent/nope.jsonl")).toBeNull();
    const dir = mkdtempSync(join(tmpdir(), "pipelines-tail-"));
    expect(readSessionTail(join(dir, "empty.jsonl"))).toBeNull();
  });
});