import type { PipelineEngine } from "./pipeline.ts";

export function applyDashboardAction(
  engine: PipelineEngine,
  controls: { cancelPipeline: (id: string) => void; stopStage: (pipelineId: string, stageId: string) => void },
  action: string,
  pipelineId: string,
  stageId?: string,
  snapshot?: { status: string; attempt: number },
): void {
  const pipeline = engine.get(pipelineId);
  if (!pipeline || pipeline.status !== "active") return;
  if (action === "cancel-pipeline") {
    controls.cancelPipeline(pipelineId);
    return;
  }
  const stage = pipeline.stages.find((candidate) => candidate.id === stageId);
  if (!stage || !snapshot || stage.status !== snapshot.status || stage.attempt !== snapshot.attempt) return;
  if (action === "resume") {
    if (stage.status === "waiting-gate") engine.proceedGate(pipelineId, stage.id);
    else if (stage.status === "waiting-help") {
      controls.stopStage(pipelineId, stage.id);
      engine.resumeHelped(pipelineId, stage.id);
    }
  } else if (action === "cancel-stage" &&
    (stage.status === "running" || stage.status === "queued" || stage.status === "waiting-help")) {
    controls.stopStage(pipelineId, stage.id);
    engine.failStage(pipelineId, stage.id, "cancelled from TUIOS dashboard");
  }
}
