export interface TodoItem {
	step: number;
	text: string;
	completed: boolean;
}

export function cleanStepText(text: string): string {
	let cleaned = text
		.replace(/\*{1,2}([^*]+)\*{1,2}/g, "$1")
		.replace(/`([^`]+)`/g, "$1")
		.replace(
			/^(Use|Run|Execute|Create|Write|Read|Check|Verify|Update|Modify|Add|Remove|Delete|Install)\s+(the\s+)?/i,
			"",
		)
		.replace(/^(?:\s*[-*+]\s+|\s*\d+[.)]\s+)/, "")
		.replace(/\s+/g, " ")
		.trim();

	if (cleaned.length > 0) cleaned = cleaned.charAt(0).toUpperCase() + cleaned.slice(1);
	if (cleaned.length > 50) {
		let truncated = cleaned.slice(0, 47);
		const lastSpace = truncated.lastIndexOf(" ");
		if (lastSpace > 0) truncated = truncated.slice(0, lastSpace);
		cleaned = `${truncated}...`;
	}
	return cleaned;
}

export function extractTodoItems(message: string): TodoItem[] {
	const items: TodoItem[] = [];
	const headerMatch = message.match(/\*{0,2}Plan:\*{0,2}\s*\n/i);
	if (!headerMatch) return items;

	const planSection = message.slice(message.indexOf(headerMatch[0]) + headerMatch[0].length);
	const numberedPattern = /^\s*(\d+)[.)]\s+(.+?)(?=\n\s*\d+[.)]\s+|\n*$)/gms;

	for (const match of planSection.matchAll(numberedPattern)) {
		const text = match[2]
			.split("\n")
			.find((line) => line.trim().length > 0 && !/^\s*[-*]\s+/.test(line))
			?.trim()
			.replace(/\*{1,2}$/, "")
			.trim();
		if (!text) continue;
		if (text.length > 5 && !text.startsWith("`") && !text.startsWith("/") && !text.startsWith("-")) {
			const cleaned = cleanStepText(text);
			if (cleaned.length > 3) items.push({ step: items.length + 1, text: cleaned, completed: false });
		}
	}
	return items;
}

export function extractDoneSteps(message: string): number[] {
	const steps: number[] = [];
	for (const match of message.matchAll(/\[DONE:(\d+)\]/gi)) {
		const step = Number(match[1]);
		if (Number.isFinite(step)) steps.push(step);
	}
	return steps;
}

export function markCompletedSteps(text: string, items: TodoItem[]): TodoItem[] {
	const doneSteps = new Set(extractDoneSteps(text));
	return items.map((item) => ({
		...item,
		completed: item.completed || doneSteps.has(item.step),
	}));
}
