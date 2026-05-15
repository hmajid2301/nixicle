/**
 * Stylix Theme — auto-applies on session start.
 * Theme JSON is generated from stylix base16 colors by nix
 * and deployed to ~/.pi/agent/themes/stylix.json.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export default function (pi: ExtensionAPI) {
	pi.on("session_start", async (_event, ctx) => {
		const result = ctx.ui.setTheme("stylix");
		if (!result.success) {
			ctx.ui.notify(`Stylix theme: ${result.error}`, "warning");
		}
	});
}
