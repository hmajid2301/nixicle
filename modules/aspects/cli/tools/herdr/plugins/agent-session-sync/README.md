# agent-session-sync

Mirrors AI coding-agent transcripts from a remote machine to this one, so losing
the remote box does not lose the conversations that were running on it.

Supports Claude Code (`~/.claude/projects`) and pi (`~/.pi/agent/sessions`).
Both store one append-only `.jsonl` per conversation, in a directory named after
the project's working directory.

## Why it is shaped this way

**Pull-only, into a quarantine mirror.** Sync writes only to
`~/.local/state/agent-session-sync`, never into the live `~/.claude` or `~/.pi`
stores the agents read. A background daemon therefore cannot touch a session you
are working in. `promote` is the only command that writes to the live store.

**Conflicts are resolved by content, not timestamps.** `rsync -a` stamps the
mirror with the *remote* machine's clock, so comparing mtimes across two boxes
is only valid when their clocks agree — a fast remote clock would clobber newer
local work, a slow one would refuse to rescue newer remote work. Transcripts are
append-only, so whichever file strictly extends the other is the later version.
If neither extends the other they have forked, and the local copy is backed up
before the mirror overwrites it.

**The mirror never shrinks.** `--append-verify` means a remote-side truncation
(disk corruption, an errant `sed -i`, an agent bug) cannot propagate and destroy
the last surviving copy.

**Only whole records are installed.** A transcript captured while the agent was
mid-write ends partway through a JSON object — the normal state for a live
session. Promote truncates to the last newline rather than installing a torn
final line.

## Usage

    agent-session-sync pull <host>              one sync pass
    agent-session-sync status                   what is mirrored, and how stale
    agent-session-sync list <host>              mirrored sessions ("+" = subagent)
    agent-session-sync promote <host> <id>      install one into the live store
    agent-session-sync daemon <host>            loop on an interval
    agent-session-sync -v pull <host>           print the rsync argv

`<host>` is an SSH host alias, so `~/.ssh/config` applies as usual.

### Different project paths on each machine

Home directories are remapped automatically. When a repo lives at a genuinely
different path, add mappings to `~/.config/agent-session-sync/paths`:

    # remote                        local
    /home/other/work                ~/projects
    /home/other/srv/nala-backend    /home/me/projects/nala-backend

Longest remote path wins. `list` shows the resolved local path and flags
`[unmapped]` or `[no local dir]`; `promote` refuses an unmapped path rather than
filing the transcript where the agent will never look for it.

### Environment

| Variable | Default |
|---|---|
| `AGENT_SYNC_MIRROR` | `~/.local/state/agent-session-sync` |
| `AGENT_SYNC_MAP` | `~/.config/agent-session-sync/paths` |
| `AGENT_SYNC_INTERVAL` | `15m` |
| `AGENT_SYNC_STALE_AFTER` | `1h` |

## Enabling the daemon

Add SSH host aliases to `syncHosts` in `../../default.nix`; one supervised
systemd user service is generated per host.

## Limitations

- Resuming a promoted session across machines with mismatched agent versions is
  untested. Try it on a session you do not care about first.
- `~/.claude/file-history/` is not synced, so promoted Claude sessions resume the
  conversation but lose checkpoint/rewind backing files.
- Nothing prunes the mirror; it grows without bound.
- `.bak.<timestamp>` files from conflicting promotes accumulate in the live
  store and are never cleaned up.

`reference-implementation.bash` is the original shell version, kept for
reference. It has known defects (see git history) and should not be used.
