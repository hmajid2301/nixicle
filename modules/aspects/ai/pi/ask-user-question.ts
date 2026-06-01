import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import {
	Editor,
	type EditorTheme,
	Key,
	matchesKey,
	truncateToWidth,
	visibleWidth,
	wrapTextWithAnsi,
	Text,
} from "@mariozechner/pi-tui";
import { Type, type Static } from "typebox";

const QuestionOptionSchema = Type.Object({
	value: Type.String({ description: "Stable value returned to the agent" }),
	label: Type.String({ description: "Short label shown to the user" }),
	description: Type.Optional(Type.String({ description: "Optional explanation or trade-off" })),
	preview: Type.Optional(
		Type.String({
			description: "Optional preview text shown for the currently highlighted option (best for code, mockups, examples)",
		}),
	),
	recommended: Type.Optional(Type.Boolean({ description: "Highlight this option as recommended" })),
});

const QuestionSchema = Type.Object({
	id: Type.String({ description: "Unique identifier for this question" }),
	header: Type.Optional(Type.String({ description: "Short tab label, e.g. Scope or Style" })),
	prompt: Type.String({ description: "Question shown to the user" }),
	kind: Type.Optional(
		Type.Union([Type.Literal("single"), Type.Literal("multi"), Type.Literal("free_text")], {
			description: "Question type. Defaults to single.",
		}),
	),
	options: Type.Optional(Type.Array(QuestionOptionSchema, { description: "Selectable options" })),
	allowOther: Type.Optional(
		Type.Boolean({ description: "Allow a custom typed answer for single-select questions. Defaults to true." }),
	),
	placeholder: Type.Optional(Type.String({ description: "Optional placeholder/help for free-text prompts" })),
});

const AskUserQuestionParams = Type.Object({
	intro: Type.Optional(Type.String({ description: "Optional intro shown above the questionnaire" })),
	questions: Type.Array(QuestionSchema, { description: "Questions to ask the user" }),
});

type AskUserQuestionInput = Static<typeof AskUserQuestionParams>;
type QuestionKind = "single" | "multi" | "free_text";

interface QuestionOption {
	value: string;
	label: string;
	description?: string;
	preview?: string;
	recommended?: boolean;
}

interface Question {
	id: string;
	header: string;
	prompt: string;
	kind: QuestionKind;
	options: QuestionOption[];
	allowOther: boolean;
	placeholder?: string;
}

interface AnswerItem {
	value: string;
	label: string;
	description?: string;
	wasCustom?: boolean;
}

interface Answer {
	id: string;
	prompt: string;
	kind: QuestionKind;
	items: AnswerItem[];
}

interface AskUserQuestionResult {
	intro?: string;
	questions: Question[];
	answers: Answer[];
	cancelled: boolean;
	error?: string;
}

const OTHER_VALUE = "__other__";
const OTHER_LABEL = "Type something.";
const PREVIEW_SPLIT_MIN_WIDTH = 100;

function wrapLines(text: string, width: number): string[] {
	const lines = text.split("\n").flatMap((line) => wrapTextWithAnsi(line || " ", Math.max(1, width)));
	return lines.length > 0 ? lines : [""];
}

function makeErrorResult(message: string, questions: Question[] = []): { content: { type: "text"; text: string }[]; details: AskUserQuestionResult } {
	return {
		content: [{ type: "text", text: message }],
		details: { questions, answers: [], cancelled: true, error: message },
	};
}

function normalizeQuestions(params: AskUserQuestionInput): Question[] {
	return params.questions.map((q, index) => {
		const kind = (q.kind ?? "single") as QuestionKind;
		return {
			id: q.id,
			header: q.header?.trim() || `Q${index + 1}`,
			prompt: q.prompt,
			kind,
			options: q.options ?? [],
			allowOther: q.allowOther !== false,
			placeholder: q.placeholder,
		};
	});
}

function validateQuestions(questions: Question[]): string | undefined {
	if (questions.length === 0) return "Error: No questions provided";
	const ids = new Set<string>();
	for (const q of questions) {
		if (ids.has(q.id)) return `Error: duplicate question id \"${q.id}\"`;
		ids.add(q.id);
		if (q.header.length > 16) return `Error: header for \"${q.id}\" is too long (max 16 chars)`;
		if (q.kind === "free_text") continue;
		if (q.options.length < 2) return `Error: question \"${q.id}\" needs at least 2 options`;
		const labels = new Set<string>();
		let recommendedCount = 0;
		for (const opt of q.options) {
			const labelKey = opt.label.trim().toLowerCase();
			if (labels.has(labelKey)) return `Error: question \"${q.id}\" has duplicate option label \"${opt.label}\"`;
			labels.add(labelKey);
			if (labelKey === OTHER_LABEL.toLowerCase()) {
				return `Error: question \"${q.id}\" must not define its own \"${OTHER_LABEL}\" option`;
			}
			if (opt.recommended) recommendedCount++;
		}
		if (q.kind === "single" && recommendedCount > 1) {
			return `Error: question \"${q.id}\" is single-select but has multiple recommended options`;
		}
	}
}

function formatMarkdown(result: AskUserQuestionResult): string {
	if (result.cancelled) return "User cancelled ask_user_question.";
	const lines: string[] = ["## User answers"]; 
	for (const answer of result.answers) {
		lines.push("");
		lines.push(`### ${answer.prompt}`);
		lines.push("");
		if (answer.kind === "multi") {
			for (const item of answer.items) {
				const desc = item.description ? ` — ${item.description}` : "";
				lines.push(`- [x] ${item.label}${desc}`);
			}
		} else {
			for (const item of answer.items) {
				const desc = item.description ? ` — ${item.description}` : "";
				lines.push(`- ${item.label}${desc}`);
			}
		}
	}
	return lines.join("\n");
}

function buildSummaryText(result: AskUserQuestionResult): string {
	if (result.cancelled) return "Cancelled";
	return result.answers
		.map((answer) => `${answer.prompt}: ${answer.items.map((item) => item.label).join(", ") || "(no answer)"}`)
		.join("\n");
}

export default function askUserQuestionExtension(pi: ExtensionAPI) {
	pi.registerTool({
		name: "ask_user_question",
		label: "Ask User",
		description: `Ask the user one or more structured clarifying questions with a rich interactive widget.
Use this instead of plain-text questioning when requirements are ambiguous, when multiple valid approaches exist, or when you need preferences before proceeding.

Supports:
- single-select questions
- multi-select questions
- free-text interview questions
- optional previews for options
- a submit/review step for multi-question interviews

Guidelines:
- Group related clarifying questions into one tool call.
- Use short headers for tabs.
- For recommended answers, mark one option as recommended.
- Do not add your own \"Type something.\" option; the UI adds it automatically for single-select questions when allowed.`,
		parameters: AskUserQuestionParams,

		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			if (!ctx.hasUI) return makeErrorResult("Error: UI not available (running in non-interactive mode)");

			const questions = normalizeQuestions(params as AskUserQuestionInput);
			const validationError = validateQuestions(questions);
			if (validationError) return makeErrorResult(validationError, questions);

			const result = (await ctx.ui.custom((tui, theme, _kb, done) => {
				const answers = new Map<string, Answer>();
				const selectedByQuestion = new Map<string, Set<number>>();
				let currentTab = 0;
				let cursorIndex = 0;
				let inputMode = questions[0]?.kind === "free_text";
				let inputQuestionId: string | null = inputMode ? questions[0]?.id ?? null : null;
				let cachedLines: string[] | undefined;

				const editorTheme: EditorTheme = {
					borderColor: (s) => theme.fg("accent", s),
					selectList: {
						selectedPrefix: (t) => theme.fg("accent", t),
						selectedText: (t) => theme.fg("accent", t),
						description: (t) => theme.fg("muted", t),
						scrollInfo: (t) => theme.fg("dim", t),
						noMatch: (t) => theme.fg("warning", t),
					},
				};
				const editor = new Editor(tui, editorTheme);
				editor.onSubmit = (value) => {
					if (!inputQuestionId) return;
					const question = questions.find((q) => q.id === inputQuestionId);
					if (!question) return;
					const trimmed = value.trim();
					if (question.kind === "free_text") {
						if (!trimmed) return;
						saveAnswer(question, [
							{ value: trimmed, label: trimmed, wasCustom: true },
						]);
					} else {
						if (!trimmed) {
							answers.delete(question.id);
						} else {
							saveAnswer(question, [
								{ value: trimmed, label: trimmed, wasCustom: true },
							]);
						}
					}
					inputMode = false;
					inputQuestionId = null;
					editor.setText("");
					advanceAfterAnswer(question);
				};

				function refresh() {
					cachedLines = undefined;
					tui.requestRender();
				}

				function currentQuestion(): Question | undefined {
					return questions[currentTab];
				}

				function allAnswered(): boolean {
					return questions.every((q) => answers.has(q.id));
				}

				function saveAnswer(question: Question, items: AnswerItem[]) {
					answers.set(question.id, {
						id: question.id,
						prompt: question.prompt,
						kind: question.kind,
						items,
					});
				}

				function questionOptions(question: Question): Array<QuestionOption & { isOther?: boolean }> {
					if (question.kind === "free_text") return [];
					const options: Array<QuestionOption & { isOther?: boolean }> = [...question.options];
					if (question.kind === "single" && question.allowOther) {
						options.push({ value: OTHER_VALUE, label: OTHER_LABEL, description: "Write your own answer.", isOther: true });
					}
					return options;
				}

				function selectedSet(questionId: string): Set<number> {
					let set = selectedByQuestion.get(questionId);
					if (!set) {
						set = new Set<number>();
						selectedByQuestion.set(questionId, set);
					}
					return set;
				}

				function openEditor(question: Question, initialText = "") {
					inputMode = true;
					inputQuestionId = question.id;
					editor.setText(initialText);
					refresh();
				}

				function submit(cancelled: boolean) {
					done({
						intro: params.intro,
						questions,
						answers: questions.flatMap((q) => {
							const answer = answers.get(q.id);
							return answer ? [answer] : [];
						}),
						cancelled,
					});
				}

				function advanceAfterAnswer(question: Question) {
					if (questions.length === 1) {
						if (question.kind === "multi") return;
						submit(false);
						return;
					}
					if (currentTab < questions.length - 1) {
						currentTab++;
						cursorIndex = 0;
						const next = currentQuestion();
						if (next?.kind === "free_text") {
							inputMode = true;
							inputQuestionId = next.id;
							editor.setText(answers.get(next.id)?.items[0]?.label ?? "");
						} else {
							inputMode = false;
							inputQuestionId = null;
						}
						refresh();
					} else {
						currentTab = questions.length;
						cursorIndex = 0;
						inputMode = false;
						inputQuestionId = null;
						refresh();
					}
				}

				function previewForSelection(question: Question, options: ReturnType<typeof questionOptions>): string | undefined {
					if (question.kind === "free_text") return question.placeholder;
					const option = options[cursorIndex];
					return option?.preview;
				}

				function renderPanelContent(lines: string[], width: number, title: string, content?: string) {
					lines.push(theme.fg("accent", `┌${"─".repeat(Math.max(0, width - 2))}┐`));
					for (const raw of wrapLines(title, Math.max(1, width - 4))) {
						const padded = raw + " ".repeat(Math.max(0, width - 4 - visibleWidth(raw)));
						lines.push(theme.fg("accent", "│ ") + theme.fg("text", padded) + theme.fg("accent", " │"));
					}
					lines.push(theme.fg("accent", `├${"─".repeat(Math.max(0, width - 2))}┤`));
					for (const raw of wrapLines(content?.trim() || "No preview for this option.", Math.max(1, width - 4))) {
						const padded = raw + " ".repeat(Math.max(0, width - 4 - visibleWidth(raw)));
						lines.push(theme.fg("accent", "│ ") + theme.fg("muted", padded) + theme.fg("accent", " │"));
					}
					lines.push(theme.fg("accent", `└${"─".repeat(Math.max(0, width - 2))}┘`));
				}

				function handleInput(data: string) {
					const question = currentQuestion();
					if (inputMode) {
						if (matchesKey(data, Key.escape)) {
							inputMode = false;
							inputQuestionId = null;
							editor.setText("");
							refresh();
							return;
						}
						editor.handleInput(data);
						refresh();
						return;
					}

					if (matchesKey(data, Key.escape)) {
						submit(true);
						return;
					}

					if (questions.length > 1 && (matchesKey(data, Key.right) || matchesKey(data, Key.tab))) {
						currentTab = (currentTab + 1) % (questions.length + 1);
						cursorIndex = 0;
						const next = currentQuestion();
						if (next?.kind === "free_text") {
							openEditor(next, answers.get(next.id)?.items[0]?.label ?? "");
							return;
						}
						refresh();
						return;
					}
					if (questions.length > 1 && (matchesKey(data, Key.left) || matchesKey(data, Key.shift("tab")))) {
						currentTab = (currentTab - 1 + questions.length + 1) % (questions.length + 1);
						cursorIndex = 0;
						const next = currentQuestion();
						if (next?.kind === "free_text") {
							openEditor(next, answers.get(next.id)?.items[0]?.label ?? "");
							return;
						}
						refresh();
						return;
					}

					if (currentTab === questions.length) {
						if (matchesKey(data, Key.enter) && allAnswered()) submit(false);
						return;
					}

					if (!question) return;
					const options = questionOptions(question);
					if (question.kind !== "free_text") {
						if (matchesKey(data, Key.up)) {
							cursorIndex = Math.max(0, cursorIndex - 1);
							refresh();
							return;
						}
						if (matchesKey(data, Key.down)) {
							cursorIndex = Math.min(options.length - 1, cursorIndex + 1);
							refresh();
							return;
						}
					}

					if (question.kind === "free_text") {
						openEditor(question, answers.get(question.id)?.items[0]?.label ?? "");
						return;
					}

					const option = options[cursorIndex];
					if (!option) return;

					if (question.kind === "multi") {
						if (matchesKey(data, Key.space) || matchesKey(data, Key.enter)) {
							const selected = selectedSet(question.id);
							if (selected.has(cursorIndex)) selected.delete(cursorIndex);
							else selected.add(cursorIndex);
							if (selected.size > 0) {
								saveAnswer(
									question,
									Array.from(selected)
										.sort((a, b) => a - b)
										.map((idx) => {
											const picked = options[idx]!;
											return {
												value: picked.value,
												label: picked.label,
												description: picked.description,
											};
										}),
								);
							} else {
								answers.delete(question.id);
							}
							refresh();
							return;
						}
						if ((matchesKey(data, Key.right) || matchesKey(data, Key.tab)) && selectedSet(question.id).size > 0) {
							if (questions.length === 1) {
								currentTab = questions.length;
								cursorIndex = 0;
								refresh();
							} else {
								advanceAfterAnswer(question);
							}
						}
						return;
					}

					if (option.value === OTHER_VALUE) {
						openEditor(question, answers.get(question.id)?.items[0]?.wasCustom ? answers.get(question.id)?.items[0]?.label ?? "" : "");
						return;
					}

					saveAnswer(question, [
						{
							value: option.value,
							label: option.label,
							description: option.description,
						},
					]);
					advanceAfterAnswer(question);
				}

				function render(width: number): string[] {
					if (cachedLines) return cachedLines;
					const lines: string[] = [];
					const question = currentQuestion();
					const options = question ? questionOptions(question) : [];
					const add = (s = "") => lines.push(truncateToWidth(s, width));

					add(theme.fg("accent", "═".repeat(width)));
					add(theme.fg("accent", theme.bold(" Ask User Question")));
					if (params.intro) {
						for (const line of wrapLines(params.intro, width)) add(theme.fg("muted", line));
					}
					add("");

					if (questions.length > 1) {
						const tabs: string[] = [];
						for (let i = 0; i < questions.length; i++) {
							const q = questions[i]!;
							const answered = answers.has(q.id);
							const active = i === currentTab;
							const chip = ` ${answered ? "■" : "□"} ${q.header} `;
							tabs.push(active ? theme.bg("selectedBg", theme.fg("text", chip)) : theme.fg(answered ? "success" : "muted", chip));
						}
						const submitChip = ` ${allAnswered() ? "✓" : "→"} Submit `;
						tabs.push(
							currentTab === questions.length
								? theme.bg("selectedBg", theme.fg("text", submitChip))
								: theme.fg(allAnswered() ? "success" : "dim", submitChip),
						);
						add(tabs.join(" "));
						add("");
					}

					if (currentTab === questions.length) {
						add(theme.fg("accent", theme.bold(" Review answers")));
						add("");
						for (const q of questions) {
							const answer = answers.get(q.id);
							const summary = answer ? answer.items.map((item) => item.label).join(", ") : "(unanswered)";
							for (const line of wrapLines(`${q.header}: ${summary}`, width)) add(theme.fg(answer ? "text" : "warning", line));
						}
						add("");
						add(theme.fg(allAnswered() ? "success" : "warning", allAnswered() ? "Press Enter to submit" : "Answer all questions before submitting"));
						add(theme.fg("dim", "←/→ switch tabs • Esc cancel"));
						add(theme.fg("accent", "═".repeat(width)));
						cachedLines = lines;
						return lines;
					}

					if (!question) {
						add(theme.fg("warning", "No active question"));
						add(theme.fg("accent", "═".repeat(width)));
						cachedLines = lines;
						return lines;
					}

					for (const line of wrapLines(question.prompt, width)) add(theme.fg("text", line));
					add("");

					if (inputMode) {
						if (question.placeholder) {
							for (const line of wrapLines(question.placeholder, width)) add(theme.fg("muted", line));
							add("");
						}
						for (const line of editor.render(Math.max(20, width - 2))) add(` ${line}`);
						add("");
						add(theme.fg("dim", "Enter save • Esc cancel"));
						add(theme.fg("accent", "═".repeat(width)));
						cachedLines = lines;
						return lines;
					}

					const hasPreview = question.kind === "single" && options.some((opt) => !!opt.preview);
					const useSplitPreview = hasPreview && width >= PREVIEW_SPLIT_MIN_WIDTH;

					if (question.kind === "free_text") {
						add(theme.fg("accent", "Press Enter to write your answer"));
					} else if (useSplitPreview) {
						const leftWidth = Math.max(30, Math.floor(width * 0.44));
						const rightWidth = Math.max(24, width - leftWidth - 3);
						const leftLines: string[] = [];
						for (let i = 0; i < options.length; i++) {
							const opt = options[i]!;
							const isCursor = i === cursorIndex;
							const isMultiSelected = question.kind === "multi" && selectedSet(question.id).has(i);
							const bullet = question.kind === "multi" ? (isMultiSelected ? "☑" : "☐") : isCursor ? "●" : "○";
							const prefix = isCursor ? theme.fg("accent", "> ") : "  ";
							const label = `${bullet} ${opt.label}${opt.recommended ? " (Recommended)" : ""}`;
							for (const line of wrapLines(prefix + label, leftWidth)) leftLines.push(isCursor ? theme.fg("accent", line) : theme.fg("text", line));
							if (opt.description) {
								for (const line of wrapLines(`   ${opt.description}`, leftWidth)) leftLines.push(theme.fg("muted", line));
							}
							leftLines.push("");
						}
						if (leftLines[leftLines.length - 1] === "") leftLines.pop();
						const rightLines: string[] = [];
						renderPanelContent(rightLines, rightWidth, options[cursorIndex]?.label || "Preview", previewForSelection(question, options));
						const maxLines = Math.max(leftLines.length, rightLines.length);
						for (let i = 0; i < maxLines; i++) {
							const left = truncateToWidth(leftLines[i] ?? "", leftWidth).padEnd(leftWidth, " ");
							const right = truncateToWidth(rightLines[i] ?? "", rightWidth);
							add(`${left}   ${right}`);
						}
					} else {
						for (let i = 0; i < options.length; i++) {
							const opt = options[i]!;
							const isCursor = i === cursorIndex;
							const isMultiSelected = question.kind === "multi" && selectedSet(question.id).has(i);
							const bullet = question.kind === "multi" ? (isMultiSelected ? "☑" : "☐") : isCursor ? "●" : "○";
							const prefix = isCursor ? theme.fg("accent", "> ") : "  ";
							const label = `${prefix}${bullet} ${opt.label}${opt.recommended ? " (Recommended)" : ""}`;
							for (const line of wrapLines(label, width)) add(isCursor ? theme.fg("accent", line) : theme.fg("text", line));
							if (opt.description) {
								for (const line of wrapLines(`   ${opt.description}`, width)) add(theme.fg("muted", line));
							}
							if (i === cursorIndex && opt.preview && !useSplitPreview) {
								add("");
								renderPanelContent(lines, Math.max(24, Math.min(width, 80)), opt.label, opt.preview);
							}
						}
					}

					add("");
					if (question.kind === "multi") {
						add(theme.fg("dim", "↑↓ move • Space toggle • Tab/→ continue • ← switch tabs • Esc cancel"));
					} else if (question.kind === "free_text") {
						add(theme.fg("dim", "Enter write • ←/→ or Tab switch tabs • Esc cancel"));
					} else {
						add(theme.fg("dim", "↑↓ move • Enter select • ←/→ or Tab switch tabs • Esc cancel"));
					}
					add(theme.fg("accent", "═".repeat(width)));
					cachedLines = lines;
					return lines;
				}

				return {
					render,
					invalidate: () => {
						cachedLines = undefined;
					},
					handleInput,
				};
			})) as AskUserQuestionResult;

			if (result.cancelled) {
				return {
					content: [{ type: "text", text: "User cancelled ask_user_question." }],
					details: result,
				};
			}

			return {
				content: [{ type: "text", text: formatMarkdown(result) }],
				details: result,
			};
		},

		renderCall(args, theme) {
			const qs = ((args.questions as Question[] | undefined) ?? []).map((q) => q.header || q.id).join(", ");
			return new Text(theme.fg("toolTitle", theme.bold("ask user ")) + theme.fg("muted", qs || "questions"), 0, 0);
		},

		renderResult(result, _options, theme) {
			const details = result.details as AskUserQuestionResult | undefined;
			if (!details) {
				return new Text(result.content[0]?.type === "text" ? result.content[0].text : "", 0, 0);
			}
			const summary = details.cancelled ? theme.fg("warning", "Cancelled") : buildSummaryText(details);
			return new Text(summary, 0, 0);
		},
	});
}
