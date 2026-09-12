import { describe, expect, test } from "bun:test";
import { isSafeCommand } from "./command-safety";

describe("isSafeCommand", () => {
	test("allows read-only commands used during plan exploration", () => {
		expect(isSafeCommand("git status --short")).toBe(true);
		expect(isSafeCommand("nix eval .#nixosConfigurations.rpi.config.system.build.toplevel.drvPath")).toBe(true);
		expect(isSafeCommand("grep -R 'TODO' modules")).toBe(true);
	});

	test("blocks destructive commands even when they start with an allowlisted command", () => {
		expect(isSafeCommand("rm -rf result")).toBe(false);
		expect(isSafeCommand("echo hi > generated.txt")).toBe(false);
		expect(isSafeCommand("git commit -m nope")).toBe(false);
	});

	test("ignores destructive words inside quoted grep patterns", () => {
		expect(isSafeCommand("grep 'rm -rf' README.md")).toBe(true);
	});
});
