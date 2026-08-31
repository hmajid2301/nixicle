// extensions/pipelines/log.test.ts
import { describe, expect, test } from "bun:test";
import { mkdtempSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { initLogging, log } from "./log.ts";

describe("log", () => {
  test("writes structured JSON lines to the configured path", () => {
    const dir = mkdtempSync(join(tmpdir(), "pipl-log-"));
    const file = join(dir, "pipelines.log");
    initLogging(file);
    log("info", "run_spawned", { id: "r1", backend: "pane" });
    log("error", "credit_limit", { id: "r2", error: "Insufficient balance" });
    const lines = readFileSync(file, "utf8").trim().split("\n");
    expect(lines).toHaveLength(2);
    const first = JSON.parse(lines[0]!);
    expect(first.level).toBe("info");
    expect(first.event).toBe("run_spawned");
    expect(first.id).toBe("r1");
    expect(first.backend).toBe("pane");
    expect(typeof first.ts).toBe("string");
    const second = JSON.parse(lines[1]!);
    expect(second.level).toBe("error");
    expect(second.event).toBe("credit_limit");
    rmSync(dir, { recursive: true, force: true });
  });

  test("is a no-op before initLogging (never throws)", () => {
    expect(() => log("warn", "noop", {})).not.toThrow();
  });
});
