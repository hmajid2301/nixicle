// extensions/pipelines/completion.test.ts
import { describe, expect, test } from "bun:test";
import { mkdtempSync, writeFileSync, existsSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { interpretExitSidecar, parseSentinel, readExitFile, waitForCompletion } from "./completion.ts";

describe("interpretExitSidecar", () => {
  test("done", () => {
    expect(interpretExitSidecar({ type: "done" })).toEqual({ reason: "done", exitCode: 0 });
  });
  test("done carries optional output", () => {
    expect(interpretExitSidecar({ type: "done", output: "ok" })).toEqual({
      reason: "done", exitCode: 0, output: "ok",
    });
  });
  test("ping carries name + message", () => {
    expect(interpretExitSidecar({ type: "ping", name: "scout", message: "help me" })).toEqual({
      reason: "ping", exitCode: 0, ping: { name: "scout", message: "help me" },
    });
  });
  test("error", () => {
    expect(interpretExitSidecar({ type: "error", errorMessage: "boom" })).toEqual({
      reason: "error", exitCode: 1, errorMessage: "boom",
    });
    expect(interpretExitSidecar({ type: "error" })?.errorMessage).toContain("no message");
  });
  test("null on junk", () => {
    expect(interpretExitSidecar({ type: "wat" })).toBeNull();
    expect(interpretExitSidecar("nope")).toBeNull();
  });
});

describe("parseSentinel", () => {
  test("extracts exit code", () => {
    expect(parseSentinel("pi done\n__PIPL_EXIT_0__")).toBe(0);
    expect(parseSentinel("__PIPL_EXIT_7__")).toBe(7);
    expect(parseSentinel("nothing here")).toBeNull();
  });
  test("last sentinel wins over stale scrollback", () => {
    expect(parseSentinel("stale __PIPL_EXIT_3__ noise __PIPL_EXIT_0__")).toBe(0);
  });
});

describe("readExitFile", () => {
  test("reads and removes file", () => {
    const dir = mkdtempSync(join(tmpdir(), "pipelines-exit-"));
    const file = join(dir, "run.json");
    expect(readExitFile(file)).toBeNull();
    writeFileSync(file, JSON.stringify({ type: "done" }));
    expect(readExitFile(file)).toEqual({ reason: "done", exitCode: 0 });
    expect(existsSync(file)).toBe(false);
  });
  test("null on partial write", () => {
    const dir = mkdtempSync(join(tmpdir(), "pipelines-exit-"));
    const file = join(dir, "run.json");
    writeFileSync(file, "{ partial");
    expect(readExitFile(file)).toBeNull();
  });
  test("consumes unrecognized sidecar as error", () => {
    const dir = mkdtempSync(join(tmpdir(), "pipelines-exit-"));
    const file = join(dir, "run.json");
    writeFileSync(file, JSON.stringify({ type: "wat" }));
    const result = readExitFile(file);
    expect(result?.reason).toBe("error");
    expect(result?.errorMessage).toContain("unrecognized");
    expect(existsSync(file)).toBe(false);
  });
});

describe("waitForCompletion", () => {
  test("resolves via sentinel from screen", async () => {
    let calls = 0;
    const result = await waitForCompletion(new AbortController().signal, {
      intervalMs: 5,
      readScreen: async () => {
        calls++;
        return calls < 2 ? "working..." : "__PIPL_EXIT_0__";
      },
    });
    expect(result).toEqual({ reason: "done", exitCode: 0 });
  });
  test("resolves error on nonzero sentinel", async () => {
    const result = await waitForCompletion(new AbortController().signal, {
      intervalMs: 5,
      readScreen: async () => "__PIPL_EXIT_3__",
    });
    expect(result.reason).toBe("error");
    expect(result.exitCode).toBe(3);
  });
  test("resolves via exit file", async () => {
    const dir = mkdtempSync(join(tmpdir(), "pipelines-exit-"));
    const file = join(dir, "run2.json");
    setTimeout(() => writeFileSync(file, JSON.stringify({ type: "done" })), 10);
    const result = await waitForCompletion(new AbortController().signal, {
      intervalMs: 5, exitFile: file,
    });
    expect(result).toEqual({ reason: "done", exitCode: 0 });
  });
  test("pane missing → error after grace", async () => {
    const result = await waitForCompletion(new AbortController().signal, {
      intervalMs: 1,
      paneDisappearanceGraceMs: 5,
      inspectPane: async () => "missing",
    });
    expect(result.reason).toBe("error");
    expect(result.errorMessage).toContain("pane disappeared");
  });
  test("aborts when signal fires", async () => {
    const c = new AbortController();
    const p = waitForCompletion(c.signal, { intervalMs: 5, inspectPane: async () => "present" });
    c.abort();
    await expect(p).rejects.toThrow(/aborted/);
  });
});