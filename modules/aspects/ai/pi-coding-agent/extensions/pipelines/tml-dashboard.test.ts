import { afterEach, describe, expect, test } from "bun:test";
import { spawnSync } from "node:child_process";
import { mkdtempSync, writeFileSync, chmodSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { WidgetModel } from "./widget-render.ts";
import { buildTmlDocument, registerTmlDashboard } from "./tml-dashboard.ts";

const fixture = (): WidgetModel => ({ pipelines: [{ id: "pipe'unsafe", name: "Release {not an action}", status: "active", createdAt: Date.now(), stages: [
  { id: "build", task: "Build app", dependsOn: [], gate: false, retries: 0, attempt: 1, status: "done", result: "Review this output" },
  { id: "approve", task: "Approve release", dependsOn: ["build"], gate: true, retries: 0, attempt: 0, status: "waiting-gate" },
  { id: "help", task: "Need direction", dependsOn: [], gate: false, retries: 0, attempt: 1, status: "waiting-help", error: "Blocked" },
] }], runs: [] });

const wait = (ms = 100) => new Promise((resolve) => setTimeout(resolve, ms));
let cleanups: (() => Promise<void>)[] = [];
afterEach(async () => { for (const cleanup of cleanups.reverse()) await cleanup(); cleanups = []; });

function harness(model = fixture(), delay = 0, output: unknown[] = [], exitCode?: number, recovery = false, patchDelay = 0, scenario: { resistant?: "patch" | "close" | "events"; stale?: boolean; splitUtf8?: boolean } = {}) {
  const dir = mkdtempSync(join(tmpdir(), "pipeline-tml-"));
  const log = join(dir, "calls");
  const cli = join(dir, "tuios");
  writeFileSync(cli, `#!/usr/bin/env bun
const args = process.argv.slice(2);
const input = await Bun.stdin.text();
const previous = await Bun.file('${log}').exists() ? await Bun.file('${log}').text() : '';
await Bun.write('${log}', previous + JSON.stringify({args,input,pid:process.pid}) + '\\n');
if (args[1] === ${JSON.stringify(scenario.resistant) ?? "undefined"}) {
  process.on('SIGTERM', () => {});
  setInterval(() => {}, 1000);
  await new Promise(() => {});
}
if (${recovery} && args[1] === 'close') await Bun.sleep(400);
if (args[1] === 'patch') await Bun.sleep(${patchDelay});
if (args[1] === 'show') {
  await Bun.sleep(${delay});
  console.log(JSON.stringify({type:'tml_opened',surface:'tml-owned',window_id:'window'}));
  if (${scenario.resistant === "events"}) process.on('SIGTERM', () => {});
  if (${!!scenario.stale} && !previous.includes('show')) {
    console.log('{broken');
    setTimeout(() => console.log('{stale'), 300);
  }
  if (!${recovery} || !previous.includes('show')) {
    for (const event of ${JSON.stringify(output)}) {
      const line = Buffer.from(JSON.stringify(event) + '\\n');
      if (${!!scenario.splitUtf8}) {
        const split = line.indexOf(Buffer.from('编')) + 1;
        process.stdout.write(line.subarray(0, split));
        await Bun.sleep(50);
        process.stdout.write(line.subarray(split));
      } else console.log(JSON.stringify(event));
    }
  }
  if (${recovery}) setTimeout(() => console.log(JSON.stringify({type:'tml-event',tml:{surface:'tml-owned',name:'cancel-pipeline',value:{pipelineId:'pl'},version:1}})), 700);
  ${exitCode === undefined ? "setTimeout(()=>{},60000);" : recovery ? `if (previous.includes('show')) setTimeout(()=>{},60000); else process.exit(${exitCode});` : `process.exit(${exitCode});`}
}
`);
  chmodSync(cli, 0o755);
  const old = { PATH: process.env.PATH, TUIOS_ENV: process.env.TUIOS_ENV, TUIOS_SESSION: process.env.TUIOS_SESSION };
  process.env.PATH = `${dir}:${process.env.PATH}`;
  process.env.TUIOS_ENV = "1";
  process.env.TUIOS_SESSION = "session";
  const handlers: Record<string, Function> = {};
  const commands: Record<string, any> = {};
  const warnings: string[] = [];
  const actions: any[] = [];
  registerTmlDashboard({ on: (name: string, fn: Function) => { handlers[name] = fn; }, registerCommand: (name: string, cmd: any) => { commands[name] = cmd; } } as any, () => model, (...args) => actions.push(args));
  const ctx = { hasUI: true, ui: { notify: (text: string) => warnings.push(text) } };
  cleanups.push(async () => { await handlers.session_shutdown?.(); await wait(150); Object.assign(process.env, old); for (const [key, value] of Object.entries(old)) if (value === undefined) delete process.env[key]; rmSync(dir, { recursive: true, force: true }); });
  const calls = () => { try { return readFileSync(log, "utf8").trim().split("\n").filter(Boolean).map((s) => JSON.parse(s)); } catch { return []; } };
  return { handlers, commands, ctx, calls, warnings, actions, cli, model };
}

describe("TML document", () => {
  test.skipIf(!Bun.which("tuios"))("populated document passes the real TML validator", () => {
    const result = spawnSync("tuios", ["tml", "validate", "-"], { input: JSON.stringify(buildTmlDocument(fixture())), encoding: "utf8" });
    expect(result.stderr).toBe("");
    expect(result.status).toBe(0);
  });
  test("binds context and action objects, never user text in expressions", () => {
    const doc = buildTmlDocument(fixture());
    expect(doc.type).toBe("tml");
    expect(doc.version).toBe(1);
    const gate = doc.state.rows.find((row: any) => row.value.stageId === "approve")!;
    expect(gate.resume).toBe(true);
    expect(gate.cancelStage).toBe(false);
    expect(gate.context).toContain("Review this output");
    expect(gate.task).toBe("Approve release");
    expect(gate.value).toEqual({ pipelineId: "pipe'unsafe", stageId: "approve", status: "waiting-gate", attempt: 0 });
    expect(JSON.stringify(doc.children)).not.toContain("unsafe");
    expect(doc.state.rows[0].cancelPipeline).toBe(true);
  });
  test("bounds documents and patches and keeps widget finished grace", () => {
    const model = fixture();
    model.pipelines = Array.from({ length: 500 }, (_, i) => ({ ...model.pipelines[0], id: String(i), name: "😀".repeat(10000) }));
    const doc = buildTmlDocument(model);
    expect(doc.state.rows.length).toBeLessThanOrEqual(100);
    expect(Buffer.byteLength(JSON.stringify(doc))).toBeLessThanOrEqual(256 * 1024);
    expect(Buffer.byteLength(JSON.stringify([{ op: "replace", path: "/rows", value: doc.state.rows }]))).toBeLessThanOrEqual(64 * 1024);
    model.pipelines = [{ ...model.pipelines[0], status: "complete", finishedAt: Date.now() - 61000 }];
    expect(buildTmlDocument(model).state.rows).toHaveLength(0);
  });
});

describe("TML lifecycle", () => {
  test("registers without resources, starts once, patches stdin, closes only owned surface", async () => {
    const h = harness();
    await wait();
    expect(h.calls()).toHaveLength(0);
    h.handlers.session_start({}, h.ctx);
    h.handlers.session_start({}, h.ctx);
    await wait(250);
    expect(h.calls().filter((c) => c.args[1] === "show")).toHaveLength(1);
    expect(h.calls()[0].args).toEqual(["tml", "show", "-", "--pane", "--events", "-s", "session"]);
    h.model.pipelines[0].stages[1].status = "done";
    await wait(1100);
    const patch = h.calls().find((c) => c.args[1] === "patch");
    expect(patch.args).toEqual(["tml", "patch", "tml-owned", "-"]);
    expect(JSON.parse(patch.input)[0].path).toBe("/rows");
    h.handlers.session_shutdown();
    h.handlers.session_shutdown();
    await wait(200);
    expect(h.calls().filter((c) => c.args[1] === "close").map((c) => c.args[2])).toEqual(["tml-owned"]);
  });
  test("does not start outside TUIOS or with an empty session", async () => {
    const h = harness();
    process.env.TUIOS_SESSION = " ";
    h.handlers.session_start({}, h.ctx);
    await wait(150);
    expect(h.calls()).toHaveLength(0);
  });
  test("routes only known, well-formed events from its own surface", async () => {
    const event = (surface: string, name: string, value: unknown) => ({ type: "tml-event", tml: { surface, name, value, version: 1 } });
    const h = harness(fixture(), 0, [
      event("tml-other", "resume", { pipelineId: "pl", stageId: "gate" }),
      event("tml-owned", "unknown", { pipelineId: "pl", stageId: "gate" }),
      event("tml-owned", "resume", { pipelineId: "pl" }),
      event("tml-owned", "resume", { pipelineId: "pl", stageId: "gate" }),
      event("tml-owned", "resume", { pipelineId: "pl", stageId: "gate", status: "waiting-gate", attempt: -1 }),
      event("tml-owned", "resume", { pipelineId: "pl", stageId: "gate", status: "waiting-gate", attempt: 0 }),
      event("tml-owned", "cancel-stage", { pipelineId: "pl", stageId: "work", status: "running", attempt: 1 }),
      event("tml-owned", "cancel-pipeline", { pipelineId: "pl" }),
    ]);
    h.handlers.session_start({}, h.ctx);
    await wait(250);
    expect(h.actions).toEqual([
      ["resume", "pl", "gate", { status: "waiting-gate", attempt: 0 }],
      ["cancel-stage", "pl", "work", { status: "running", attempt: 1 }],
      ["cancel-pipeline", "pl", undefined, undefined],
    ]);
  });
  test("dismissal stays closed until explicitly reopened", async () => {
    const h = harness(fixture(), 0, [{ type: "tml-event", tml: { surface: "tml-owned", name: "close", reason: "dismissed", version: 1 } }]);
    h.handlers.session_start({}, h.ctx);
    await wait(1200);
    expect(h.calls().filter((c) => c.args[1] === "show")).toHaveLength(1);
    await h.commands["pipeline-dashboard"].handler();
    await wait(250);
    expect(h.calls().filter((c) => c.args[1] === "show")).toHaveLength(2);
    expect(h.warnings).toHaveLength(0);
  });
  test("a broken event stream closes the owned surface and warns once", async () => {
    const h = harness(fixture(), 0, [], 1);
    h.handlers.session_start({}, h.ctx);
    await wait(350);
    expect(h.calls().filter((c) => c.args[1] === "close").map((c) => c.args[2])).toEqual(["tml-owned"]);
    expect(h.warnings).toHaveLength(1);
    await wait(1100);
    expect(h.calls().filter((c) => c.args[1] === "show")).toHaveLength(1);
  });
  test("reopening during slow cleanup keeps the replacement event stream alive", async () => {
    const h = harness(fixture(), 0, [], 1, true);
    h.handlers.session_start({}, h.ctx);
    await wait(150);
    await h.commands["pipeline-dashboard"].handler();
    await wait(850);
    expect(h.calls().filter((c) => c.args[1] === "show")).toHaveLength(2);
    expect(h.actions).toEqual([["cancel-pipeline", "pl", undefined, undefined]]);
  });
  test("retired stream callbacks cannot close the replacement dashboard", async () => {
    const h = harness(fixture(), 0, [], undefined, true, 0, { stale: true });
    h.handlers.session_start({}, h.ctx);
    await wait(150);
    await h.commands["pipeline-dashboard"].handler();
    await wait(850);
    expect(h.calls().filter((c) => c.args[1] === "show")).toHaveLength(2);
    expect(h.actions).toEqual([["cancel-pipeline", "pl", undefined, undefined]]);
  });
  test("routes stage IDs whose UTF-8 codepoints cross stream chunks", async () => {
    const h = harness(fixture(), 0, [{type:"tml-event", tml:{surface:"tml-owned",name:"resume",value:{pipelineId:"pl",stageId:"编译",status:"waiting-help",attempt:1},version:1}}], undefined, false, 0, {splitUtf8:true});
    h.handlers.session_start({}, h.ctx);
    await wait(250);
    expect(h.actions).toEqual([["resume", "pl", "编译", {status:"waiting-help",attempt:1}]]);
  });
  for (const resistant of ["patch", "close", "events"] as const) {
    test(`shutdown reaps a ${resistant} process that ignores SIGTERM`, async () => {
      const h = harness(fixture(), 0, [], undefined, false, 0, {resistant});
      h.handlers.session_start({}, h.ctx);
      await wait(200);
      if (resistant === "patch") {
        h.model.pipelines[0].stages[1].status = "done";
        await wait(1000);
      }
      const shutdown = h.handlers.session_shutdown();
      let deadline: ReturnType<typeof setTimeout>;
      const bounded = new Promise<boolean>((resolve) => { deadline = setTimeout(() => resolve(false), 7000); });
      const completed = await Promise.race([shutdown.then(() => true), bounded]);
      clearTimeout(deadline!);
      if (!completed) {
        for (const call of h.calls()) { try { process.kill(call.pid, "SIGKILL"); } catch {} }
        await shutdown;
      }
      const alive = h.calls().filter((call) => { try { process.kill(call.pid, 0); return true; } catch { return false; } });
      for (const call of alive) { try { process.kill(call.pid, "SIGKILL"); } catch {} }
      expect(completed).toBe(true);
      expect(alive).toHaveLength(0);
    }, 10000);
  }
  test("shutdown waits for a pending patch before closing the surface", async () => {
    const h = harness(fixture(), 0, [], undefined, false, 600);
    h.handlers.session_start({}, h.ctx);
    await wait(200);
    h.model.pipelines[0].stages[1].status = "done";
    await wait(1000);
    expect(h.calls().some((c) => c.args[1] === "patch")).toBe(true);
    await h.handlers.session_shutdown();
    expect(h.calls().filter((c) => c.args[1] === "close").map((c) => c.args[2])).toEqual(["tml-owned"]);
  });
  test("closes a late opening before shutdown resolves", async () => {
    const h = harness(fixture(), 250);
    h.handlers.session_start({}, h.ctx);
    await wait(100);
    await h.handlers.session_shutdown();
    expect(h.calls().filter((c) => c.args[1] === "close")).toHaveLength(1);
  });
});
