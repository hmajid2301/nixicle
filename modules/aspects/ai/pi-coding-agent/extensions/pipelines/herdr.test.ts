// extensions/pipelines/herdr.test.ts
import { afterAll, describe, expect, test } from "bun:test";
import { execFileSync } from "node:child_process";
import { chmodSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { buildTabCreateArgs, currentPaneInfo, extractRootPaneId, herdrExec, paneGet, paneReadAsync, parsePaneGet } from "./herdr.ts";

const fixtureDir = mkdtempSync(join(tmpdir(), "pipelines herdr "));
const cli = join(fixtureDir, "herdr shim");
writeFileSync(cli, `#!/bin/sh
case "$1 $2" in
  'pane current')
    printf '%s\\n' '{"result":{"pane":{"pane_id":"child","tab_id":"child-tab","workspace_id":"child-workspace"}}}' ;;
  'pane read')
    printf '%s\\n' "$@" ;;
  'pane get')
    case "$3" in
      present) printf '%s\\n' '{"result":{"pane":{"pane_id":"present"}}}' ;;
      missing) printf '%s\\n' '{"error":{"code":"pane_not_found"}}' >&2; exit 1 ;;
      missing-stdout) printf '%s\\n' '{"error":{"code":"not_found"}}'; exit 1 ;;
      forbidden) printf '%s\\n' '{"error":{"code":"forbidden"}}' >&2; exit 1 ;;
      disconnected) printf '%s\\n' 'connection refused' >&2; exit 1 ;;
      *) printf '%s\\n' 'invalid json' ;;
    esac ;;
  *) printf '%s\\n' "$@" ;;
esac
`);
chmodSync(cli, 0o755);
writeFileSync(join(fixtureDir, "herdr"), "#!/bin/sh\nexit 99\n", { mode: 0o755 });
afterAll(() => rmSync(fixtureDir, { recursive: true, force: true }));

async function withCli(check: () => void | Promise<void>): Promise<void> {
  const previous = process.env.HERDR_BIN_PATH;
  const previousPath = process.env.PATH;
  process.env.HERDR_BIN_PATH = cli;
  process.env.PATH = fixtureDir;
  try {
    await check();
  } finally {
    if (previous === undefined) delete process.env.HERDR_BIN_PATH;
    else process.env.HERDR_BIN_PATH = previous;
    if (previousPath === undefined) delete process.env.PATH;
    else process.env.PATH = previousPath;
  }
}

function available(env: Record<string, string>): boolean {
  const isolatedEnv = { ...process.env };
  for (const key of ["HERDR_ENV", "TUIOS_ENV", "HERDR_BIN_PATH"]) delete isolatedEnv[key];
  return execFileSync(process.execPath, ["--eval", `
    import { isHerdrAvailable } from ${JSON.stringify(import.meta.dir + "/herdr.ts")};
    console.log(isHerdrAvailable());
  `], { env: { ...isolatedEnv, ...env }, encoding: "utf8" }).trim() === "true";
}

describe("TUIOS compatibility CLI", () => {
  test("sync execution honors the shim and preserves arguments", () => withCli(() => {
    expect(herdrExec(["pane", "run", "child", "echo 'two words'"])).toBe("pane\nrun\nchild\necho 'two words'\n");
  }));
  test("current identity comes from the destination, not inherited IDs", () => withCli(() => {
    expect(currentPaneInfo()).toEqual({ paneId: "child", tabId: "child-tab", workspaceId: "child-workspace" });
  }));
  test("async screen reads honor the shim and positional pane ID", () => withCli(async () => {
    expect(await paneReadAsync("child", 12)).toBe("pane\nread\nchild\n--source\nvisible\n--lines\n12\n");
  }));
  test("liveness separates missing panes from unavailable reads", () => withCli(async () => {
    expect(await paneGet("present")).toBe("present");
    expect(await paneGet("missing")).toBe("missing");
    expect(await paneGet("missing-stdout")).toBe("missing");
    expect(await paneGet("forbidden")).toBe("unavailable");
    expect(await paneGet("disconnected")).toBe("unavailable");
    expect(await paneGet("malformed")).toBe("unavailable");
  }));
});

describe("buildTabCreateArgs", () => {
  test("targets workspace, labels, cwd, no focus", () => {
    expect(buildTabCreateArgs("scout", "/repo", "ws1")).toEqual([
      "tab", "create", "--workspace", "ws1",
      "--label", "scout", "--cwd", "/repo", "--no-focus",
    ]);
  });
});

describe("extractRootPaneId", () => {
  test("reads result.root_pane.pane_id", () => {
    expect(extractRootPaneId(`{"result":{"root_pane":{"pane_id":"pane-7"}}}`)).toBe("pane-7");
  });
  test("throws on malformed output", () => {
    expect(() => extractRootPaneId("not json")).toThrow(/Unexpected herdr/);
    expect(() => extractRootPaneId(`{"result":{}}`)).toThrow(/Unexpected herdr/);
  });
});

describe("parsePaneGet", () => {
  test("present when pane_id matches", () => {
    expect(parsePaneGet(`{"result":{"pane":{"pane_id":"p1"}}}`, "p1")).toBe("present");
  });
  test("missing on pane_not_found error code", () => {
    expect(parsePaneGet(`{"error":{"code":"pane_not_found"}}`, "p1")).toBe("missing");
  });
  test("missing on not_found code", () => {
    expect(parsePaneGet(`{"error":{"code":"not_found"}}`, "p1")).toBe("missing");
  });
  test("unavailable otherwise", () => {
    expect(parsePaneGet(`{"result":{"pane":{"pane_id":"other"}}}`, "p1")).toBe("unavailable");
    expect(parsePaneGet(`{`, "p1")).toBe("unavailable");
  });
});

describe("isHerdrAvailable", () => {
  test("TUIOS uses its explicit shim path even with spaces", () => {
    expect(available({ TUIOS_ENV: "1", HERDR_BIN_PATH: cli })).toBe(true);
  });
  test("real Herdr still resolves herdr on PATH", () => {
    expect(available({ HERDR_ENV: "1", PATH: fixtureDir })).toBe(true);
  });
  test("no multiplexer remains headless even with a shim", () => {
    expect(available({ HERDR_BIN_PATH: cli })).toBe(false);
  });
  test("TUIOS without its compatibility shim does not select real Herdr on PATH", () => {
    expect(available({ TUIOS_ENV: "1", PATH: fixtureDir })).toBe(false);
  });
  test("missing shim is unavailable", () => {
    expect(available({ TUIOS_ENV: "1", HERDR_BIN_PATH: join(fixtureDir, "missing") })).toBe(false);
  });
});
