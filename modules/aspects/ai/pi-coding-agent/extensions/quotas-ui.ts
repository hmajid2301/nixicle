export type QuotaStatusUIMode = "regular" | "fullscreen" | undefined;

export function shouldRenderQuotaStatus(
	{ uiMode, previousText, nextText }: { uiMode: QuotaStatusUIMode; previousText: string | undefined; nextText: string | undefined },
): boolean {
	if (uiMode !== "fullscreen") return false;
	return previousText !== nextText;
}
