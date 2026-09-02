// extensions/pipelines/agents.test.ts
import { describe, expect, test, beforeAll } from "bun:test";
import { mkdirSync, mkdtempSync, symlinkSync, unlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
  bundledAgentsDir,
  discoverAgents,
  findProjectAgentsDir,
  parseAgentFile,
} from "./agents.ts";

let agentRoot: string;
let projectDir: string;

beforeAll(() => {
  agentRoot = mkdtempSync(join(tmpdir(), "pipelines-agents-"));
  projectDir = mkdtempSync(join(tmpdir(), "pipelines-project-"));
  process.env.PI_CODING_AGENT_DIR = agentRoot;
  mkdirSync(join(agentRoot, "agents"), { recursive: true });
  // user agent, also exists bundled → user must win
  writeFileSync(
    join(agentRoot, "agents", "scout.md"),
    "---\nname: scout\ndescription: user-level scout\n---\nYou are the USER scout.\n",
  );
  // reviewer fixture: bundled reviewer was removed; this user fixture supplies it
  writeFileSync(
    join(agentRoot, "agents", "reviewer.md"),
    "---\nname: reviewer\ndescription: user reviewer\n---\nYou are the USER reviewer.\n",
  );
  // project-level agent directory
  const projAgents = join(projectDir, ".pi", "agent", "agents");
  mkdirSync(projAgents, { recursive: true });
  writeFileSync(
    join(projAgents, "scout.md"),
    "---\nname: scout\ndescription: project scout\n---\nYou are the PROJECT scout.\n",
  );
  writeFileSync(
    join(projAgents, "project-only.md"),
    "---\nname: project-only\ndescription: only here\n---\nOnly in project.\n",
  );
});

describe("parseAgentFile", () => {
  test("parses frontmatter and body", () => {
    const agent = parseAgentFile(
      "---\nname: coder\ndescription: writes code\ntools: read, edit, bash\ncli: pi\nauto-exit: true\n---\nYou write code.",
      "user",
      "/x/coder.md",
    );
    expect(agent?.name).toBe("coder");
    expect(agent?.description).toBe("writes code");
    expect(agent?.systemPrompt).toBe("You write code.");
    expect(agent?.tools).toEqual(["read", "edit", "bash"]);
    expect(agent?.cli).toBe("pi");
    expect(agent?.autoExit).toBe(true);
  });
  test("parses yaml-list frontmatter and thinking-level alias", () => {
    const agent = parseAgentFile(
      "---\nname: qa\ntools:\n  - read\n  - bash\nextensions:\n  - ketch.ts\nthinking-level: high\n---\nBody.",
      "project",
      "/x/qa.md",
    );
    expect(agent?.tools).toEqual(["read", "bash"]);
    expect(agent?.extensions).toEqual(["ketch.ts"]);
    expect(agent?.thinking).toBe("high");
  });
  test("returns null without frontmatter", () => {
    expect(parseAgentFile("no frontmatter", "user", "/x/a.md")).toBeNull();
  });

  test("falls back to filename stem when name is missing", () => {
    const agent = parseAgentFile("---\ndescription: no explicit name\n---\nbody", "user", "/x/fallback-agent.md");
    expect(agent?.name).toBe("fallback-agent");
    expect(agent?.description).toBe("no explicit name");
  });

  test("keeps explicit frontmatter name over filename stem", () => {
    const agent = parseAgentFile("---\nname: explicit-name\n---\nbody", "user", "/x/fallback-agent.md");
    expect(agent?.name).toBe("explicit-name");
  });
});

describe("findProjectAgentsDir", () => {
  test("walks up to .pi/agent/agents", () => {
    expect(findProjectAgentsDir(join(projectDir, ".pi", "agent"))).toBe(
      join(projectDir, ".pi", "agent", "agents"),
    );
  });
  test("null when none above", () => {
    expect(findProjectAgentsDir(tmpdir())).toBeNull();
  });
});

describe("discoverAgents", () => {
  test("project beats user beats bundled", () => {
    const agents = discoverAgents(projectDir);
    const scout = agents.find((a) => a.name === "scout");
    expect(scout?.source).toBe("project");
    expect(scout?.systemPrompt).toContain("PROJECT");
    expect(agents.find((a) => a.name === "project-only")?.source).toBe("project");
    // bundled agents ship with the extension dir
    const bundledNames = ["planner", "worker", "visual-tester"];
    for (const name of bundledNames) {
      expect(agents.find((a) => a.name === name)?.source).toBe("bundled");
    }
    // bundled reviewer was removed; the user fixture supplies it
    const reviewer = agents.find((a) => a.name === "reviewer");
    expect(reviewer?.source).toBe("user");
    // deterministic name set, sorted
    // (brief's array omitted "worker", contradicting the bundledNames loop above
    // and the shipped agents/worker.md — completed here; see task report)
    expect(agents.map((a) => a.name)).toEqual([
      "planner", "project-only", "reviewer", "scout", "visual-tester", "worker",
    ]);
  });

  test("skips a subdirectory named evil.md instead of throwing", () => {
    // a directory that looks like an agent file must not crash discovery (EISDIR)
    mkdirSync(join(agentRoot, "agents", "evil.md"));
    const agents = discoverAgents(projectDir);
    expect(agents.map((a) => a.name)).toEqual([
      "planner", "project-only", "reviewer", "scout", "visual-tester", "worker",
    ]);
    expect(agents.find((a) => a.name === "evil")).toBeUndefined();
  });

  test("loads a symlinked agent file (nix/home-manager deploys symlinks)", () => {
    // real fixture lives in a temp subdir; the agents dir only holds a symlink
    const realDir = mkdtempSync(join(tmpdir(), "pipelines-real-"));
    const realPath = join(realDir, "linked-real.md");
    writeFileSync(realPath, "---\nname: linked\ndescription: via symlink\n---\nYou are LINKED.\n");
    const linkPath = join(agentRoot, "agents", "linked.md");
    symlinkSync(realPath, linkPath);
    try {
      const agents = discoverAgents(projectDir);
      const linked = agents.find((a) => a.name === "linked");
      expect(linked?.source).toBe("user");
      expect(linked?.systemPrompt).toBe("You are LINKED.");
    } finally {
      unlinkSync(linkPath);
    }
  });

  test("skips a symlink pointing at a directory without throwing", () => {
    // a *.md symlink to a directory must not crash discovery — skipped like evil.md
    const linkPath = join(agentRoot, "agents", "dirlink.md");
    symlinkSync(projectDir, linkPath);
    try {
      const agents = discoverAgents(projectDir);
      expect(agents.map((a) => a.name)).toEqual([
        "planner", "project-only", "reviewer", "scout", "visual-tester", "worker",
      ]);
      expect(agents.find((a) => a.name === "dirlink")).toBeUndefined();
    } finally {
      unlinkSync(linkPath);
    }
  });
});

describe("bundledAgentsDir", () => {
  test("points inside extension dir", () => {
    expect(bundledAgentsDir()).toBe(join(import.meta.dir, "agents"));
  });
});
