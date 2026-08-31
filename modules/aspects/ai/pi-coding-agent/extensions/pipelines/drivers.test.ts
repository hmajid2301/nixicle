// extensions/pipelines/drivers.test.ts
import { describe, expect, test } from "bun:test";
import { buildLaunch, buildToolAllowlist, isHeadlessCapable, shellQuote, type LaunchOpts } from "./drivers.ts";

const base: LaunchOpts = {
  id: "run-1",
  name: "scout",
  task: "map the repo",
  cwd: "/repo",
  harness: "pi",
  mode: "pane",
  sessionFile: "/p/sessions/run-1.jsonl",
  exitFile: "/p/exit/run-1.json",
  childExtPath: "/p/child.ts",
  autoExit: true,
  agentName: "scout",
};

describe("shellQuote", () => {
  test("wraps and escapes single quotes", () => {
    expect(shellQuote("it's")).toBe("'it'\\''s'");
    expect(shellQuote("plain")).toBe("'plain'");
  });
});

describe("buildToolAllowlist", () => {
  test("appends control tools, dedupes", () => {
    expect(buildToolAllowlist(["read", "bash"])).toBe("read,bash,subagent_done,caller_ping");
    expect(buildToolAllowlist(["caller_ping"])).toBe("caller_ping,subagent_done");
  });
  test("null when unspecified", () => {
    expect(buildToolAllowlist(undefined)).toBeNull();
    expect(buildToolAllowlist([])).toBeNull();
  });
});

describe("isHeadlessCapable", () => {
  test("pi/claude/codex/opencode yes, grok and custom no", () => {
    expect(isHeadlessCapable("pi")).toBe(true);
    expect(isHeadlessCapable("claude")).toBe(true);
    expect(isHeadlessCapable("codex")).toBe(true);
    expect(isHeadlessCapable("opencode")).toBe(true);
    expect(isHeadlessCapable("grok")).toBe(false);
    expect(isHeadlessCapable("mycli")).toBe(false);
  });
});

describe("buildLaunch", () => {
  test("pi pane: session, child ext, env, sentinel", () => {
    delete process.env.PI_CODING_AGENT_DIR; // deterministic env prefix
    const s = buildLaunch(base);
    expect(s).toContain("cd '/repo' && ");
    expect(s).toContain(
      "PI_SUBAGENT_NAME='scout' PI_SUBAGENT_AGENT='scout' PI_SUBAGENT_AUTO_EXIT=1 PI_SUBAGENT_EXIT_FILE='/p/exit/run-1.json' pi",
    );
    expect(s).toContain("--no-extensions --session '/p/sessions/run-1.jsonl'");
    expect(s).toContain("-e '/p/child.ts'");
    expect(s).toContain("'map the repo'");
    expect(s.endsWith("; echo '__PIPL_EXIT_'$?'__'")).toBe(true);
  });
  test("pi headless: json -p mode, no sentinel", () => {
    const s = buildLaunch({ ...base, mode: "headless" });
    expect(s).toContain("--no-extensions --session '/p/sessions/run-1.jsonl' --mode 'json' -p");
    expect(s).not.toContain("__PIPL_EXIT_");
  });
  test("pi with model, thinking, tools, skills, sysprompt", () => {
    const s = buildLaunch({
      ...base,
      model: "m1",
      thinking: "high",
      tools: ["read"],
      skills: ["/skills/x"],
      extensions: ["/ext/ketch.ts"],
      systemPromptAppend: "be terse",
    });
    expect(s).toContain("--model 'm1'");
    expect(s).toContain("--thinking 'high'");
    expect(s).toContain("--tools 'read,subagent_done,caller_ping'");
    expect(s).toContain("--skill '/skills/x'");
    expect(s).toContain("-e '/ext/ketch.ts'");
    expect(s).toContain("--append-system-prompt 'be terse'");
  });
  test("pi without session/exit files throws", () => {
    expect(() => buildLaunch({ ...base, sessionFile: undefined })).toThrow(/sessionFile/);
    expect(() => buildLaunch({ ...base, exitFile: undefined })).toThrow(/exitFile/);
  });
  test("claude headless: --print, no sentinel", () => {
    const s = buildLaunch({ ...base, harness: "claude", mode: "headless" });
    expect(s).toContain("claude --print --output-format 'text'");
    expect(s).not.toContain("__PIPL_EXIT_");
  });
  test("claude pane: skip-permissions, sysprompt, sentinel", () => {
    const s = buildLaunch({
      ...base, harness: "claude", mode: "pane", systemPromptAppend: "sp", model: "m",
    });
    expect(s).toContain("claude --dangerously-skip-permissions");
    expect(s).toContain("--model 'm'");
    expect(s).toContain("--append-system-prompt 'sp'");
    expect(s.endsWith("__PIPL_EXIT_'$?'__'")).toBe(true);
  });
  test("codex headless uses exec; thinking maps to reasoning-effort", () => {
    const s = buildLaunch({ ...base, harness: "codex", mode: "headless", thinking: "high", systemPromptAppend: "sp" });
    expect(s).toContain("codex exec");
    expect(s).toContain("--reasoning-effort 'high'");
    expect(s).toContain("--system-prompt 'sp'");
  });
  test("grok headless throws", () => {
    expect(() => buildLaunch({ ...base, harness: "grok", mode: "headless" })).toThrow(/headless/);
  });
  test("custom cli pane-only", () => {
    const s = buildLaunch({ ...base, harness: "mycli", mode: "pane" });
    expect(s).toContain("mycli 'map the repo'");
    expect(() => buildLaunch({ ...base, harness: "mycli", mode: "headless" })).toThrow(/headless/);
  });
});