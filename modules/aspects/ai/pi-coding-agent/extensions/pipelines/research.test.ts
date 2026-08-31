// extensions/pipelines/research.test.ts
import { describe, expect, test } from "bun:test";
import { buildResearchTask, chooseResearchAgent } from "./research.ts";

describe("chooseResearchAgent", () => {
  test("maps doc questions to librarian", () => {
    expect(chooseResearchAgent("Check the pi extensions docs for setWidget")).toBe("librarian");
  });
  test("maps codebase questions to explore", () => {
    expect(chooseResearchAgent("explore the codebase and find where auth lives")).toBe("explore");
  });
  test("maps review requests to reviewer", () => {
    expect(chooseResearchAgent("security review of this diff")).toBe("reviewer");
  });
  test("maps planning to plan", () => {
    expect(chooseResearchAgent("design an approach and plan the migration")).toBe("plan");
  });
  test("maps implementation to coder", () => {
    expect(chooseResearchAgent("implement the fix and write tests")).toBe("coder");
  });
  test("null when no hint matches", () => {
    expect(chooseResearchAgent("hello world")).toBeNull();
  });
  test("highest keyword score wins", () => {
    // both "plan" and "design" hit the plan agent → highest score wins overall
    expect(chooseResearchAgent("plan the design")).toBe("plan");
  });
  test("word-boundary matching avoids false hits inside larger words", () => {
    expect(chooseResearchAgent("how do I use a fixture here")).toBeNull(); // "fixture" ≠ "fix"
    expect(chooseResearchAgent("preview the deployment")).toBeNull(); // "preview" ≠ "review"
    expect(chooseResearchAgent("prefix")).toBeNull(); // "prefix" ≠ "fix"
  });
  test("word-boundary matching still routes standalone keywords", () => {
    expect(chooseResearchAgent("fix the broken build")).toBe("coder");
  });
});

describe("buildResearchTask", () => {
  test("frames request with supervisor handoff contract", () => {
    const text = buildResearchTask("How does auth reach the database?");
    expect(text).toContain("research subagent");
    expect(text).toContain("How does auth reach the database?");
    expect(text).toContain("300 words");
    expect(text).toContain("Key findings");
  });
});
