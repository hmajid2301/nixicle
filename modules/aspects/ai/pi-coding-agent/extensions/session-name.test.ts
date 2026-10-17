import { expect, test } from "bun:test";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import sessionName from "./session-name.ts";

function setup() {
	const handlers = new Map<string, Function>();
	let name: string | undefined;
	let id = "first";
	let requests = 0;
	let prompt = "";
	let result = async () => ({ content: [{ type: "text", text: '"Fix login bug"' }], stopReason: "stop" });
	const ctx = {
		model: { id: "test-model" },
		sessionManager: {
			getSessionId: () => id,
			getBranch: () => [{ type: "message", message: { role: "user", content: [{ type: "text", text: prompt }] } }],
		},
		modelRegistry: {
			streamSimple: (_model: unknown, context: any) => {
				requests++;
				expect(context.messages[0].content).toBe(prompt.slice(0, 4000));
				return { result: () => result() };
			},
		},
		ui: { notify: () => {} },
	} as unknown as ExtensionContext;
	sessionName({
		on: (event: string, handler: Function) => handlers.set(event, handler),
		getSessionName: () => name,
		setSessionName: (value: string) => { name = value; },
	} as unknown as ExtensionAPI);
	return {
		ctx,
		emit: async () => { await handlers.get("agent_end")?.({}, ctx); },
		get name() { return name; },
		get requests() { return requests; },
		setName: (value: string) => { name = value; },
		setPrompt: (value: string) => { prompt = value; },
		switchSession: () => { id = "second"; name = undefined; },
		setResult: (value: typeof result) => { result = value; },
	};
}

test("names an unnamed session once from the first prompt", async () => {
	const app = setup();
	app.setPrompt("Fix the login bug");
	await app.emit();
	await app.emit();
	expect(app.name).toBe("Fix login bug");
	expect(app.requests).toBe(1);
});

test("preserves existing names without a model call", async () => {
	const app = setup();
	app.setPrompt("Fix login");
	app.setName("My title");
	await app.emit();
	expect(app.name).toBe("My title");
	expect(app.requests).toBe(0);
});

test("skips empty prompts and missing models", async () => {
	const app = setup();
	await app.emit();
	app.setPrompt("Fix login");
	app.ctx.model = undefined;
	await app.emit();
	expect(app.requests).toBe(0);
});

test("names a new session in the same process", async () => {
	const app = setup();
	app.setPrompt("Fix login");
	await app.emit();
	app.switchSession();
	await app.emit();
	expect(app.name).toBe("Fix login bug");
	expect(app.requests).toBe(2);
});

test("does not overwrite a manual name set during generation", async () => {
	const app = setup();
	app.setPrompt("Fix login");
	app.setResult(async () => {
		app.setName("Manual title");
		return { content: [{ type: "text", text: "Generated title" }], stopReason: "stop" };
	});
	await app.emit();
	expect(app.name).toBe("Manual title");
});

test("does not apply a title to a different session", async () => {
	const app = setup();
	app.setPrompt("Fix login");
	app.setResult(async () => {
		app.switchSession();
		return { content: [{ type: "text", text: "Wrong title" }], stopReason: "stop" };
	});
	await app.emit();
	expect(app.name).toBeUndefined();
});

test("handles model failure without repeated requests", async () => {
	const app = setup();
	app.setPrompt("Fix login");
	app.setResult(async () => { throw new Error("No credentials"); });
	await app.emit();
	await app.emit();
	expect(app.name).toBeUndefined();
	expect(app.requests).toBe(1);
});

test("rejects failed model output", async () => {
	const app = setup();
	app.setPrompt("Fix login");
	app.setResult(async () => ({ content: [{ type: "text", text: "Partial title" }], stopReason: "error" }));
	await app.emit();
	expect(app.name).toBeUndefined();
});
