/**
 * Pi Database Extension — lightweight Postgres/Docker integration
 *
 * Auto-discovers databases from docker-compose files and provides
 * tools for querying, schema introspection, and container management.
 *
 * No encrypted secrets, no web UI — just reads connection info from
 * docker-compose.yml/docker-compose.yaml files in the project tree
 * and connects via the running containers (or exposed ports).
 *
 * Tools:
 *   db_discover         — find databases in docker-compose files
 *   db_query            — execute SQL
 *   db_tables           — list tables
 *   db_describe         — show column definitions
 *   db_views            — list views
 *   db_indexes          — list indexes on a table
 *   db_info             — show database server info
 *
 * Commands:
 *   /db                 — show discovered databases
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@mariozechner/pi-ai";
import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { join, basename } from "node:path";

// ── Types ─────────────────────────────────────────────────────────────────────

interface DiscoveredDB {
	name: string;
	project: string;
	composeFile: string;
	service: string;
	host: string;
	port: number;
	database: string;
	user: string;
	container: string | undefined;
}

// ── Docker Compose Discovery ──────────────────────────────────────────────────

function findComposeFiles(cwd: string, maxDepth = 3): string[] {
	const results: string[] = [];
	const names = ["docker-compose.yml", "docker-compose.yaml", "compose.yml", "compose.yaml"];

	function walk(dir: string, depth: number) {
		if (depth > maxDepth) return;
		try {
			for (const entry of readdirSync(dir, { withFileTypes: true })) {
				if (entry.name.startsWith(".") || entry.name === "node_modules" || entry.name === ".git") continue;
				if (names.includes(entry.name)) {
					results.push(join(dir, entry.name));
				}
				if (entry.isDirectory()) {
					walk(join(dir, entry.name), depth + 1);
				}
			}
		} catch { /* skip unreadable dirs */ }
	}

	walk(cwd, 0);
	return results;
}

function parseYamlPorts(portSpec: unknown): { host: number; container: number }[] {
	if (!portSpec) return [];
	const ports: { host: number; container: number }[] = [];

	const items = Array.isArray(portSpec) ? portSpec : [portSpec];
	for (const item of items) {
		if (typeof item === "string") {
			// "5432:5432" or "0.0.0.0:5432:5432"
			const parts = item.split(":");
			if (parts.length >= 2) {
				const hostPort = parseInt(parts[parts.length === 2 ? 0 : 1], 10);
				const containerPort = parseInt(parts[parts.length === 2 ? 1 : 2], 10);
				if (!isNaN(hostPort) && !isNaN(containerPort)) {
					ports.push({ host: hostPort, container: containerPort });
				}
			}
		} else if (typeof item === "object" && item !== null) {
			// { target: 5432, published: "5432" }
			const obj = item as Record<string, unknown>;
			const host = typeof obj.published === "string" ? parseInt(obj.published, 10) : (typeof obj.target === "number" ? obj.target : NaN);
			const container = typeof obj.target === "number" ? obj.target : NaN;
			if (!isNaN(host) && !isNaN(container)) {
				ports.push({ host, container });
			}
		}
	}
	return ports;
}

interface ParsedService {
	image?: string;
	environment?: Record<string, string> | string[];
	ports?: unknown[];
	container_name?: string;
}

function extractEnvVars(env: Record<string, string> | string[] | undefined): Record<string, string> {
	if (!env) return {};
	if (Array.isArray(env)) {
		const map: Record<string, string> = {};
		for (const item of env) {
			if (typeof item === "string") {
				const eq = item.indexOf("=");
				if (eq >= 0) map[item.slice(0, eq)] = item.slice(eq + 1);
			}
		}
		return map;
	}
	return env;
}

/**
 * Minimal YAML parser — only handles the subset we need for docker-compose.
 * Extracts top-level services and their image/ports/environment/container_name.
 */
function parseComposeServices(content: string): Map<string, ParsedService> {
	const services = new Map<string, ParsedService>();
	const lines = content.split("\n");

	let inServices = false;
	let currentService: string | undefined;
	let serviceIndent = 0;
	let currentKey: string | undefined;

	// Known postgres-like images
	const pgImages = ["postgres", "pg", "timescale/timescaledb", "postgis/postgis", "neondatabase/neon", "supabase/postgres"];

	for (let i = 0; i < lines.length; i++) {
		const line = lines[i];
		const indent = line.search(/\S/);
		const trimmed = line.trim();

		if (trimmed === "" || trimmed.startsWith("#")) continue;

		// Top-level "services:" key
		if (indent === 0 && trimmed === "services:") {
			inServices = true;
			continue;
		}

		if (indent === 0) {
			// Another top-level section — stop parsing services
			if (trimmed.endsWith(":") && trimmed !== "services:") {
				inServices = false;
				currentService = undefined;
			}
			continue;
		}

		if (!inServices) continue;

		// Service name (first indent level under services:)
		if (indent === 2 && trimmed.endsWith(":") && !trimmed.includes(" ")) {
			currentService = trimmed.slice(0, -1);
			services.set(currentService, {});
			serviceIndent = indent;
			currentKey = undefined;
			continue;
		}

		if (!currentService) continue;

		const svc = services.get(currentService)!;

		// Second-level keys
		if (indent === 4 && trimmed.endsWith(":")) {
			currentKey = trimmed.slice(0, -1);
			continue;
		}

		// Values
		if (indent >= 6 && currentKey === "image" && !trimmed.endsWith(":")) {
			svc.image = trimmed.replace(/^["']|["']$/g, "");
		}

		if (indent === 4 && trimmed.startsWith("container_name:")) {
			svc.container_name = trimmed.split(":").slice(1).join(":").trim().replace(/^["']|["']$/g, "");
		}

		if (indent === 4 && trimmed.startsWith("image:")) {
			svc.image = trimmed.split(":").slice(1).join(":").trim().replace(/^["']|["']$/g, "");
		}
	}

	return services;
}

function discoverDatabases(cwd: string): DiscoveredDB[] {
	const databases: DiscoveredDB[] = [];
	const composeFiles = findComposeFiles(cwd);

	const pgImages = ["postgres", "timescale/timescaledb", "postgis/postgis", "neondatabase/neon", "supabase/postgres"];

	for (const file of composeFiles) {
		try {
			const content = readFileSync(file, "utf-8");
			const services = parseComposeServices(content);
			const projectName = basename(join(file, "..")).replace(/[^a-zA-Z0-9]/g, "");

			for (const [svcName, svc] of services) {
				// Check if it's a postgres-like image
				const image = (svc.image || "").toLowerCase();
				const isPostgres = pgImages.some((pg) => image.includes(pg));
				if (!isPostgres) continue;

				// Parse ports
				// Since our minimal parser doesn't fully parse ports arrays,
				// default to standard postgres port
				const port = 5432;

				// Default connection info
				const db: DiscoveredDB = {
					name: `${projectName}_${svcName}`,
					project: projectName,
					composeFile: file,
					service: svcName,
					host: "localhost",
					port,
					database: "postgres",
					user: "postgres",
					container: svc.container_name || `${projectName}-${svcName}-1`,
				};

				databases.push(db);
			}
		} catch { /* skip unreadable files */ }
	}

	return databases;
}

// ── Postgres Client (via docker exec or direct pg connection) ─────────────────

async function execPg(pi: ExtensionAPI, db: DiscoveredDB, sql: string, format: "table" | "json" | "csv" = "table"): Promise<string> {
	// Try docker exec first (works even without exposed ports)
	const container = db.container;
	if (container) {
		const psqlArgs = [
			"exec", container,
			"psql",
			"-U", db.user,
			"-d", db.database,
			"-c", sql,
		];

		if (format === "json") {
			psqlArgs.splice(5, 0, "-t", "-A");
		}

		const result = await pi.exec("docker", psqlArgs, { timeout: 30_000 });
		if (result.code === 0) {
			if (format === "json") {
				// psql -t -A returns raw values; try JSON format instead
				const jsonArgs = [
					"exec", container,
					"psql", "-U", db.user, "-d", db.database,
					"-t", "-A",
					"-c", `SELECT json_agg(row_to_json(t)) FROM (${sql}) t`,
				];
				const jsonResult = await pi.exec("docker", jsonArgs, { timeout: 30_000 });
				if (jsonResult.code === 0 && jsonResult.stdout.trim()) {
					return jsonResult.stdout.trim() === "null" ? "[]" : jsonResult.stdout.trim();
				}
			}
			return result.stdout;
		}

		// If docker exec fails (container not running), fall through to direct connection
	}

	// Fallback: try direct connection via psql on host
	const psqlArgs = [
		"-h", db.host,
		"-p", String(db.port),
		"-U", db.user,
		"-d", db.database,
		"-c", sql,
	];

	if (format === "json") {
		psqlArgs.splice(1, 0, "-t", "-A");
	}

	const result = await pi.exec("psql", psqlArgs, {
		timeout: 30_000,
		env: { PGPASSWORD: "postgres" }, // default, user can override
	});

	if (result.code !== 0 && !result.killed) {
		throw new Error(`psql failed: ${result.stderr || result.stdout}`);
	}

	if (format === "json") {
		const jsonArgs = [
			"-t", "-A",
			"-h", db.host,
			"-p", String(db.port),
			"-U", db.user,
			"-d", db.database,
			"-c", `SELECT json_agg(row_to_json(t)) FROM (${sql}) t`,
		];
		const jsonResult = await pi.exec("psql", jsonArgs, {
			timeout: 30_000,
			env: { PGPASSWORD: "postgres" },
		});
		if (jsonResult.code === 0 && jsonResult.stdout.trim()) {
			return jsonResult.stdout.trim() === "null" ? "[]" : jsonResult.stdout.trim();
		}
	}

	return result.stdout;
}

function resolveDb(discovered: DiscoveredDB[], name: string | undefined): DiscoveredDB {
	if (!name) {
		if (discovered.length === 0) throw new Error("No databases discovered. Run db_discover first.");
		if (discovered.length === 1) return discovered[0];
		throw new Error(`Multiple databases found. Specify one: ${discovered.map((d) => d.name).join(", ")}`);
	}
	const db = discovered.find((d) => d.name === name || d.service === name);
	if (!db) throw new Error(`Database "${name}" not found. Available: ${discovered.map((d) => d.name).join(", ")}`);
	return db;
}

// ── Extension ─────────────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
	let cachedDbs: DiscoveredDB[] | undefined;

	async function getDbs(cwd: string): Promise<DiscoveredDB[]> {
		if (!cachedDbs) cachedDbs = discoverDatabases(cwd);
		return cachedDbs;
	}

	function invalidateCache() {
		cachedDbs = undefined;
	}

	// ── Tools ──────────────────────────────────────────────────────────────

	pi.registerTool({
		name: "db_discover",
		label: "Discover Databases",
		description: "Scan docker-compose files in the project for Postgres databases",
		parameters: Type.Object({}),
		async execute(_id, _params, _sig, onUpdate) {
			onUpdate?.({ content: [{ type: "text", text: "Scanning for databases..." }] });
			invalidateCache();
			const dbs = await getDbs(pi.cwd);

			if (dbs.length === 0) {
				return {
					content: [{ type: "text", text: "No Postgres databases found in docker-compose files." }],
					details: { databases: [] },
				};
			}

			const summary = dbs.map((d) => ({
				name: d.name,
				service: d.service,
				host: d.host,
				port: d.port,
				database: d.database,
				user: d.user,
				container: d.container,
				composeFile: d.composeFile,
			}));

			const text = [
				`Found ${dbs.length} Postgres database(s):`,
				...dbs.map((d) => `  • ${d.name} — ${d.service} (${d.host}:${d.port}/${d.database}) container=${d.container || "n/a"}`),
			].join("\n");

			return {
				content: [{ type: "text", text }],
				details: { databases: summary },
			};
		},
	});

	pi.registerTool({
		name: "db_query",
		label: "Database Query",
		description: "Execute a SQL query against a discovered Postgres database",
		parameters: Type.Object({
			sql: Type.String({ description: "SQL query to execute" }),
			database: Type.Optional(Type.String({ description: "Database name (from db_discover). Auto-selects if only one found." })),
			format: Type.Optional(Type.String({ description: "Output format: table, json, or csv", default: "table" })),
		}),
		async execute(_id, params, _sig, onUpdate) {
			onUpdate?.({ content: [{ type: "text", text: `Executing query on ${params.database || "default"}...` }] });
			const dbs = await getDbs(pi.cwd);
			const db = resolveDb(dbs, params.database);
			const format = (params.format || "table") as "table" | "json" | "csv";
			const output = await execPg(pi, db, params.sql, format);
			return {
				content: [{ type: "text", text: output }],
				details: { database: db.name, sql: params.sql, format },
			};
		},
	});

	pi.registerTool({
		name: "db_tables",
		label: "Database Tables",
		description: "List tables in a discovered Postgres database",
		parameters: Type.Object({
			database: Type.Optional(Type.String({ description: "Database name. Auto-selects if only one found." })),
			schema: Type.Optional(Type.String({ description: "Filter by schema (default: all non-system schemas)" })),
		}),
		async execute(_id, params, _sig, onUpdate) {
			onUpdate?.({ content: [{ type: "text", text: "Listing tables..." }] });
			const dbs = await getDbs(pi.cwd);
			const db = resolveDb(dbs, params.database);
			const schemaFilter = params.schema
				? ` WHERE schemaname = '${params.schema.replace(/'/g, "''")}'`
				: " WHERE schemaname NOT IN ('pg_catalog', 'information_schema')";
			const sql = `SELECT schemaname AS schema, tablename AS table, tableowner AS owner FROM pg_catalog.pg_tables${schemaFilter} ORDER BY schemaname, tablename;`;
			const output = await execPg(pi, db, sql);
			return { content: [{ type: "text", text: output }], details: { database: db.name } };
		},
	});

	pi.registerTool({
		name: "db_describe",
		label: "Describe Table",
		description: "Show column definitions for a table in a discovered Postgres database",
		parameters: Type.Object({
			table: Type.String({ description: "Table name (supports schema.table notation)" }),
			database: Type.Optional(Type.String({ description: "Database name. Auto-selects if only one found." })),
		}),
		async execute(_id, params, _sig, onUpdate) {
			onUpdate?.({ content: [{ type: "text", text: `Describing ${params.table}...` }] });
			const dbs = await getDbs(pi.cwd);
			const db = resolveDb(dbs, params.database);
			const parts = params.table.split(".");
			const table = parts.length > 1 ? parts[1] : parts[0];
			const schema = parts.length > 1 ? parts[0] : "public";
			const sql = `SELECT column_name, data_type, is_nullable, column_default, character_maximum_length FROM information_schema.columns WHERE table_name = '${table.replace(/'/g, "''")}' AND table_schema = '${schema.replace(/'/g, "''")}' ORDER BY ordinal_position;`;
			const output = await execPg(pi, db, sql);
			return { content: [{ type: "text", text: output }], details: { database: db.name, table: params.table } };
		},
	});

	pi.registerTool({
		name: "db_views",
		label: "Database Views",
		description: "List views in a discovered Postgres database",
		parameters: Type.Object({
			database: Type.Optional(Type.String({ description: "Database name. Auto-selects if only one found." })),
			schema: Type.Optional(Type.String({ description: "Filter by schema" })),
		}),
		async execute(_id, params, _sig, onUpdate) {
			onUpdate?.({ content: [{ type: "text", text: "Listing views..." }] });
			const dbs = await getDbs(pi.cwd);
			const db = resolveDb(dbs, params.database);
			const schemaFilter = params.schema
				? ` WHERE schemaname = '${params.schema.replace(/'/g, "''")}'`
				: " WHERE schemaname NOT IN ('pg_catalog', 'information_schema')";
			const sql = `SELECT schemaname AS schema, viewname AS view, viewowner AS owner FROM pg_catalog.pg_views${schemaFilter} ORDER BY schemaname, viewname;`;
			const output = await execPg(pi, db, sql);
			return { content: [{ type: "text", text: output }], details: { database: db.name } };
		},
	});

	pi.registerTool({
		name: "db_indexes",
		label: "Table Indexes",
		description: "List indexes on a table in a discovered Postgres database",
		parameters: Type.Object({
			table: Type.String({ description: "Table name (supports schema.table notation)" }),
			database: Type.Optional(Type.String({ description: "Database name. Auto-selects if only one found." })),
		}),
		async execute(_id, params, _sig, onUpdate) {
			onUpdate?.({ content: [{ type: "text", text: `Listing indexes on ${params.table}...` }] });
			const dbs = await getDbs(pi.cwd);
			const db = resolveDb(dbs, params.database);
			const parts = params.table.split(".");
			const table = parts.length > 1 ? parts[1] : parts[0];
			const schema = parts.length > 1 ? parts[0] : "public";
			const sql = `SELECT indexname AS index, indexdef AS definition FROM pg_indexes WHERE tablename = '${table.replace(/'/g, "''")}' AND schemaname = '${schema.replace(/'/g, "''")}' ORDER BY indexname;`;
			const output = await execPg(pi, db, sql);
			return { content: [{ type: "text", text: output }], details: { database: db.name, table: params.table } };
		},
	});

	pi.registerTool({
		name: "db_info",
		label: "Database Info",
		description: "Show server info for a discovered Postgres database",
		parameters: Type.Object({
			database: Type.Optional(Type.String({ description: "Database name. Auto-selects if only one found." })),
		}),
		async execute(_id, params, _sig, onUpdate) {
			onUpdate?.({ content: [{ type: "text", text: "Fetching database info..." }] });
			const dbs = await getDbs(pi.cwd);
			const db = resolveDb(dbs, params.database);
			const sql = "SELECT version() AS version, current_database() AS database, current_user AS user, inet_server_addr() AS host, inet_server_port() AS port;";
			const output = await execPg(pi, db, sql);
			return { content: [{ type: "text", text: output }], details: { database: db.name } };
		},
	});

	// ── Command ────────────────────────────────────────────────────────────

	pi.registerCommand("db", {
		description: "Show discovered databases from docker-compose files",
		handler: async (_args, ctx) => {
			invalidateCache();
			const dbs = await getDbs(ctx.cwd);
			if (dbs.length === 0) {
				ctx.ui.notify("No Postgres databases found in docker-compose files.", "warning");
				return;
			}
			const lines = [
				`Found ${dbs.length} database(s):`,
				...dbs.map((d) => `  • ${d.name} — ${d.host}:${d.port}/${d.database} (container: ${d.container || "n/a"})`),
			];
			ctx.ui.notify(lines.join("\n"), "info");
		},
	});

	// Invalidate cache on reload
	pi.on("session_start", async () => { invalidateCache(); });
}
