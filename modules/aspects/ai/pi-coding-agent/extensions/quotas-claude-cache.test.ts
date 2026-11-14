import { afterEach, beforeEach, expect, test } from "bun:test";
import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fetchClaudeUsage } from "./quotas.ts";

const payload = { five_hour: { utilization: 35, resets_at: "2026-11-18T14:50:00Z" } };
const realFetch = globalThis.fetch;
let dir: string;
let calls: number;

function stubFetch(status: number, headers: Record<string, string> = {}): void {
	globalThis.fetch = (async () => {
		calls++;
		return new Response(status === 200 ? JSON.stringify(payload) : "", { status, headers });
	}) as typeof fetch;
}

beforeEach(() => {
	dir = mkdtempSync(join(tmpdir(), "quotas-"));
	process.env.XDG_CACHE_HOME = join(dir, "cache");
	process.env.CLAUDE_CONFIG_DIR = join(dir, "claude");
	mkdirSync(process.env.CLAUDE_CONFIG_DIR);
	writeFileSync(
		join(process.env.CLAUDE_CONFIG_DIR, ".credentials.json"),
		JSON.stringify({ claudeAiOauth: { accessToken: "t" } }),
	);
	calls = 0;
});

afterEach(() => {
	globalThis.fetch = realFetch;
	rmSync(dir, { recursive: true, force: true });
});

test("a fresh result is shared instead of fetched again", async () => {
	stubFetch(200);
	expect("error" in (await fetchClaudeUsage())).toBe(false);
	expect("error" in (await fetchClaudeUsage())).toBe(false);
	expect(calls).toBe(1);
});

test("a 429 backs off for retry-after and does not call the endpoint again", async () => {
	stubFetch(429, { "retry-after": "300" });
	expect(await fetchClaudeUsage()).toEqual({ error: "HTTP 429" });
	expect(await fetchClaudeUsage()).toEqual({ error: "Claude usage rate-limited" });
	expect(calls).toBe(1);
});
