// extensions/pipelines/session-model.test.ts
import { describe, expect, test } from "bun:test";
import { createSessionModel, envModel, modelString, safeModelFrom } from "./session-model.ts";

describe("modelString", () => {
  test("namespaces provider and id", () => {
    expect(modelString({ provider: "opencode-go", id: "glm-5.3" })).toBe("opencode-go/glm-5.3");
  });

  test("id only when provider is absent", () => {
    expect(modelString({ id: "glm-5.3" })).toBe("glm-5.3");
  });

  test("undefined for empty input", () => {
    expect(modelString(undefined)).toBeUndefined();
    expect(modelString(null)).toBeUndefined();
    expect(modelString({})).toBeUndefined();
  });
});

describe("envModel", () => {
  test("prefers provider/id", () => {
    expect(envModel({ PI_MODEL: "glm-5.3", PI_PROVIDER: "opencode-go" } as NodeJS.ProcessEnv)).toBe("opencode-go/glm-5.3");
  });

  test("id alone, and undefined when unset", () => {
    expect(envModel({ PI_MODEL: "glm-5.3" } as NodeJS.ProcessEnv)).toBe("glm-5.3");
    expect(envModel({} as NodeJS.ProcessEnv)).toBeUndefined();
  });
});

describe("createSessionModel", () => {
  test("seeds from the initial value and keeps the last observed model", () => {
    const m = createSessionModel("ollama/glm-5.3");
    expect(m.current()).toBe("ollama/glm-5.3");
    m.observe({ provider: "opencode-go", id: "glm-5.3" });
    expect(m.current()).toBe("opencode-go/glm-5.3");
  });

  test("ignores observations without a model id", () => {
    const m = createSessionModel("opencode-go/glm-5.3");
    m.observe({});
    m.observe(undefined);
    expect(m.current()).toBe("opencode-go/glm-5.3");
  });
});

describe("safeModelFrom", () => {
  test("reads model off a context", () => {
    expect(safeModelFrom({ model: { provider: "openai-codex", id: "gpt-5.4" } })).toEqual({
      provider: "openai-codex",
      id: "gpt-5.4",
    });
  });

  test("stale pi contexts throw — swallowed", () => {
    const stale = {
      get model() {
        throw new Error("stale context");
      },
    };
    expect(safeModelFrom(stale)).toBeUndefined();
  });
});
