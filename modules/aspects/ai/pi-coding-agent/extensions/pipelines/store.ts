// extensions/pipelines/store.ts
import { existsSync, readFileSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { subDir } from "./config.ts";
import type { PipelineState } from "./pipeline.ts";

export function savePipeline(p: PipelineState): void {
  writeFileSync(join(subDir("state"), `${p.id}.json`), JSON.stringify(p, null, 2));
}

export function deletePipeline(id: string): void {
  rmSync(join(subDir("state"), `${id}.json`), { force: true });
}

export function loadPipelines(): PipelineState[] {
  const dir = subDir("state");
  if (!existsSync(dir)) return [];
  return readdirSync(dir)
    .filter((f) => f.endsWith(".json"))
    .map((f) => {
      try {
        return JSON.parse(readFileSync(join(dir, f), "utf8")) as PipelineState;
      } catch {
        return null;
      }
    })
    .filter((p): p is PipelineState => p !== null);
}