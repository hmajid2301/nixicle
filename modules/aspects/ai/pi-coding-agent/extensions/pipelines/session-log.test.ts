// extensions/pipelines/session-log.test.ts
import { beforeAll, describe, expect, test } from "bun:test";
import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { readSessionEntries, textOf } from "./session-log.ts";

let dir: string;

beforeAll(() => {
  dir = mkdtempSync(join(tmpdir(), "pipelines-session-log-"));
});

describe("textOf", () => {
  test("joins text parts and ignores non-text", () => {
    expect(textOf("plain")).toBe("plain");
    expect(textOf([{ type: "text", text: "a" }, { type: "toolCall", name: "x" }, { type: "text", text: "b" }])).toBe("a\nb");
    expect(textOf(42)).toBe("");
  });
});

describe("readSessionEntries", () => {
  test("parses valid lines and skips junk", () => {
    const file = join(dir, "ok.jsonl");
    writeFileSync(file, ["{\"a\":1}", "not json", "", "{\"b\":2}"].join("\n") + "\n");
    expect(readSessionEntries(file)).toEqual([{ a: 1 }, { b: 2 }]);
  });

  test("empty for a missing file", () => {
    expect(readSessionEntries(join(dir, "missing.jsonl"))).toEqual([]);
  });

  test("reads only the tail of a file larger than the byte cap", () => {
    const file = join(dir, "huge.jsonl");
    const head = JSON.stringify({ marker: "head", pad: "a".repeat(600_000) });
    writeFileSync(file, [head, JSON.stringify({ marker: "tail" })].join("\n") + "\n");
    const entries = readSessionEntries(file);
    expect(entries.at(-1)).toEqual({ marker: "tail" });
    expect(entries.some((e) => e?.marker === "head")).toBe(false);
  });

  test("honours maxLines", () => {
    const file = join(dir, "many.jsonl");
    writeFileSync(file, Array.from({ length: 10 }, (_, i) => JSON.stringify({ i })).join("\n") + "\n");
    expect(readSessionEntries(file, 2)).toEqual([{ i: 8 }, { i: 9 }]);
  });
});
