import { expect, test } from "bun:test";
import { execFileSync } from "node:child_process";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

for (const mode of ["pane", "headless"] as const) {
for (const action of ["pipeline_cancel_stage", "pipeline_cancel", "subagent_resume", "pipeline_proceed", "dashboard", "subagent_resume_credit", "dashboard_resume_credit"] as const) {
  test(`${action} releases the ${mode} run retained by a help request`, () => {
    const dir = mkdtempSync(join(tmpdir(), "pipeline-ownership-"));
    const creditGated = action.endsWith("_credit");
    writeFileSync(join(dir, "pi"), `#!/bin/sh
if [ "$PI_SUBAGENT_NAME" = credit ]; then
  printf '%s\\n' '{"type":"error","errorMessage":"Insufficient balance","isCreditLimit":true}' > "$PI_SUBAGENT_EXIT_FILE"
else
  printf '%s\\n' '{"type":"ping","name":"scout","message":"Need guidance"}' > "$PI_SUBAGENT_EXIT_FILE"
fi
`, { mode: 0o755 });
    writeFileSync(join(dir, "herdr"), `#!/bin/sh
case "$1 $2" in
  'pane current') printf '%s\\n' '{"result":{"pane":{"pane_id":"parent","tab_id":"tab","workspace_id":"workspace"}}}' ;;
  'worktree list') printf '%s\\n' '{"result":{"type":"worktree_list","worktrees":[]}}' ;;
  'pane list') printf '%s\\n' '{"result":{"type":"pane_list","panes":[]}}' ;;
  'tab create') printf '%s\\n' '{"result":{"root_pane":{"pane_id":"child"},"tab":{"tab_id":"agents"}}}' ;;
  'pane run') /bin/sh -c "$4" ;;
  'pane get') printf '%s\\n' '{"result":{"pane":{"pane_id":"child"}}}' ;;
  'pane close') printf '%s\\n' "$3" >> "$FIXTURE_CLOSE_LOG" ;;
esac
`, { mode: 0o755 });
    writeFileSync(join(dir, "tuios"), `#!${process.execPath}
const args = process.argv.slice(2);
const input = await Bun.stdin.text();
if (args[1] === 'show') {
  const row = JSON.parse(input).state.rows.find((row) => row.status === 'waiting-help');
  console.log(JSON.stringify({type:'tml_opened',surface:'tml-fixture',window_id:'fixture'}));
  console.log(JSON.stringify({type:'tml-event',tml:{surface:'tml-fixture',name:${JSON.stringify(creditGated ? "resume" : "cancel-stage")},value:row.value,version:1}}));
  setTimeout(() => {}, 60000);
}
`, { mode: 0o755 });
    try {
      const output = execFileSync(process.execPath, ["--eval", `
        import assert from "node:assert/strict";
        import { readFileSync, writeFileSync } from "node:fs";
        import extension from ${JSON.stringify(join(import.meta.dir, "index.ts"))};
        import { listRuns, stopRun } from ${JSON.stringify(join(import.meta.dir, "backends.ts"))};
        const tools = new Map();
        const handlers = [];
        extension({ on(name, fn) { handlers.push({name,fn}); }, registerCommand() {}, registerTool(tool) { tools.set(tool.name, tool); }, sendMessage() {}, sendUserMessage() {} });
        const started = await tools.get("pipeline").execute("", { name: "Help", stages: [{ id: "help", agent: "scout", task: "Ask for help" }, ...(${creditGated} ? [{ id: "credit", agent: "scout", task: "Exhaust credits" }] : [])] });
        const pipelineId = started.details.id;
        let waiting = false;
        for (let i = 0; i < 100; i++) {
          const status = await tools.get("pipeline_status").execute("", { pipelineId });
          if (status.content[0].text.includes("waiting-help") && (!${creditGated} || status.content[0].text.includes("credit: failed"))) { waiting = true; break; }
          await Bun.sleep(20);
        }
        assert.equal(waiting, true, "stage should reach waiting-help");
        const retained = listRuns().find((run) => run.req.name === "help");
        assert.ok(retained, "backend should retain the pinged run");
        if (${creditGated}) writeFileSync(process.env.FIXTURE_CLOSE_LOG, "");
        if (${JSON.stringify(action)}.startsWith("dashboard")) {
          process.env.TUIOS_ENV = "1";
          process.env.TUIOS_SESSION = "fixture";
          for (const handler of handlers.filter((h) => h.name === "session_start")) await handler.fn({}, {hasUI:false, ui:{notify() {}}});
          for (let i = 0; i < 100 && listRuns().some((run) => run.handle.id === retained.handle.id); i++) await Bun.sleep(20);
          for (const handler of handlers.filter((h) => h.name === "session_shutdown")) await handler.fn();
        } else {
          await tools.get(${JSON.stringify(creditGated ? "subagent_resume" : action)}).execute("", { pipelineId, stageId: "help", message: "Continue" });
        }
        assert.equal(listRuns().some((run) => run.handle.id === retained.handle.id), false, "old help run must be forgotten");
        if (${creditGated}) {
          const status = await tools.get("pipeline_status").execute("", { pipelineId });
          assert.ok(status.content[0].text.includes("help: queued"), "credit-gated help stage must stay queued");
          assert.equal(listRuns().length, 0, "credit gate must prevent a replacement run");
        }
        if (${JSON.stringify(mode)} === "pane") assert.equal(readFileSync(process.env.FIXTURE_CLOSE_LOG, "utf8"), "child\\n", "retained pane must close exactly once");
        for (const run of listRuns()) stopRun(run.handle.id);
        console.log("released");
      `], {
        encoding: "utf8", timeout: 10000,
        env: { ...process.env, PATH: `${dir}:${process.env.PATH}`, PIPELINES_DIR: join(dir, "state"), HERDR_ENV: mode === "pane" ? "1" : "", HERDR_BIN_PATH: join(dir, "herdr"), TUIOS_ENV: "", FIXTURE_CLOSE_LOG: join(dir, "closed") },
      });
      expect(output.trim()).toBe("released");
    } finally {
      rmSync(dir, { recursive: true, force: true });
    }
  });
}
}
