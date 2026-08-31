// extensions/pipelines/child-helpers.test.ts
import { describe, expect, test } from "bun:test";
import {
  buildCompletionSidecar,
  findLatestAssistantError,
  isCreditLimitError,
  isTransientError,
  shouldAutoExitOnAgentEnd,
  shouldMarkUserTookOver,
} from "./child-helpers.ts";

const done = [{ role: "assistant", stopReason: "stop" }];
const errored = [{ role: "assistant", stopReason: "error", errorMessage: "overloaded" }];
const aborted = [{ role: "assistant", stopReason: "aborted" }];

describe("shouldMarkUserTookOver", () => {
  test("only after agent started", () => {
    expect(shouldMarkUserTookOver(false)).toBe(false);
    expect(shouldMarkUserTookOver(true)).toBe(true);
  });
});

describe("shouldAutoExitOnAgentEnd", () => {
  test("exit on normal end; not on abort", () => {
    expect(shouldAutoExitOnAgentEnd(false, done)).toBe(true);
    expect(shouldAutoExitOnAgentEnd(false, aborted)).toBe(false);
  });
  test("exit on error end (so parent learns)", () => {
    expect(shouldAutoExitOnAgentEnd(false, errored)).toBe(true);
  });
  test("exit on length-stopped agent (surfaces the error)", () => {
    expect(shouldAutoExitOnAgentEnd(false, [{ role: "assistant", stopReason: "length" }])).toBe(true);
  });
  test("no messages → exit", () => {
    expect(shouldAutoExitOnAgentEnd(false, undefined)).toBe(true);
  });
});

describe("isCreditLimitError", () => {
  test("flags credit/billing patterns", () => {
    expect(isCreditLimitError("Insufficient balance. Manage your billing here")).toBe(true);
    expect(isCreditLimitError("CreditsError: out of credits")).toBe(true);
    expect(isCreditLimitError("payment required (402)")).toBe(true);
    expect(isCreditLimitError("syntax error in file")).toBe(false);
  });
});

describe("isTransientError", () => {
  test("flags overload/rate-limit/network patterns", () => {
    expect(isTransientError("overloaded, try again later")).toBe(true);
    expect(isTransientError("rate limit exceeded (429)")).toBe(true);
    expect(isTransientError("ECONNRESET: connection reset")).toBe(true);
    expect(isTransientError("backend temporarily unavailable")).toBe(true);
  });
  test("does not flag permanent errors", () => {
    expect(isTransientError("syntax error in file")).toBe(false);
    expect(isTransientError("invalid API key")).toBe(false);
    expect(isTransientError("Insufficient balance")).toBe(false);
  });
});

describe("findLatestAssistantError", () => {
  test("sets isCreditLimit on billing errors", () => {
    expect(findLatestAssistantError([{ role: "assistant", stopReason: "error", errorMessage: "Insufficient balance" }])).toEqual({
      errorMessage: "Insufficient balance", stopReason: "error", isCreditLimit: true,
    });
  });
  test("omits isCreditLimit for non-billing errors", () => {
    expect(findLatestAssistantError(errored)).toEqual({
      errorMessage: "overloaded", stopReason: "error",
    });
  });
  test("finds error info from latest assistant", () => {
    expect(findLatestAssistantError(errored)).toEqual({
      errorMessage: "overloaded", stopReason: "error",
    });
  });
  test("null on normal or missing", () => {
    expect(findLatestAssistantError(done)).toBeNull();
    expect(findLatestAssistantError(undefined)).toBeNull();
  });
  test("falls back to generic message when errorMessage empty", () => {
    expect(findLatestAssistantError([{ role: "assistant", stopReason: "error" }])?.errorMessage)
      .toContain("no errorMessage field");
  });
  test("length/deferred stopReasons classified as error, not done", () => {
    expect(findLatestAssistantError([{ role: "assistant", stopReason: "length" }])?.errorMessage)
      .toContain("length");
    expect(findLatestAssistantError([{ role: "assistant", stopReason: "deferred" }])?.errorMessage)
      .toContain("deferred");
    expect(buildCompletionSidecar([{ role: "assistant", stopReason: "length" }])).toEqual({
      type: "error", errorMessage: expect.stringContaining("length"), stopReason: "error",
    });
  });
});

describe("buildCompletionSidecar", () => {
  test("done sidecar", () => {
    expect(buildCompletionSidecar(done)).toEqual({ type: "done" });
  });
  test("error sidecar", () => {
    expect(buildCompletionSidecar(errored)).toEqual({
      type: "error", errorMessage: "overloaded", stopReason: "error",
    });
  });
});