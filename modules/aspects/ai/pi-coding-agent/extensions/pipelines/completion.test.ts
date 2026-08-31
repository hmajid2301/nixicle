// extensions/pipelines/completion.test.ts
import { describe, expect, test } from "bun:test";
import { mkdtempSync, writeFileSync, existsSync, rmSync } from "node:fs";
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
  test("error sidecar carries isCreditLimit", () => {
    expect(
      interpretExitSidecar({ type: "error", errorMessage: "Insufficient balance", isCreditLimit: true }),
    ).toEqual({ reason: "error", exitCode: 1, errorMessage: "Insufficient balance", isCreditLimit: true });
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
  test("skips inspectPane when readScreen returns content (pane is present)", async () => {
    const c = new AbortController();
    let inspects = 0;
    const p = waitForCompletion(c.signal, {
      intervalMs: 5,
      readScreen: async () => "working...",
      inspectPane: async () => { inspects++; return "present"; },
    });
    await new Promise((r) => setTimeout(r, 30));
    c.abort();
    await expect(p).rejects.toThrow(/aborted/);
    expect(inspects).toBe(0);
  });
  test("calls inspectPane when readScreen returns empty", async () => {
    const c = new AbortController();
    let inspects = 0;
    const p = waitForCompletion(c.signal, {
      intervalMs: 5,
      readScreen: async () => "",
      inspectPane: async () => { inspects++; return "present"; },
    });
    await new Promise((r) => setTimeout(r, 30));
    c.abort();
    await expect(p).rejects.toThrow(/aborted/);
    expect(inspects).toBeGreaterThan(0);
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
  test("calls onTimeout after timeoutMs and keeps waiting (does not resolve)", async () => {
    const c = new AbortController();
    const timeouts: number[] = [];
    const p = waitForCompletion(c.signal, {
      intervalMs: 5,
      timeoutMs: 20,
      onTimeout: (s) => timeouts.push(s),
      inspectPane: async () => "present",
    });
    await new Promise((r) => setTimeout(r, 60));
    c.abort();
    await expect(p).rejects.toThrow(/aborted/);
    expect(timeouts.length).toBeGreaterThanOrEqual(1);
  });
  test("watchdog fires onTimeout once and resolves on sidecar", async () => {
    const dir = mkdtempSync(join(tmpdir(), "pipl-watchdog-"));
    const exitFile = join(dir, "exit.json");
    const c = new AbortController();
    const timeouts: number[] = [];
    const p = waitForCompletion(c.signal, {
      intervalMs: 5,
      exitFile,
      timeoutMs: 20,
      onTimeout: (s) => timeouts.push(s),
      inspectPane: async () => "present",
    });
    await new Promise((r) => setTimeout(r, 100));
    writeFileSync(exitFile, JSON.stringify({ type: "done" }));
    const result = await p;
    expect(result).toEqual({ reason: "done", exitCode: 0 });
    expect(timeouts).toHaveLength(1);
    rmSync(dir, { recursive: true, force: true });
  });
  test("resolves via childExit with exit code when no sidecar is written", async () => {
    const c = new AbortController();
    let resolveExit: (code: number | null) => void = () => {};
    const childExit = new Promise<number | null>((r) => (resolveExit = r));
    const p = waitForCompletion(c.signal, {
      intervalMs: 5,
      childExit,
      inspectPane: async () => "present",
    });
    resolveExit(0);
    await expect(p).resolves.toEqual({ reason: "done", exitCode: 0 });
  });
  test("childExit with non-zero code yields an error result", async () => {
    const c = new AbortController();
    let resolveExit: (code: number | null) => void = () => {};
    const childExit = new Promise<number | null>((r) => (resolveExit = r));
    const p = waitForCompletion(c.signal, {
      intervalMs: 5,
      childExit,
      inspectPane: async () => "present",
    });
    resolveExit(3);
    const result = await p;
    expect(result.reason).toBe("error");
    expect(result.exitCode).toBe(3);
  });
  test("childExit prefers a late sidecar over the exit code", async () => {
    const dir = mkdtempSync(join(tmpdir(), "pipl-child-race-"));
    const exitFile = join(dir, "exit.json");
    const c = new AbortController();
    let resolveExit: (code: number | null) => void = () => {};
    const childExit = new Promise<number | null>((r) => (resolveExit = r));
    const p = waitForCompletion(c.signal, {
      intervalMs: 5,
      exitFile,
      childExit,
      inspectPane: async () => "present",
    });
    writeFileSync(exitFile, JSON.stringify({ type: "done" }));
    resolveExit(1);
    await expect(p).resolves.toEqual({ reason: "done", exitCode: 0 });
    rmSync(dir, { recursive: true, force: true });
  });
});