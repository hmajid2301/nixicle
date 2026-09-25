// extensions/pipelines/btw-controller.ts
// Stateful /btw side-thread lifecycle: launch, replace/close, and merge-back.
import { join } from "node:path";
import {
  buildContextDocument,
  buildMergeTranscript,
  clearMergeRequest,
  formatMergeMessage,
  mergeFileFor,
  readMergeRequest,
} from "./btw.ts";
import { newId } from "./ids.ts";
import type { ResolvedSpawn } from "./backends.ts";
import type { CompletionResult, RunHandle } from "./types.ts";

const BTW_INSTRUCTION =
  "You are in a /btw side thread. Answer the user's question using the parent conversation snapshot as reference. " +
  "The parent will not see this thread unless the user runs /btw-merge <prompt>.";

export interface BtwDeps {
  available(): boolean;
  /** Directory holding per-run exit sidecars; merge mailboxes sit beside them. */
  exitDir: string;
  makeRequest(id: string, question: string, systemPromptAppend: string, tools: string[] | undefined): ResolvedSpawn;
  spawn(req: ResolvedSpawn): RunHandle;
  sendMerge(message: string, prompt: string): void;
  closePane(paneId: string): void;
  tools?: string[];
}

export interface BtwController {
  start(question: string, sessionFile?: string): string;
  close(): boolean;
}

interface Active {
  id: string;
  handle: RunHandle;
  mergeFile: string;
}

export function createBtwController(deps: BtwDeps): BtwController {
  let active: Active | undefined;

  function close(): boolean {
    if (!active) return false;
    const current = active;
    active = undefined;
    try {
      void current.handle.interrupt().catch(() => {});
    } catch {
      // best effort — the side thread may already be gone
    }
    if (current.handle.paneId) {
      try {
        deps.closePane(current.handle.paneId);
      } catch {
        // best effort
      }
    }
    clearMergeRequest(current.mergeFile);
    return true;
  }

  function settle(id: string, handle: RunHandle, mergeFile: string, result: CompletionResult): void {
    if (active?.id !== id) {
      clearMergeRequest(mergeFile);
      return;
    }
    active = undefined;
    const request = readMergeRequest(mergeFile);
    clearMergeRequest(mergeFile);
    if (result.reason !== "done" || !request) return;
    const transcript = handle.sessionPath ? buildMergeTranscript(handle.sessionPath) : "";
    deps.sendMerge(formatMergeMessage(transcript), request.prompt);
  }

  function start(question: string, sessionFile?: string): string {
    if (!deps.available()) throw new Error("/btw requires a Herdr pane — start pi inside herdr.");
    const text = question.trim();
    if (!text) throw new Error("Usage: /btw <question>");
    close();
    const id = newId("btw");
    const context = sessionFile ? buildContextDocument(sessionFile) : "";
    const systemPromptAppend = context ? `${BTW_INSTRUCTION}\n\n${context}` : BTW_INSTRUCTION;
    const req = deps.makeRequest(id, text, systemPromptAppend, deps.tools);
    req.env = { ...(req.env ?? {}), PI_BTW: "1" };
    req.panePlacement = { mode: "split", direction: "down", maxPerTab: 1 };
    const mergeFile = mergeFileFor(join(deps.exitDir, `${id}.json`));
    clearMergeRequest(mergeFile);
    const handle = deps.spawn(req);
    active = { id, handle, mergeFile };
    void handle.completion
      .then((result) => settle(id, handle, mergeFile, result))
      .catch(() => {
        clearMergeRequest(mergeFile);
        if (active?.id === id) active = undefined;
      });
    return id;
  }

  return { start, close };
}
