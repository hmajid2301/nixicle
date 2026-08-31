// extensions/pipelines/widget-render.ts
// Pure variant-A "dashboard" renderer. Locked columns:
// glyph(1) + 2sp | name(10) + 1sp | status(8) + 1sp | time(6) + 1sp | tools(4) + 2sp | note(rest)
// NOTE: brief specified tools(3), but its own test data (tools: "read") cannot
// fit a 3-char column — widened to 4 so common tool names render untruncated.

export interface RowVM {
  branch: "root" | "tee" | "elbow" | "none";
  glyph: string;
  name: string;
  status: string;
  time: string;
  tools: string;
  note: string;
}

export interface DashboardVM {
  title: string;
  active: number;
  waiting: number;
  tokens: string;
  attention: boolean;
  rows: RowVM[];
}

// Pad to exactly n chars. Over-long values truncate to n-1 chars + "…" so
// truncation is visible while the fixed-width column invariant holds (review T9-1).
function pad(value: string, n: number): string {
  if (value.length > n) return value.slice(0, n - 1) + "…";
  return value + " ".repeat(n - value.length);
}

function trunc(value: string, n: number): string {
  return value.length <= n ? value : value.slice(0, Math.max(0, n - 1)) + "…";
}

export function renderDashboard(vm: DashboardVM, width = 60): string[] {
  const top = `╭${"─".repeat(width - 2)}╮`;
  const bottom = `╰${"─".repeat(width - 2)}╯`;
  const line = (inner: string): string => {
    const body = inner.length >= width - 4 ? trunc(inner, width - 4) : inner.padEnd(width - 4);
    return `│ ${body} │`;
  };
  const header = line(
    `${vm.title}${vm.attention ? " ⚑" : ""} · ●${vm.active} active · ○${vm.waiting} waiting · ${vm.tokens} tok`,
  );
  const branchPrefix = (r: RowVM): string =>
    r.branch === "root" ? "  "
    : r.branch === "tee" ? "  ├ "
    : r.branch === "elbow" ? "  └ "
    : "";
  const rows = vm.rows.map((r) => {
    const body =
      `${r.glyph}  ${pad(r.name, 10)} ${pad(r.status, 8)} ${pad(r.time, 6)} ${pad(r.tools, 4)}  ${r.note}`;
    return line(branchPrefix(r) + body);
  });
  return [top, header, ...rows, bottom];
}

export function collapsedLine(vm: DashboardVM): string {
  return ` ◈ Pipelines · ●${vm.active} running · ○${vm.waiting} waiting · ${vm.tokens} tok`;
}
