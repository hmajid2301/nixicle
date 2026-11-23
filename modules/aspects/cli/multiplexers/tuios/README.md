# Command resurrection

The TUIOS aspect packages the same pinned `herdr-resurrect` source as Herdr.
It captures ordinary commands every 30 seconds and restores them on daemon
startup. TUIOS itself resumes supported agent conversations.

After activating the Nix configuration, approve the plugin from a terminal
outside TUIOS (with the daemon running):

```sh
tuios plugins approve ntindle.herdr-resurrect --grant admin
tuios plugins run ntindle.herdr-resurrect save
tuios plugins log ntindle.herdr-resurrect
```

If the running daemon has not discovered the new configuration, run
`tuios config apply` from that outside terminal before approval. No daemon
restart is required just to enable the plugin. A changed plugin may require
approval again. Do not restart a daemon with active work just to test restore.

Keys after `Ctrl+A`:

- `Ctrl+S`: save now
- `Ctrl+R`: restore idle panes
- `Ctrl+P`: preview restore

The wildcard allowlist matches the existing Herdr configuration: any captured
ordinary command can run again, including commands with side effects. The plugin
has admin permission; agent panes retain their existing restricted grants.
Snapshots contain command arguments and may contain secrets. TUIOS stores them
under its private plugin state directory, separate from Herdr's state.

This restarts commands, not process memory or unsaved editor buffers. Commands
started or stopped within the last 30 seconds may not be reflected in a snapshot.
The npm patch recovers only simple `npm run <script>` process titles; extra
arguments discarded by npm cannot be recovered reliably. Required programs must
still be available in restored shells.

## Isolated regression test

Build the plugin without activating anything:

```sh
plugin=$(nix build --impure --no-link --print-out-paths --expr '
  let
    f = builtins.getFlake (toString ./.);
    pkgs = import f.inputs.nixpkgs { system = "x86_64-linux"; };
  in import ./modules/aspects/cli/multiplexers/tuios/_resurrect.nix {
    inherit pkgs;
    inherit (pkgs) lib;
    src = f.inputs.plugins-herdr-resurrect;
  }')
bash modules/aspects/cli/multiplexers/tuios/_resurrect-test.sh "$plugin"
TUIOS_TEST_SHELL=$(command -v fish) bash modules/aspects/cli/multiplexers/tuios/_resurrect-test.sh "$plugin"
```

The test needs `tuios`, `bash`, `jq`, `node`, `npm`, `nvim` and `htop` on PATH.
It creates temporary HOME and XDG directories, and stops only its own daemon.
It leaves its temporary state for inspection.
