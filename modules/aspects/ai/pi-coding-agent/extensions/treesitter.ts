import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import fs from "node:fs";
import path from "node:path";

type TextResult = { content: { type: "text"; text: string }[]; details: Record<string, unknown> };

function textResult(text: string, details: Record<string, unknown> = {}): TextResult {
	return { content: [{ type: "text" as const, text }], details };
}

function errorResult(message: string, details: Record<string, unknown> = {}): TextResult {
	return textResult(`Error: ${message}`, details);
}

const ToolSchema = Type.Object({
	action: Type.Union([Type.Literal("read_code_structure"), Type.Literal("read_code_symbol")]),
	file: Type.String({ description: "Path to file (relative or absolute)" }),
	symbol: Type.Optional(Type.String({ description: "Symbol name (for read_code_symbol)" })),
	max_results: Type.Optional(Type.Integer({ description: "Max outline entries (default 200)", minimum: 1, maximum: 2000 })),
});

function luaStringLiteral(s: string): string {
	// single-quoted lua string with basic escapes
	return `'${s.replace(/\\/g, "\\\\").replace(/'/g, "\\'")}'`;
}

function buildLuaFile(action: string, symbol?: string, maxResults = 200): string {
	const symLit = symbol ? luaStringLiteral(symbol) : "nil";
	const maxLit = String(maxResults);
	const actionLit = luaStringLiteral(action);
	return [
		`local want=${symLit}`,
		`local max_results=${maxLit}`,
		`local action=${actionLit}`,
		"local function out(t) print('PI_TS_JSON:'..vim.json.encode(t)) end",
		"vim.cmd('filetype detect')",
		"local ft = vim.bo.filetype",
		"local lang = vim.treesitter.language.get_lang(ft)",
		"if not lang then out({ok=false,error='no treesitter lang for ft='..tostring(ft)}); return end",
		"local okp, parser = pcall(vim.treesitter.get_parser, 0, lang)",
		"if not okp or not parser then out({ok=false,error='no treesitter parser for '..tostring(lang)}); return end",
		"local tree = parser:parse()[1]",
		"local root = tree:root()",
		"local queries = {}",
		"queries.typescript = [[ (import_statement) @import (function_declaration name:(identifier) @name) @def (class_declaration name:(identifier) @name) @def (interface_declaration name:(identifier) @name) @def (type_alias_declaration name:(type_identifier) @name) @def (enum_declaration name:(identifier) @name) @def (method_definition name:(property_identifier) @name) @def ]]",
		"queries.tsx = queries.typescript",
		"queries.javascript = [[ (import_statement) @import (function_declaration name:(identifier) @name) @def (class_declaration name:(identifier) @name) @def (method_definition name:(property_identifier) @name) @def ]]",
		"queries.go = [[ (import_spec) @import (function_declaration name:(identifier) @name) @def (method_declaration name:(field_identifier) @name) @def (type_spec name:(type_identifier) @name) @def ]]",
		"queries.python = [[ (import_statement) @import (import_from_statement) @import (function_definition name:(identifier) @name) @def (class_definition name:(identifier) @name) @def ]]",
		"local qstr = queries[ft] or queries[lang]",
		"if not qstr then out({ok=false,error='no query for ft='..tostring(ft)..' lang='..tostring(lang)}); return end",
		"local okq, query = pcall(vim.treesitter.query.parse, lang, qstr)",
		"if not okq then out({ok=false,error='query parse failed',details=query}); return end",
		"local results = {}",
		"local function add(kind, name, node) local sr,_,er,_ = node:range(); table.insert(results, {kind=kind,name=name,start_line=sr+1,end_line=er+1}) end",
		"local imported, defined = 0, 0",
		"for id,node,_ in query:iter_captures(root, 0, 0, -1) do local cap = query.captures[id]; if cap == 'import' then imported = imported + 1; if imported <= max_results then local txt = vim.treesitter.get_node_text(node, 0) or ''; add('import', (txt:gsub('%s+',' '):gsub('^%s+',''):gsub('%s+$','')), node); end elseif cap == 'def' then defined = defined + 1; if defined <= max_results then local name=''; for cid,cnode,_ in query:iter_captures(node,0,node:start(),node:end_()) do if query.captures[cid]=='name' then name = vim.treesitter.get_node_text(cnode,0) or ''; break end end; if name=='' then name = vim.treesitter.get_node_text(node,0) or '' end; add('def', name, node); end end end",
		"table.sort(results, function(a,b) return a.start_line < b.start_line end)",
		"if action == 'read_code_structure' then out({ok=true,ft=ft,lang=lang,results=results}); return end",
		"if not want then out({ok=false,error='symbol required'}); return end",
		"for _,r in ipairs(results) do if r.kind=='def' and r.name==want then local lines = vim.api.nvim_buf_get_lines(0, r.start_line-1, r.end_line, false); out({ok=true,ft=ft,lang=lang,match=r,source=table.concat(lines,'\\n')}); return end end",
		"out({ok=false,error='symbol not found',symbol=want,ft=ft,lang=lang,available=results})",
	].join("\n") + "\n";
}

async function runNvim(pi: ExtensionAPI, args: string[], timeoutMs: number): Promise<{ ok: boolean; stdout: string; stderr: string; exitCode: number }> {
	const r = await pi.exec("nvim", args, { timeout: timeoutMs });
	const exitCode = typeof (r as any).exitCode === "number" ? (r as any).exitCode : Number((r as any).exitCode ?? 0);
	return { ok: exitCode === 0, stdout: (r as any).stdout ?? "", stderr: (r as any).stderr ?? "", exitCode };
}

export default function treesitterExtension(pi: ExtensionAPI): void {
	pi.registerTool({
		name: "read_code_structure",
		label: "Read Code Structure",
		description: "Outline imports + top-level symbols with line ranges (treesitter via headless neovim)",
		parameters: Type.Object({
			file: Type.String({ description: "Path to file (relative or absolute)" }),
			max_results: Type.Optional(Type.Integer({ description: "Max outline entries (default 200)", minimum: 1, maximum: 2000 })),
		}),
		async execute(_id, params: any) {
			try {
				const cwd = params.cwd ?? pi.cwd ?? process.cwd();
				const filePath = path.isAbsolute(params.file) ? params.file : path.join(cwd, params.file);
				if (!fs.existsSync(filePath)) return errorResult(`file not found: ${params.file}`);
				const maxResults = typeof params.max_results === "number" ? params.max_results : 200;
				const lua = buildLuaFile("read_code_structure", undefined, maxResults);
				const luaPath = path.join("/tmp", `pi-treesitter-${process.pid}.lua`);
				fs.writeFileSync(luaPath, lua, "utf8");
				const r = await runNvim(pi, ["--headless", "--clean", "+e " + filePath, "+luafile " + luaPath, "+q"], 30_000);
				try { fs.unlinkSync(luaPath); } catch {}
				if (!r.ok) return errorResult(`nvim failed (exit ${r.exitCode})`, { stderr: r.stderr, stdout: r.stdout });
				const jsonLines = r.stdout
					.split(/\r?\n/)
					.map((l) => l.trim())
					.filter((l) => l.startsWith("PI_TS_JSON:"));
				const payload = jsonLines.pop()?.slice("PI_TS_JSON:".length) ?? "";
				let data: any;
				try { data = JSON.parse(payload); } catch (e: any) { return errorResult("invalid nvim json output", { stdout: r.stdout, stderr: r.stderr, error: String(e?.message ?? e) }); }
				if (!data.ok) return errorResult(data.error ?? "unknown error", data.details ?? data);
				const lines: string[] = [];
				lines.push(`${params.file} (${data.ft}/${data.lang})`);
				for (const it of data.results as any[]) {
					const range = `${it.start_line}-${it.end_line}`;
					const kind = it.kind === "import" ? "imp" : "sym";
					lines.push(`${kind} ${range.padEnd(9)} ${String(it.name)}`);
				}
				return textResult(lines.join("\n"), { ft: data.ft, lang: data.lang, count: (data.results ?? []).length });
			} catch (err: any) {
				return errorResult(err?.message ?? String(err));
			}
		},
	});

	pi.registerTool({
		name: "read_code_symbol",
		label: "Read Code Symbol",
		description: "Read full source for one named top-level symbol (treesitter via headless neovim)",
		parameters: Type.Object({
			file: Type.String({ description: "Path to file (relative or absolute)" }),
			symbol: Type.String({ description: "Symbol name" }),
		}),
		async execute(_id, params: any) {
			try {
				const cwd = params.cwd ?? pi.cwd ?? process.cwd();
				const filePath = path.isAbsolute(params.file) ? params.file : path.join(cwd, params.file);
				if (!fs.existsSync(filePath)) return errorResult(`file not found: ${params.file}`);
				const lua = buildLuaFile("read_code_symbol", params.symbol, 2000);
				const luaPath = path.join("/tmp", `pi-treesitter-${process.pid}.lua`);
				fs.writeFileSync(luaPath, lua, "utf8");
				const r = await runNvim(pi, ["--headless", "--clean", "+e " + filePath, "+luafile " + luaPath, "+q"], 30_000);
				try { fs.unlinkSync(luaPath); } catch {}
				if (!r.ok) return errorResult(`nvim failed (exit ${r.exitCode})`, { stderr: r.stderr, stdout: r.stdout });
				const jsonLines = r.stdout
					.split(/\r?\n/)
					.map((l) => l.trim())
					.filter((l) => l.startsWith("PI_TS_JSON:"));
				const payload = jsonLines.pop()?.slice("PI_TS_JSON:".length) ?? "";
				let data: any;
				try { data = JSON.parse(payload); } catch (e: any) { return errorResult("invalid nvim json output", { stdout: r.stdout, stderr: r.stderr, error: String(e?.message ?? e) }); }
				if (!data.ok) return errorResult(data.error ?? "unknown error", data.details ?? data);
				const header = `${params.file}:${data.match.start_line}-${data.match.end_line} (${data.ft}/${data.lang})`;
				return textResult(`${header}\n\n${data.source}`, { match: data.match, ft: data.ft, lang: data.lang });
			} catch (err: any) {
				return errorResult(err?.message ?? String(err));
			}
		},
	});
}
