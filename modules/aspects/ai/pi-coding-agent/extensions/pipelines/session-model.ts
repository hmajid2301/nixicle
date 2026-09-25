// extensions/pipelines/session-model.ts
// Tracks the parent session's model so spawned children can inherit it when
// neither the stage nor the agent nor the config pins one.
//
// `ctx.model` throws on a stale context in pi, so every read goes through
// safeModelFrom().

export interface ModelLike {
  id?: string;
  provider?: string;
}

export function modelString(model: ModelLike | null | undefined): string | undefined {
  if (!model?.id) return undefined;
  return model.provider ? `${model.provider}/${model.id}` : model.id;
}

export function envModel(env: NodeJS.ProcessEnv = process.env): string | undefined {
  const id = env.PI_MODEL;
  if (!id) return undefined;
  const provider = env.PI_PROVIDER;
  return provider ? `${provider}/${id}` : id;
}

export function safeModelFrom(ctx: unknown): ModelLike | undefined {
  try {
    return (ctx as { model?: ModelLike } | undefined)?.model;
  } catch {
    return undefined;
  }
}

export interface SessionModel {
  observe(model: ModelLike | null | undefined): void;
  current(): string | undefined;
}

export function createSessionModel(initial?: string): SessionModel {
  let current = initial;
  return {
    observe(model) {
      const next = modelString(model);
      if (next) current = next;
    },
    current() {
      return current;
    },
  };
}
