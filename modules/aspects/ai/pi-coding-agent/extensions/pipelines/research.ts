// extensions/pipelines/research.ts

export const RESEARCH_AGENT_HINTS: { agent: string; keywords: string[] }[] = [
  { agent: "librarian", keywords: ["docs", "documentation", "library", "api reference", "how does"] },
  { agent: "explore", keywords: ["explore", "codebase", "structure", "where", "find", "scan"] },
  { agent: "reviewer", keywords: ["review", "audit", "security", "vulnerability", "quality"] },
  { agent: "plan", keywords: ["plan", "design", "architecture", "approach", "strategy", "migration"] },
  { agent: "coder", keywords: ["implement", "fix", "write", "refactor", "bug", "tests"] },
];

// Escape regex metacharacters so keywords match literally inside the pattern.
function escapeRegExp(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

export function chooseResearchAgent(task: string): string | null {
  let best: { agent: string; score: number } | null = null;
  for (const h of RESEARCH_AGENT_HINTS) {
    // Word-boundary matching (\b) so keywords like "fix" don't hit "prefix"/
    // "fixture" and "review" doesn't hit "preview" (review T10-1).
    const score = h.keywords.reduce(
      (n, k) => n + (new RegExp(`\\b${escapeRegExp(k)}\\b`, "i").test(task) ? 1 : 0),
      0,
    );
    if (score > 0 && (!best || score > best.score)) best = { agent: h.agent, score };
  }
  return best?.agent ?? null;
}

export function buildResearchTask(task: string): string {
  return [
    "You are a research subagent. Investigate the request below and return a concise supervisor handoff.",
    "",
    "Final answer requirements:",
    "- Key findings first, then relevant file paths (with line refs where useful), then one recommended next step.",
    "- No preamble, no restating the request. Max ~300 words.",
    "",
    `Request: ${task}`,
  ].join("\n");
}
