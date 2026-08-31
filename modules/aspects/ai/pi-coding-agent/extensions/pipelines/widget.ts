// extensions/pipelines/widget.ts
// Dashboard widget: expanded while anything runs, collapsed one-liner while
// only waiting/lingering, removed when idle.
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { truncateToWidth } from "@mariozechner/pi-tui";
import { buildVM, collapsedLine, renderDashboard, type WidgetModel } from "./widget-render.ts";

export { buildVM } from "./widget-render.ts";
export type { WidgetModel } from "./widget-render.ts";

export function registerWidget(
	pi: ExtensionAPI,
	getModel: () => WidgetModel,
	opts: { collapsedDefault?: boolean } = {},
): void {
	let timer: ReturnType<typeof setInterval> | undefined;
	let tuiRef: { requestRender?: () => void } | undefined;

	const draw = (ctx: ExtensionContext): void => {
		if (!ctx.hasUI) return;
		const vm = buildVM(getModel());
		if (vm.rows.length === 0) {
			ctx.ui.setWidget("pipelines", undefined);
			tuiRef = undefined;
			return;
		}

		ctx.ui.setWidget("pipelines", (tui: any, theme: any) => {
			tuiRef = tui;
			return {
				render(width: number): string[] {
					const expanded = vm.active > 0 && !opts.collapsedDefault;
					const lines = expanded ? renderDashboard(vm, Math.max(20, width)) : [collapsedLine(vm)];
					return lines.map((line) => {
						if (!vm.attention) return truncateToWidth(line, width);
						return theme.fg("warning", truncateToWidth(line, width));
					});
				},
				invalidate() {},
				dispose() {
					if (tuiRef === tui) tuiRef = undefined;
				},
			};
		});
	};

	pi.on("session_start", (_event, ctx: ExtensionContext) => {
		draw(ctx);
		timer = setInterval(() => {
			draw(ctx);
			tuiRef?.requestRender?.();
		}, 1000);
		if (timer.unref) timer.unref();
	});

	pi.on("session_shutdown", () => {
		if (timer) clearInterval(timer);
		timer = undefined;
		tuiRef = undefined;
	});
}
