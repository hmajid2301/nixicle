// extensions/pipelines/btw-controller.test.ts
import { beforeAll, describe, expect, test } from "bun:test";
import { existsSync, mkdtempSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { mergeFileFor, writeMergeRequest } from "./btw.ts";
import { createBtwController, type BtwController } from "./btw-controller.ts";
import type { CompletionResult, RunHandle } from "./types.ts";

let exitDir: string;
let sessionFile: string;

beforeAll(() => {
  exitDir = mkdtempSync(join(tmpdir(), "pipelines-btwctl-"));
  sessionFile = join(exitDir, "child.jsonl");
  writeFileSync(
    sessionFile,
    [
      JSON.stringify({ message: { role: "user", content: "why blue" } }),
      JSON.stringify({ message: { role: "assistant", content: "rayleigh" } }),
    ].join("\n") + "\n",
  );
});

interface Harness {
  controller: BtwController;
  sends: { message: string; prompt: string }[];
  closed: string[];
  requests: any[];
  settle(id: string, result: CompletionResult): Promise<void>;
}

function makeHarness(available = true): Harness {
  const sends: { message: string; prompt: string }[] = [];
  const closed: string[] = [];
  const requests: any[] = [];
  const pending = new Map<string, (r: CompletionResult) => void>();

  const controller = createBtwController({
    available: () => available,
    exitDir,
    tools: ["read"],
    makeRequest: (id, question, systemPromptAppend, tools) => {
      const req = { id, name: "btw", task: question, systemPromptAppend, tools, cwd: "/tmp", harness: "pi", autoExit: false };
      requests.push(req);
      return req as any;
    },
    spawn: (req): RunHandle => {
      const completion = new Promise<CompletionResult>((resolve) => pending.set(req.id, resolve));
      return {
        id: req.id,
        name: "btw",
        backend: "pane",
        paneId: `pane-${req.id}`,
        sessionPath: sessionFile,
        startedAt: Date.now(),
        completion,
        interrupt: async () => {},
      };
    },
    closePane: (paneId) => {
      closed.push(paneId);
    },
    sendMerge: (message, prompt) => {
      sends.push({ message, prompt });
    },
  });

  return {
    controller,
    sends,
    closed,
    requests,
    settle: async (id, result) => {
      pending.get(id)?.(result);
      await Promise.resolve();
      await Promise.resolve();
    },
  };
}

function mergePath(id: string): string {
  return mergeFileFor(join(exitDir, `${id}.json`));
}

describe("createBtwController", () => {
  test("start throws when no pane backend is available", () => {
    const h = makeHarness(false);
    expect(() => h.controller.start("hi", sessionFile)).toThrow(/Herdr pane/);
  });

  test("start requires a question", () => {
    const h = makeHarness();
    expect(() => h.controller.start("  ", sessionFile)).toThrow(/Usage/);
  });

  test("start marks the child and uses a split placement", () => {
    const h = makeHarness();
    const id = h.controller.start("why is the sky blue", sessionFile);
    const req = h.requests.at(-1);
    expect(req.env).toEqual({ PI_BTW: "1" });
    expect(req.panePlacement).toEqual({ mode: "split", direction: "down", maxPerTab: 1 });
    expect(req.systemPromptAppend).toContain("Parent conversation (snapshot)");
    expect(req.tools).toEqual(["read"]);
    expect(id.startsWith("btw")).toBe(true);
  });

  test("delivers the transcript and prompt on a merged completion", async () => {
    const h = makeHarness();
    const id = h.controller.start("q", sessionFile);
    writeMergeRequest(mergePath(id), "apply it");
    await h.settle(id, { reason: "done", exitCode: 0 });
    expect(h.sends).toHaveLength(1);
    expect(h.sends[0].prompt).toBe("apply it");
    expect(h.sends[0].message).toContain("Assistant: rayleigh");
    expect(existsSync(mergePath(id))).toBe(false);
  });

  test("delivers nothing when the child exits without a merge request", async () => {
    const h = makeHarness();
    const id = h.controller.start("q", sessionFile);
    await h.settle(id, { reason: "done", exitCode: 0 });
    expect(h.sends).toHaveLength(0);
  });

  test("close drops and does not deliver a later merge", async () => {
    const h = makeHarness();
    const id = h.controller.start("q", sessionFile);
    expect(h.controller.close()).toBe(true);
    expect(h.closed).toEqual([`pane-${id}`]);
    writeMergeRequest(mergePath(id), "late");
    await h.settle(id, { reason: "done", exitCode: 0 });
    expect(h.sends).toHaveLength(0);
  });

  test("a second start replaces the first", () => {
    const h = makeHarness();
    const first = h.controller.start("one", sessionFile);
    const second = h.controller.start("two", sessionFile);
    expect(h.closed).toEqual([`pane-${first}`]);
    expect(second).not.toBe(first);
  });

  test("close is false when nothing is open", () => {
    expect(makeHarness().controller.close()).toBe(false);
  });
});
