export function buildRightFooterParts(
	{
		modelId,
		sessionName,
		thinkingBadge,
	}: {
		modelId: string;
		sessionName?: string;
		thinkingBadge?: string;
	},
): string[] {
	return [modelId, sessionName, thinkingBadge].filter(
		(part): part is string => Boolean(part),
	);
}
