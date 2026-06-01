import type { AutocompleteItem, AutocompleteProvider, AutocompleteSuggestions } from "@mariozechner/pi-tui";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { StringEnum } from "@mariozechner/pi-ai";
import { Type, type Static } from "typebox";
import { spawn } from "node:child_process";
import { appendFile, existsSync, mkdir, readFile, realpathSync, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { basename, dirname, isAbsolute, join, relative, resolve, sep } from "node:path";

// ── zk CLI client ──────────────────────────────────────────────────────────

const NO_COLOR_ENV = { NO_COLOR: "1", TERM: "dumb" };

function resolveZkBin(env = process.env): string {
  if (env.ZK_BIN?.trim()) return env.ZK_BIN.trim();
  const p = join(process.env.HOME ?? "/", ".local", "bin", "zk");
  if (existsSync(p)) return p;
  return "zk";
}

async function zk(args: string[], cwd: string, opts?: { signal?: AbortSignal; timeout?: number; input?: string; env?: NodeJS.ProcessEnv }): Promise<{ stdout: string; stderr: string }> {
  const bin = resolveZkBin(opts?.env);
  return new Promise((res, rej) => {
    const child = spawn(bin, args, { cwd, env: { ...process.env, ...NO_COLOR_ENV, ...opts?.env }, stdio: ["pipe", "pipe", "pipe"] });
    let out = "", err = "";
    child.stdout.setEncoding("utf8").on("data", (d: string) => { out += d; });
    child.stderr.setEncoding("utf8").on("data", (d: string) => { err += d; });
    let done = false;
    const finish = (code: number) => { if (done) return; done = true; clearTimeout(timer); opts?.signal?.removeEventListener("abort", onAbort); code === 0 ? res({ stdout: out, stderr: err }) : rej(new Error(`zk ${args[0]} failed (${code}): ${err || out}`)); };
    const onAbort = () => { done = true; child.kill("SIGTERM"); rej(new Error(`zk ${args[0]} aborted`)); };
    opts?.signal?.addEventListener("abort", onAbort, { once: true });
    const timer = opts?.timeout ? setTimeout(() => { done = true; child.kill("SIGTERM"); rej(new Error(`zk ${args[0]} timed out`)); }, opts.timeout) : setTimeout(() => {}, 1e9);
    child.on("error", (e) => { done = true; rej(e); });
    child.on("close", finish);
    child.stdin.end(opts?.input ?? "");
  });
}

// ── Notebook resolution ────────────────────────────────────────────────────

interface Notebook { path: string; source: string }

function resolveNotebook(cwd: string, override?: string, env = process.env): Notebook {
  if (override?.trim()) return { path: resolve(cwd, override.trim()), source: "override" };
  for (const key of ["ZK_NOTEBOOK_DIR", "ZK_DIR"] as const) {
    const v = env[key]?.trim();
    if (v) return { path: resolve(v), source: key };
  }
  let dir = resolve(cwd);
  for (;;) {
    if (existsSync(join(dir, ".zk"))) return { path: dir, source: dir === resolve(cwd) ? "cwd" : "walk_up" };
    const parent = dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }
  throw new Error("No zk notebook found. Set ZK_NOTEBOOK_DIR or run inside a .zk directory.");
}

function nbArgs(nbPath: string, args: string[]): string[] {
  return ["--notebook-dir", nbPath, ...args];
}

// ── Parsing ────────────────────────────────────────────────────────────────

interface Note { path: string; title: string; tags: string[] }
interface Tag { name: string; count: number }

const FMT_NOTE = "{{path}}\\t{{title}}\\t{{join tags \",\"}}";
const FMT_TAG = "{{name}}\\t{{note-count}}";

function parseNotes(stdout: string): Note[] {
  return stdout.split("\n").map(l => l.replace(/\r$/, "")).filter(Boolean).map(line => {
    const [path, title, tagsRaw] = line.split("\t");
    if (!path) return null;
    return { path, title: title ?? "", tags: (tagsRaw ?? "").split(",").map(t => t.trim()).filter(Boolean) };
  }).filter(Boolean) as Note[];
}

function parseTags(stdout: string): Tag[] {
  return stdout.split("\n").map(l => l.replace(/\r$/, "")).filter(Boolean).map(line => {
    const [name, count] = line.split("\t");
    if (!name) return null;
    const n = parseInt(count?.trim() ?? "", 10);
    return Number.isFinite(n) ? { name, count: n } : null;
  }).filter(Boolean) as Tag[];
}

// ── Validation ─────────────────────────────────────────────────────────────

const CTRL_RE = /[\x00-\x1f\x7f]/;

function safeNotebookPath(nbRoot: string, target: string): string {
  if (!target.trim()) throw new Error("path is empty");
  if (CTRL_RE.test(target)) throw new Error("path contains control characters");
  if (isAbsolute(target)) throw new Error("path must be notebook-relative");
  const segments = target.split(/[\\/]+/).filter(Boolean);
  if (segments.includes("..")) throw new Error("path must not traverse upwards");
  let root: string;
  try { root = realpathSync(nbRoot); } catch { root = resolve(nbRoot); }
  const abs = resolve(root, target);
  let real: string;
  try { real = realpathSync(abs); } catch { real = abs; }
  const rel = relative(root, real);
  if (rel.startsWith("..") || isAbsolute(rel)) throw new Error(`path outside notebook: ${target}`);
  return real;
}

function validateTitle(title: string): string {
  const t = title.trim();
  if (!t || t.length > 200) throw new Error("title: 1-200 chars");
  if (/[/\\]/.test(t) || CTRL_RE.test(t)) throw new Error("title: no separators or control chars");
  return t;
}

function validateDir(dir: string): string {
  if (!dir.trim()) throw new Error("directory is empty");
  if (CTRL_RE.test(dir) || isAbsolute(dir)) throw new Error("invalid directory");
  const segs = dir.split(/[\\/]+/).filter(Boolean);
  if (segs.includes("..")) throw new Error("directory must not traverse upwards");
  return segs.join("/");
}

// ── Edits ──────────────────────────────────────────────────────────────────

function applyEdits(content: string, edits: Array<{ oldText: string; newText: string }>): string {
  let result = content;
  for (let i = 0; i < edits.length; i++) {
    const { oldText, newText } = edits[i];
    if (!oldText) throw new Error(`edit ${i + 1}: empty oldText`);
    const count = result.split(oldText).length - 1;
    if (count === 0) throw new Error(`edit ${i + 1}: oldText not found`);
    if (count > 1) throw new Error(`edit ${i + 1}: oldText matches ${count} times, make it unique`);
    result = result.replace(oldText, newText);
  }
  return result;
}

function appendPayload(existing: string, content: string): string {
  const block = content.endsWith("\n") ? content : `${content}\n`;
  if (!existing) return block;
  if (existing.endsWith("\n\n")) return block;
  if (existing.endsWith("\n")) return `\n${block}`;
  return `\n\n${block}`;
}

// ── Output formatting ──────────────────────────────────────────────────────

function renderNotes(notes: Note[]): string {
  if (!notes.length) return "No notes found.";
  return notes.map(n => {
    const tags = n.tags.length ? ` [${n.tags.join(", ")}]` : "";
    return `- ${n.path}\t${n.title}${tags}`;
  }).join("\n");
}

function renderTags(tags: Tag[]): string {
  if (!tags.length) return "No tags found.";
  return tags.map(t => `- ${t.name} (${t.count})`).join("\n");
}

async function truncText(text: string, prefix: string, maxBytes = 50_000): Promise<string> {
  if (Buffer.byteLength(text, "utf8") <= maxBytes) return text;
  const { mkdtemp, writeFile: wf } = await import("node:fs/promises");
  const dir = await mkdtemp(join(tmpdir(), prefix));
  await wf(join(dir, "output.txt"), text, "utf8");
  const buf = Buffer.from(text, "utf8");
  const kept = buf.slice(Math.max(0, buf.length - maxBytes)).toString("utf8");
  return `${kept}\n\n[Truncated. Full output: ${join(dir, "output.txt")}]`;
}

// ── Note cache for autocomplete ────────────────────────────────────────────

interface CachedNote { path: string; stem: string; title: string; tags: string[] }

function stem(path: string): string {
  const f = basename(path);
  const d = f.lastIndexOf(".");
  return d <= 0 ? f : f.slice(0, d);
}

class NoteCache {
  private data: CachedNote[] | undefined;
  private at = 0;
  private loading: Promise<CachedNote[]> | undefined;
  constructor(private nbPath: string, private cwd: string, private ttl = 60_000) {}
  async get(): Promise<CachedNote[]> {
    if (this.data && Date.now() - this.at < this.ttl) return this.data;
    if (this.loading) return this.loading;
    this.loading = (async () => {
      try {
        const limit = parseInt(process.env.ZK_AUTOCOMPLETE_LIMIT ?? "", 10) || 500;
        const r = await zk(nbArgs(this.nbPath, ["list", "-q", "--no-pager", "--sort", "modified-", "--limit", String(limit), "--format", FMT_NOTE]), this.cwd, { timeout: 10_000 });
        this.data = parseNotes(r.stdout).map(n => ({ path: n.path, stem: stem(n.path), title: n.title, tags: n.tags }));
        this.at = Date.now();
        return this.data;
      } catch { return this.data ?? []; }
      finally { this.loading = undefined; }
    })();
    return this.loading;
  }
  invalidate() { this.data = undefined; this.at = 0; }
}

// ── Wikilink autocomplete ──────────────────────────────────────────────────

const WL_RE = /\[\[([^\]\n]*)$/;
const MAX_SUGGEST = 20;

function createWikilinkProvider(current: AutocompleteProvider, cache: NoteCache): AutocompleteProvider {
  return {
    async getSuggestions(lines, line, col, opts) {
      const before = (lines[line] ?? "").slice(0, col);
      const m = before.match(WL_RE);
      if (!m) return current.getSuggestions(lines, line, col, opts);
      const query = m[1].toLowerCase();
      const notes = await cache.get();
      if (opts.signal.aborted || !notes.length) return current.getSuggestions(lines, line, col, opts);
      const matches = notes.filter(n => {
        const h = `${n.stem} ${n.title} ${n.tags.join(" ")}`.toLowerCase();
        let idx = 0;
        for (const ch of query) { idx = h.indexOf(ch, idx); if (idx === -1) return false; idx++; }
        return true;
      }).slice(0, MAX_SUGGEST);
      if (!matches.length) return current.getSuggestions(lines, line, col, opts);
      const items: AutocompleteItem[] = matches.map(n => ({
        value: `[[${n.stem}]]`, label: n.stem,
        description: `${n.title}${n.tags.length ? ` ${n.tags.map(t => `#${t}`).join(" ")}` : ""}`,
      }));
      return { items, prefix: `[[${m[1]}` };
    },
    applyCompletion(lines, line, col, item, prefix) {
      return current.applyCompletion(lines, line, col, item, prefix);
    },
    shouldTriggerFileCompletion(lines, line, col) {
      return current.shouldTriggerFileCompletion?.(lines, line, col) ?? true;
    },
  };
}

// ── System prompt guidance ─────────────────────────────────────────────────

function guidance(nb: Notebook): string {
  return [
    "# pi-zk notebook guidance",
    `A zk notebook is in scope at \`${nb.path}\` (resolved via ${nb.source}).`,
    "",
    "- Prefer zk tools over generic bash/edit/read when working with notes.",
    "- Use zk_search_notes before reading to discover candidate paths.",
    "- Use zk_read_note (notebook-relative paths) instead of the generic read tool.",
    "- Use zk_create_note instead of write so zk's filename rules and templates apply.",
    "- Use zk_edit_note for surgical changes, zk_append_note for log-style additions.",
    "- Use zk_link_to, zk_linked_by, zk_related to navigate the link graph.",
    "- Wikilink autocomplete active: type `[[partial` for fuzzy suggestions.",
  ].join("\n");
}

// ── Shared schemas ─────────────────────────────────────────────────────────

const NotebookOverride = Type.Optional(Type.String({ description: "Override notebook path (absolute or relative to cwd)." }));
const NoteRef = Type.String({ description: "Notebook-relative path (e.g. `journal/2026-05-09.md`)." });

// ── Tool registrations ─────────────────────────────────────────────────────

function registerSearchNotes(pi: ExtensionAPI) {
  const Params = Type.Object({
    match: Type.Optional(Type.String({ description: "Full-text query (FTS: AND default, OR/|, NOT/-, parens)." })),
    tags: Type.Optional(Type.Array(Type.String())),
    exclude_tags: Type.Optional(Type.Array(Type.String())),
    paths: Type.Optional(Type.Array(Type.String({ description: "Scope to these notebook-relative paths." }))),
    created_after: Type.Optional(Type.String()),
    modified_after: Type.Optional(Type.String()),
    sort: Type.Optional(Type.String({ description: "Sort criterion. Default `modified-`." })),
    limit: Type.Optional(Type.Number({ minimum: 1, maximum: 200 })),
    offset: Type.Optional(Type.Number({ minimum: 0 })),
    notebook: NotebookOverride,
  });

  pi.registerTool({
    name: "zk_search_notes", label: "zk Search",
    description: "Search notes by full-text, tags, paths, date ranges.",
    parameters: Params,
    promptSnippet: "zk_search_notes: find notes by query/tags/paths/dates.",
    promptGuidelines: ["Use before reading notes to discover paths."],
    async execute(_, p: Static<typeof Params>, signal, _2, ctx) {
      const nb = resolveNotebook(ctx.cwd, p.notebook);
      const limit = Math.min(p.limit ?? 50, 200);
      const offset = p.offset ?? 0;
      const args = nbArgs(nb.path, ["list", "-q", "--no-pager", "--format", FMT_NOTE]);
      if (p.match) args.push("--match", p.match);
      const tags = [...(p.tags ?? []).map(t => t.trim()).filter(Boolean), ...(p.exclude_tags ?? []).map(t => `NOT ${t.trim()}`)];
      if (tags.length) args.push("--tag", tags.join(", "));
      if (p.created_after) args.push("--created-after", p.created_after);
      if (p.modified_after) args.push("--modified-after", p.modified_after);
      args.push("--sort", p.sort ?? "modified-", "--limit", String(limit + offset + 1));
      for (const path of p.paths ?? []) { const t = path.trim(); if (t) args.push(t); }
      const r = await zk(args, ctx.cwd, { signal, timeout: 30_000 });
      const notes = parseNotes(r.stdout).slice(offset, offset + limit);
      const text = `Found ${notes.length} note${notes.length === 1 ? "" : "s"}:\n${renderNotes(notes)}`;
      return { content: [{ type: "text", text: await truncText(text, "pi-zk-") }], details: { notes, notebook: nb.path } };
    },
  });
}

function registerReadNote(pi: ExtensionAPI) {
  const Params = Type.Object({ path: NoteRef, notebook: NotebookOverride });
  pi.registerTool({
    name: "zk_read_note", label: "zk Read",
    description: "Read a note's full contents.",
    parameters: Params,
    promptSnippet: "zk_read_note: read note by path.",
    promptGuidelines: ["Prefer over generic read tool for notes."],
    async execute(_, p: Static<typeof Params>, signal) {
      const nb = resolveNotebook(p.notebook ? "." : process.cwd(), p.notebook);
      const abs = safeNotebookPath(nb.path, p.path);
      if (signal?.aborted) throw new Error("aborted");
      const text = await readFile(abs, "utf8");
      return { content: [{ type: "text", text: await truncText(text, "pi-zk-") }], details: { path: p.path, notebook: nb.path } };
    },
  });
}

function registerCreateNote(pi: ExtensionAPI) {
  const Params = Type.Object({
    title: Type.String({ description: "Note title. 1-200 chars." }),
    directory: Type.Optional(Type.String({ description: "Notebook-relative subdirectory." })),
    template: Type.Optional(Type.String({ description: "zk template name." })),
    content: Type.Optional(Type.String({ description: "Optional body appended after template." })),
    notebook: NotebookOverride,
  });
  pi.registerTool({
    name: "zk_create_note", label: "zk Create",
    description: "Create a new note via `zk new`. Returns notebook-relative path.",
    parameters: Params,
    promptSnippet: "zk_create_note: create note with optional template.",
    promptGuidelines: ["Use instead of writing files by hand so zk rules apply."],
    async execute(_, p: Static<typeof Params>, signal, _2, ctx) {
      const nb = resolveNotebook(ctx.cwd, p.notebook);
      const title = validateTitle(p.title);
      const dir = p.directory ? validateDir(p.directory) : undefined;
      if (dir) await mkdir(resolve(nb.path, dir), { recursive: true });
      const args = nbArgs(nb.path, ["new", "--print-path", "--title", title, ...(p.template ? ["--template", p.template] : []), ...(dir ? [dir] : [])]);
      const r = await zk(args, nb.path, { signal, timeout: 15_000, env: { ZK_EDITOR: "true", EDITOR: "true", VISUAL: "true" } });
      const printed = r.stdout.trim().split("\n").pop()?.trim();
      if (!printed) throw new Error("zk new did not print a path");
      const abs = isAbsolute(printed) ? safeNotebookPath(nb.path, relative(nb.path, printed)) : safeNotebookPath(nb.path, printed);
      const rel = relative(nb.path, abs);
      if (p.content) await appendFile(abs, p.content.endsWith("\n") ? p.content : `${p.content}\n`, "utf8");
      return { content: [{ type: "text", text: `Created ${rel}` }], details: { path: rel, notebook: nb.path } };
    },
  });
}

function registerEditNote(pi: ExtensionAPI) {
  const Edit = Type.Object({ oldText: Type.String(), newText: Type.String() });
  const Params = Type.Object({ path: NoteRef, edits: Type.Array(Edit, { minItems: 1 }), notebook: NotebookOverride });
  pi.registerTool({
    name: "zk_edit_note", label: "zk Edit",
    description: "Apply exact text-replacement edits. Each oldText must match exactly once.",
    parameters: Params,
    promptSnippet: "zk_edit_note: surgical text replacements.",
    promptGuidelines: ["Prefer over re-writing entire note."],
    async execute(_, p: Static<typeof Params>, signal) {
      const nb = resolveNotebook(p.notebook ? "." : process.cwd(), p.notebook);
      const abs = safeNotebookPath(nb.path, p.path);
      if (signal?.aborted) throw new Error("aborted");
      const before = await readFile(abs, "utf8");
      const after = applyEdits(before, p.edits);
      await writeFile(abs, after, "utf8");
      return { content: [{ type: "text", text: `Edited ${p.path}: ${p.edits.length} edit(s) applied` }], details: { path: p.path, notebook: nb.path } };
    },
  });
}

function registerAppendNote(pi: ExtensionAPI) {
  const Params = Type.Object({ path: NoteRef, content: Type.String({ minLength: 1 }), notebook: NotebookOverride });
  pi.registerTool({
    name: "zk_append_note", label: "zk Append",
    description: "Append markdown to a note. Ensures blank line separator.",
    parameters: Params,
    promptSnippet: "zk_append_note: append block to note.",
    promptGuidelines: ["Use for daily-log style additions."],
    async execute(_, p: Static<typeof Params>, signal) {
      const nb = resolveNotebook(p.notebook ? "." : process.cwd(), p.notebook);
      const abs = safeNotebookPath(nb.path, p.path);
      if (signal?.aborted) throw new Error("aborted");
      const before = await readFile(abs, "utf8");
      const payload = appendPayload(before, p.content);
      await appendFile(abs, payload, "utf8");
      return { content: [{ type: "text", text: `Appended to ${p.path}` }], details: { path: p.path, notebook: nb.path } };
    },
  });
}

function registerListTags(pi: ExtensionAPI) {
  const Params = Type.Object({ notebook: NotebookOverride });
  pi.registerTool({
    name: "zk_list_tags", label: "zk Tags",
    description: "List all tags with note counts.",
    parameters: Params,
    promptSnippet: "zk_list_tags: list tags.",
    promptGuidelines: ["Use when user asks about tags."],
    async execute(_, p: Static<typeof Params>, signal, _2, ctx) {
      const nb = resolveNotebook(ctx.cwd, p.notebook);
      const r = await zk(nbArgs(nb.path, ["tag", "list", "-q", "--no-pager", "--format", FMT_TAG]), ctx.cwd, { signal, timeout: 15_000 });
      const tags = parseTags(r.stdout).sort((a, b) => b.count - a.count);
      return { content: [{ type: "text", text: await truncText(renderTags(tags), "pi-zk-") }], details: { tags, notebook: nb.path } };
    },
  });
}

function registerLinkGraph(pi: ExtensionAPI, name: string, label: string, desc: string, snippet: string, flag: string, recursive: boolean) {
  const Params = Type.Object({
    path: NoteRef,
    limit: Type.Optional(Type.Number({ minimum: 1, maximum: 200 })),
    offset: Type.Optional(Type.Number({ minimum: 0 })),
    sort: Type.Optional(Type.String()),
    ...(recursive ? { recursive: Type.Optional(Type.Boolean()), max_distance: Type.Optional(Type.Number({ minimum: 1 })) } : {}),
    notebook: NotebookOverride,
  });
  pi.registerTool({
    name, label, description: desc, parameters: Params,
    promptSnippet: snippet, promptGuidelines: [],
    async execute(_, p: Static<typeof Params>, signal, _2, ctx) {
      const nb = resolveNotebook(ctx.cwd, p.notebook);
      const limit = Math.min(p.limit ?? 50, 200);
      const offset = p.offset ?? 0;
      const args = nbArgs(nb.path, ["list", "-q", "--no-pager", "--format", FMT_NOTE, flag, p.path as string, "--sort", (p.sort as string) ?? "modified-", "--limit", String(limit + offset + 1)]);
      if (recursive && (p as any).recursive) args.push("--recursive");
      if (recursive && (p as any).max_distance) args.push("--max-distance", String((p as any).max_distance));
      const r = await zk(args, ctx.cwd, { signal, timeout: 30_000 });
      const notes = parseNotes(r.stdout).slice(offset, offset + limit);
      const text = `Found ${notes.length} note${notes.length === 1 ? "" : "s"}:\n${renderNotes(notes)}`;
      return { content: [{ type: "text", text: await truncText(text, "pi-zk-") }], details: { notes, notebook: nb.path } };
    },
  });
}

function registerLastModified(pi: ExtensionAPI) {
  const Params = Type.Object({ tag: Type.Optional(Type.String()), notebook: NotebookOverride });
  pi.registerTool({
    name: "zk_last_modified", label: "zk Last Modified",
    description: "Most recently modified note.",
    parameters: Params,
    promptSnippet: "zk_last_modified: last edited note.",
    promptGuidelines: [],
    async execute(_, p: Static<typeof Params>, signal, _2, ctx) {
      const nb = resolveNotebook(ctx.cwd, p.notebook);
      const args = nbArgs(nb.path, ["list", "-q", "--no-pager", "--format", FMT_NOTE, "--sort", "modified-", "--limit", "1", ...(p.tag?.trim() ? ["--tag", p.tag.trim()] : [])]);
      const r = await zk(args, ctx.cwd, { signal, timeout: 10_000 });
      const notes = parseNotes(r.stdout);
      return { content: [{ type: "text", text: notes[0] ? renderNotes(notes) : "No notes found." }], details: { note: notes[0], notebook: nb.path } };
    },
  });
}

function registerRandomNote(pi: ExtensionAPI) {
  const Params = Type.Object({ tag: Type.Optional(Type.String()), notebook: NotebookOverride });
  pi.registerTool({
    name: "zk_random_note", label: "zk Random",
    description: "One randomly selected note.",
    parameters: Params,
    promptSnippet: "zk_random_note: random note.",
    promptGuidelines: [],
    async execute(_, p: Static<typeof Params>, signal, _2, ctx) {
      const nb = resolveNotebook(ctx.cwd, p.notebook);
      const args = nbArgs(nb.path, ["list", "-q", "--no-pager", "--format", FMT_NOTE, "--sort", "random", "--limit", "1", ...(p.tag?.trim() ? ["--tag", p.tag.trim()] : [])]);
      const r = await zk(args, ctx.cwd, { signal, timeout: 10_000 });
      const notes = parseNotes(r.stdout);
      return { content: [{ type: "text", text: notes[0] ? renderNotes(notes) : "No notes found." }], details: { note: notes[0], notebook: nb.path } };
    },
  });
}

function registerTaglessNotes(pi: ExtensionAPI) {
  const Params = Type.Object({
    limit: Type.Optional(Type.Number({ minimum: 1, maximum: 200 })),
    offset: Type.Optional(Type.Number({ minimum: 0 })),
    notebook: NotebookOverride,
  });
  pi.registerTool({
    name: "zk_tagless_notes", label: "zk Tagless",
    description: "Notes with no tags. Useful for triage.",
    parameters: Params,
    promptSnippet: "zk_tagless_notes: untagged notes.",
    promptGuidelines: [],
    async execute(_, p: Static<typeof Params>, signal, _2, ctx) {
      const nb = resolveNotebook(ctx.cwd, p.notebook);
      const limit = Math.min(p.limit ?? 50, 200);
      const offset = p.offset ?? 0;
      const args = nbArgs(nb.path, ["list", "-q", "--no-pager", "--tagless", "--sort", "modified-", "--format", FMT_NOTE, "--limit", String(limit + offset + 1)]);
      const r = await zk(args, ctx.cwd, { signal, timeout: 15_000 });
      const notes = parseNotes(r.stdout).slice(offset, offset + limit);
      const text = `Found ${notes.length} untagged note${notes.length === 1 ? "" : "s"}:\n${renderNotes(notes)}`;
      return { content: [{ type: "text", text: await truncText(text, "pi-zk-") }], details: { notes, notebook: nb.path } };
    },
  });
}

// ── Entry point ────────────────────────────────────────────────────────────

const MUTATING = new Set(["zk_create_note", "zk_edit_note", "zk_append_note"]);

export default function piZkExtension(pi: ExtensionAPI): void {
  registerSearchNotes(pi);
  registerReadNote(pi);
  registerCreateNote(pi);
  registerEditNote(pi);
  registerAppendNote(pi);
  registerListTags(pi);
  registerLinkGraph(pi, "zk_link_to", "zk Backlinks", "Notes that link TO this note.", "zk_link_to: backlinks.", "--link-to", true);
  registerLinkGraph(pi, "zk_linked_by", "zk Outbound", "Notes this note links TO.", "zk_linked_by: outbound links.", "--linked-by", true);
  registerLinkGraph(pi, "zk_related", "zk Related", "Notes sharing neighbors.", "zk_related: related notes.", "--related", false);
  registerLastModified(pi);
  registerRandomNote(pi);
  registerTaglessNotes(pi);

  const caches = new Map<string, NoteCache>();
  let activeNb: Notebook | undefined;

  pi.on("session_start", async (_, ctx) => {
    try { activeNb = resolveNotebook(ctx.cwd); } catch { activeNb = undefined; return; }
    const cache = new NoteCache(activeNb.path, ctx.cwd);
    caches.set(activeNb.path, cache);
    void cache.get();
    ctx.ui.addAutocompleteProvider(cur => createWikilinkProvider(cur, cache));
  });

  pi.on("before_agent_start", (e) => {
    if (!activeNb) return undefined;
    return { systemPrompt: `${e.systemPrompt}\n\n${guidance(activeNb)}` };
  });

  pi.on("tool_result", (e) => {
    if (!MUTATING.has(e.toolName) || e.isError) return;
    const nb = (e.details as any)?.notebook as string | undefined;
    if (nb) caches.get(nb)?.invalidate();
  });
}
