---
name: weekly-summary
description: Fill in this week's notes from every AI coding session (Claude Code and pi) since Monday, splitting work and personal. Use for /weekly-summary, "what did I do this week", "update my weekly notes", or "write the handover for next week".
---

# Weekly summary

Reads the week's agent sessions and fills in what was done. Works the same from any agent.

## 1. List the sessions

```bash
<this skill's dir>/scripts/list-sessions.sh [YYYY-MM-DD] [tail-chars]
```

- Defaults: Monday of this week, and the last 600 characters of each session's final reply.
- It covers Claude Code (`~/.claude/projects`) and pi (`$PI_CODING_AGENT_SESSION_DIR`, defaulting to `~/.local/state/pi/sessions`), and skips subagent transcripts and tiny sessions.
- Each block has the time, the tool, the cwd, the file, the title, the opening prompt and the end of the last reply. The last reply is usually the session's own summary, so it's normally enough.
- If a session is unclear, read more of that file only, with `jq`. Never read whole transcripts into context.
  - Claude Code: the text is in `.message.content[] | select(.type=="text")` on `user`/`assistant` lines.
  - pi: the same, on `type=="message"` lines with `.message.role` set.
- Many sessions repeat each other (`/clear` + handoff chains). Group them by topic, not by session.

## 2. Split work and personal

- **Work:** cwd under `~/projects/nala-*`, `~/projects/Nala-Remit`, `~/projects/go-library`, `~/projects/terraform-aws`, `~/worktrees/<nala repo>`, or anything else clearly Nala.
  - Goes in `~/projects/notes/projects/nala/weekly/<monday>.md`.
- **Personal:** everything else (blog, nixicle, lettucego, homelab and so on).
  - Goes in `~/projects/notes/journals/weekly/<monday>.md`.
- If a week's note doesn't exist, create it from the previous week's structure (or `~/projects/notes/templates/`), with the same frontmatter and headings.

## 3. Check before writing

- Read the target note first, and only add what's missing. Other sessions may have written to it this week.
- Check the state of PRs you mention (`gh pr view <n> -R <owner/repo> --json state,isDraft,mergedAt`). The end of a session is often out of date, because PRs merge later.
- Tick TODOs and Intentions only when the work is actually done (merged, deployed, or confirmed). Don't tick something that's just "in review".

## 4. Write

- Match the note's existing style and sections: in the Nala note that's `## PRs` / `### TODO`, `## Projects`, `## What we did` with `### <Day> <date>`; in the personal journal it's Highlights and Intentions.
- Under each day, use rough bullets with enough to jog memory, not loads of detail: what it was, the outcome, a link to the PR or ticket, and what's left.
- Name incidents (`INC-…`) with a one-line cause and impact.
- Put open threads in a `## Handover for next week` section as checkboxes, with the blocking step first.
- No customer names, emails, IBANs or other personal data. IDs and internal links are fine.
- Don't commit the notes repo unless asked.

## 5. Report back

- Say which notes you changed, and what you added per day, briefly.
- Say which items you inferred only from a session title or a thin summary, so the user can check them.
