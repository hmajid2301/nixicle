# Herdr VPS operations

## Topology

```text
Desktop Herdr                     TermRover
saved SSH machine                 SSH or Mosh
         \                         /
             Tailscale tailnet
                     |
             VPS user: herdr
                     |
        Herdr workspaces and agents
```

Phone and desktop disconnects do not stop Herdr-owned panes.
A lingering systemd user service starts the Herdr server at boot. Home Manager does not restart it automatically when its unit changes, which protects running agents during ordinary activation.
A VPS reboot stops all processes. Herdr restores layout and can resume only supported agents with valid native session references.
TermRover must not receive a Tailscale API key.
Collie, Tailscale Serve, and Tailscale Funnel are not part of this deployment.

## Security model

- Use only the dedicated `herdr` account for mobile agent access.
- `herdr` has no password, administrator SSH keys, `wheel`, or `networkmanager` membership.
- Tailscale SSH authenticates approved tailnet identities.
- Public firewall exposes no UDP ports. Mosh UDP `60000-61000` is reachable only through trusted `tailscale0` and permitted tailnet policy.
- Keep Herdr pane history disabled because pane output can contain secrets.
- Authenticate each agent interactively as `herdr`. Never copy an administrator home or broad credential directory.

## Tailscale policy

Apply tailnet policy before deployment. Preserve existing administrator recovery access.

Example HuJSON fragment:

```jsonc
{
  "tagOwners": {
    "tag:herdr-vps": ["autogroup:admin"],
  },
  "grants": [
    {
      "src": ["you@example.com"],
      "dst": ["tag:herdr-vps"],
      "ip": ["tcp:22", "udp:60000-61000"],
    },
  ],
  "ssh": [
    {
      "action": "check",
      "src": ["you@example.com"],
      "dst": ["tag:herdr-vps"],
      "users": ["herdr"],
    },
  ],
}
```

Replace `you@example.com` with approved phone and desktop identity. Assign `tag:herdr-vps` to only VPS. Merge fragment into existing policy; do not replace unrelated rules. Validate syntax and policy tests in Tailscale admin before saving. Identity names and existing policy live outside this repository.

## Evaluate and deploy

Evaluate locally:

```bash
nix eval .#nixosConfigurations.vps.config.system.build.toplevel.drvPath
```

Review changes before deployment:

```bash
git log --oneline main..HEAD
git diff main...HEAD --stat
git diff main...HEAD
```

Deploy only after explicit approval:

```bash
deploy .#vps
```

Keep current administrative SSH session open during first activation.

## Verify VPS

```bash
ssh herdr@vps
herdr --version
herdr integration status
herdr
```

Expected Herdr version: `0.9.0`.

Detach with configured Herdr prefix (`Ctrl-A`), then `q`. Reconnect with `herdr` and confirm same pane process remains.

From administrator session:

```bash
systemctl status tailscaled
systemctl status restic-backups-herdr.timer
sudo -u herdr XDG_RUNTIME_DIR=/run/user/$(id -u herdr) systemctl --user status herdr-server
sudo -u herdr test -w /home/herdr/projects
sudo -u herdr id
```

Confirm `id` does not show `wheel` or `networkmanager`.

## Configure agent integrations

Run as `herdr`:

```bash
herdr integration install pi
herdr integration install claude
herdr integration status
```

Authenticate only required agent CLIs. Store repositories in `/home/herdr/projects`.

## Configure TermRover

1. Install official Tailscale app and join tailnet.
2. Install TermRover v1.2 or newer.
3. Disable **Settings > Diagnostics**.
4. Enable biometric lock.
5. Add VPS manually with its MagicDNS name. Do not use TermRover tailnet import or provide a Tailscale API key.
6. Set user to `herdr` and use Tailscale SSH keyless login.
7. Test SSH first.
8. Switch live connection to Mosh after SSH works.
9. Select Herdr as host multiplexer, then open Agents Fleet.

If keyless login fails, verify official Tailscale app connectivity and plain Tailscale SSH first. Do not work around failure with administrator credentials. A dedicated, revocable phone SSH key is fallback only.

## Configure desktop Herdr

Verify ordinary SSH first:

```bash
ssh herdr@vps
```

Add saved machine:

```bash
herdr machine add herdr@vps --label VPS
herdr machine list
herdr
```

VPS workspaces and agents appear beside local ones. Removing saved machine disconnects client only; VPS agents continue running.

## Resilience tests

### Disconnect test

1. Start harmless agent task in Herdr.
2. Record pane process ID.
3. Detach desktop and TermRover.
4. Reconnect from each client.
5. Confirm same process ID and output remain.

### Network test

1. Confirm SSH and Mosh work from approved device inside tailnet.
2. Disable Tailscale on test device.
3. Confirm public SSH does not authenticate as `herdr`.
4. Confirm public interface rejects Mosh UDP `60000-61000`.
5. Re-enable Tailscale and confirm recovery.

### Optional reboot test

Run only after every active repository is committed or checkpointed. Reboot VPS, reconnect, and verify layout plus supported native agent resume. Arbitrary shells, development servers, tests, and unsupported agents do not survive reboot.

## Backup and recovery

Restic backs up `/home/herdr` daily. It excludes caches, trash, `.direnv`, `node_modules`, and Rust `target` directories.

Check timer and latest snapshot:

```bash
systemctl list-timers restic-backups-herdr.timer
sudo systemctl start restic-backups-herdr.service
journalctl -u restic-backups-herdr.service --since today
```

Use existing repository Restic credentials and recovery procedure. Test restoration into a temporary directory before replacing live state.
