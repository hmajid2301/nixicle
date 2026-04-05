# Den Migration — Handover Plan

> **Purpose:** Instructions for an AI agent to implement the migration described
> in `docs/den-migration.md`. Each phase has exact files to read, changes to
> make, commands to run, and expected outputs to verify nothing broke.

---

## Migration Overview

```
Phase 1          Phase 2          Phase 3          Phase 4          Phase 5          Phase 6
Declare hosts    Thin flake.nix   User aspects     Role aspects     Service aspects  flake-file
& schemas        & outputs        & homes          & programs       (framebox)       (inputs)
    │                │                │                │                │                │
    ▼                ▼                ▼                ▼                ▼                ▼
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│ den.nix │    │flake.nix│    │ users/  │    │aspects/ │    │aspects/ │    │flake-   │
│ expanded│    │rewritten│    │ homes/  │    │ roles/  │    │services/│    │file.nix │
│         │    │flake-   │    │ secrets/│    │ progs/  │    │ hosts/  │    │per-mod  │
│         │    │outputs  │    │ schema  │    │profiles/│    │         │    │inputs   │
└─────────┘    └─────────┘    └─────────┘    └─────────┘    └─────────┘    └─────────┘
    │                │                │                │                │                │
 RISK: Zero      RISK: Low       RISK: Low       RISK: Medium    RISK: Medium     RISK: Low
 (additive)     (plumbing)     (alongside old)  (strip mkIf)    (same as Ph4)   (no-op)

─── import-tree bridge active ─────────────────────────────┤                │
    (modules/legacy.nix keeps old modules loading)         │  bridge removed│
                                                           │  in cleanup    │
```

**Deploy order after each phase:** `vm → vps → dell → workstation → framebox → framework`

---

## Mandatory Reading Before Any Phase

Before starting ANY phase, read these files to understand the current state:

| File | Why |
|------|-----|
| `docs/den-migration.md` | The full migration plan — read Part 8 (greenfield) and Part 9 (phases) |
| `modules/den.nix` | Current Den wiring — only 5 lines right now |
| `modules/legacy.nix` | The import-tree bridge — this is the safety net |
| `flake.nix` | Current flake — 648 lines, has all inputs and `mkSystem`/`mkHome` helpers |
| `~/den/AGENTS_EXAMPLE.md` | Den's AI agent guide — consult for API shapes, batteries, context pipeline |

**Den source references** (consult on demand, do NOT guess at API shapes):

| What you need | Where to find it |
|--------------|-----------------|
| How `den.aspects` work | `~/den/docs/src/content/docs/explanation/aspects.mdx` |
| How parametric dispatch works | `~/den/docs/src/content/docs/explanation/parametric.mdx` |
| How the context pipeline works | `~/den/docs/src/content/docs/explanation/context-pipeline.mdx` |
| Battery implementations | `~/den/modules/aspects/provides/` |
| CI test examples (most authoritative) | `~/den/templates/ci/modules/features/` |
| Schema options | `~/den/docs/src/content/docs/reference/schema.mdx` |
| Migration guide | `~/den/docs/src/content/docs/guides/migrate.mdx` |
| From-flake guide | `~/den/docs/src/content/docs/guides/from-flake-to-den.mdx` |
| Angle bracket syntax | `~/den/docs/src/content/docs/guides/angle-brackets.mdx` |
| Custom classes / forwarding | `~/den/docs/src/content/docs/guides/custom-classes.mdx` |
| Mutual providers | `~/den/docs/src/content/docs/guides/mutual.mdx` |

---

## Current Outputs (Must All Still Work After Every Phase)

These are the exact flake outputs that exist today. After every phase, every
single one of these must still evaluate successfully.

**NixOS Configurations:**
```
nixosConfigurations.framework
nixosConfigurations.framebox
nixosConfigurations.workstation
nixosConfigurations.vm
nixosConfigurations.vps
```

**Home Configurations:**
```
homeConfigurations."haseeb@framework"
homeConfigurations."haseeb@framebox"
homeConfigurations."haseeb@workstation"
homeConfigurations."haseeb@vm"
homeConfigurations."haseebmajid@dell"
```

---

## Validation Commands (Run After EVERY Change)

### Quick smoke test (run first, catches 90% of issues)

```bash
nix flake check 2>&1 | tail -20
```

Expected: no errors. Warnings about missing `meta` are fine.

### Full build test per host (run before considering a phase done)

```bash
# NixOS hosts — each must produce a valid system closure
nix build .#nixosConfigurations.framework.config.system.build.toplevel --dry-run
nix build .#nixosConfigurations.framebox.config.system.build.toplevel --dry-run
nix build .#nixosConfigurations.workstation.config.system.build.toplevel --dry-run
nix build .#nixosConfigurations.vm.config.system.build.toplevel --dry-run
nix build .#nixosConfigurations.vps.config.system.build.toplevel --dry-run

# Home-manager homes — each must produce a valid HM generation
nix build .#homeConfigurations."haseeb@framework".activationPackage --dry-run
nix build .#homeConfigurations."haseeb@framebox".activationPackage --dry-run
nix build .#homeConfigurations."haseeb@workstation".activationPackage --dry-run
nix build .#homeConfigurations."haseeb@vm".activationPackage --dry-run
nix build .#homeConfigurations."haseebmajid@dell".activationPackage --dry-run
```

Expected: all exit 0. `--dry-run` checks evaluation without downloading
everything. If evaluation fails, the build is broken.

### Quick single-host test (use during development)

```bash
# Pick the simplest host to iterate fast
nix build .#nixosConfigurations.vm.config.system.build.toplevel --dry-run
```

### VM test (before deploying to real hardware)

```bash
nixos-rebuild build-vm --flake .#vm
./result/bin/run-*-vm
```

---

## Phase 1 — Declare All Hosts, Schemas, and Shared Defaults

### What to read first

```
modules/den.nix              ← you are expanding this file
modules/legacy.nix           ← verify this still exists unchanged after your changes
flake.nix                    ← do NOT modify this file in Phase 1
~/den/AGENTS_EXAMPLE.md §4   ← how to declare hosts
~/den/AGENTS_EXAMPLE.md §6   ← how schemas work
~/den/AGENTS_EXAMPLE.md §7   ← how den.ctx works
~/den/AGENTS_EXAMPLE.md §8   ← batteries (define-user, hostname, mutual-provider)
~/den/AGENTS_EXAMPLE.md §10  ← mutual providers
```

### What to change

**Only `modules/den.nix`.** Nothing else. The import-tree bridge in `legacy.nix`
keeps all existing modules working.

The expanded `den.nix` must contain:
1. `_module.args.__findFile = den.lib.__findFile` — enables angle brackets
2. `imports = [ inputs.den.flakeModule ]`
3. `den.ctx.user.includes = [den._.mutual-provider]` — enables `provides.to-users`
4. `den.default` with:
   - `includes` list with `<den/define-user>` and `<den/hostname>`
   - `nixos` block importing shared frameworks (disko, sops-nix, niri, stylix, nixos-facter)
   - `homeManager.home.stateVersion`
5. `den.schema.user` with default classes
6. `den.schema.host` with `isLaptop` and `primaryDisplay` options
7. All 5 NixOS hosts declared with `users.*`
8. The standalone dell home declared

See `docs/den-migration.md` Phase 1 for the exact code.

### What NOT to change

- `flake.nix` — untouched in Phase 1
- `modules/legacy.nix` — untouched
- `hosts/` directory — untouched
- `modules/nixos/` — untouched
- `modules/home/` — untouched

### How to verify it worked

```bash
# 1. Check den.nix evaluates
nix flake check

# 2. Verify all existing outputs still build
nix build .#nixosConfigurations.vm.config.system.build.toplevel --dry-run
nix build .#nixosConfigurations.framework.config.system.build.toplevel --dry-run
nix build .#nixosConfigurations.framebox.config.system.build.toplevel --dry-run
nix build .#nixosConfigurations.workstation.config.system.build.toplevel --dry-run
nix build .#nixosConfigurations.vps.config.system.build.toplevel --dry-run
nix build .#homeConfigurations."haseebmajid@dell".activationPackage --dry-run

# 3. Verify den host declarations are accessible
nix eval .#nixosConfigurations.framework.config.networking.hostName
# Expected: "framework"
```

### What success looks like

- All builds pass with zero changes to any other file
- `nix eval .#nixosConfigurations.framework.config.networking.hostName` returns `"framework"`
- `modules/legacy.nix` is identical to before (not modified)

### What failure looks like and how to fix it

| Symptom | Cause | Fix |
|---------|-------|-----|
| `error: attribute 'flakeModule' not found` | `inputs.den` not in flake.nix | den is already in flake.nix — check spelling |
| `error: cannot find '__findFile'` | Missing `_module.args.__findFile` | Add it to den.nix |
| `infinite recursion` | Circular includes | Check that `den.default.includes` doesn't reference aspects that include `den.default` |
| `attribute 'mutual-provider' not found` | Wrong battery path | Use `den._.mutual-provider` not `den.provides.mutual-provider` |
| Existing host builds fail | den.default.nixos conflicts with host config | Use `lib.mkDefault` for values that hosts may override |

---

## Phase 2 — Simplify flake.nix

### What to read first

```
flake.nix                    ← you are rewriting this
lib/default.nix              ← current mkSystem/mkHome helpers (being deleted)
docs/den-migration.md Part 9 Phase 2
~/den/AGENTS_EXAMPLE.md §16  ← flake output generation
```

### What to change

1. Create `modules/flake-outputs.nix` — move packages, devShells, deploy, checks, topology, iso from flake.nix
2. Rewrite `flake.nix` to the thin `evalModules` evaluator
3. Delete `mkSystem`, `mkHome`, `mkHomeModule` helper functions

### Critical: preserving all outputs

The new setup must produce the EXACT SAME outputs. Check:

```bash
# Before rewrite — record current output names
nix flake show --json 2>/dev/null | python3 -c "
import json,sys
d = json.load(sys.stdin)
for k in sorted(d.keys()):
    if isinstance(d[k], dict):
        print(f'{k}: {sorted(d[k].keys())}')
"
```

After rewrite, run the same command and diff. The output names must be identical.

### How to verify

```bash
# All 5 NixOS hosts
nix build .#nixosConfigurations.framework.config.system.build.toplevel --dry-run
nix build .#nixosConfigurations.framebox.config.system.build.toplevel --dry-run
nix build .#nixosConfigurations.workstation.config.system.build.toplevel --dry-run
nix build .#nixosConfigurations.vm.config.system.build.toplevel --dry-run
nix build .#nixosConfigurations.vps.config.system.build.toplevel --dry-run

# All home configurations
nix build .#homeConfigurations."haseeb@framework".activationPackage --dry-run
nix build .#homeConfigurations."haseeb@framebox".activationPackage --dry-run
nix build .#homeConfigurations."haseeb@workstation".activationPackage --dry-run
nix build .#homeConfigurations."haseeb@vm".activationPackage --dry-run
nix build .#homeConfigurations."haseebmajid@dell".activationPackage --dry-run

# Non-OS outputs still exist
nix build .#packages.x86_64-linux --dry-run 2>&1 | head -5
nix eval .#deploy --apply 'x: builtins.attrNames x' 2>/dev/null
```

### What failure looks like

| Symptom | Cause | Fix |
|---------|-------|-----|
| `homeConfigurations` missing | Den not generating HM outputs | Check `den.schema.user` has `classes = [ "homeManager" ]` |
| `nixosConfigurations` missing or different names | Host names wrong in den.nix | Match exactly: framework, framebox, workstation, vm, vps |
| `packages` missing | flake-outputs.nix not imported by import-tree | Ensure the file is in `modules/` and is a valid module |
| `deploy` missing | Deploy config not moved correctly | Check flake-outputs.nix has `flake.deploy = ...` |

---

## Phase 3 — User-Host Pair Aspects

### What to read first

```
hosts/framework/home.nix     ← current user config (being moved to aspect)
hosts/dell/home.nix           ← dell standalone HM config
docs/den-migration.md Part 9 Phase 3
~/den/AGENTS_EXAMPLE.md §3.1  ← how aspects work
~/den/AGENTS_EXAMPLE.md §5    ← configuring aspects
~/den/AGENTS_EXAMPLE.md §13   ← angle bracket syntax
```

### What to change

1. Create `modules/users/schema.nix` — typed identity (email, signingKey, authorizedKeys)
2. Create `modules/users/haseeb/base.nix` — shared user config
3. Create `modules/users/haseeb/framework.nix` — laptop-specific
4. Create `modules/users/haseeb/framebox.nix`
5. Create `modules/users/haseeb/workstation.nix`
6. Create `modules/users/haseeb/vm.nix`
7. Create `modules/users/nixos/vps.nix`
8. Create `modules/homes/haseebmajid@dell/module.nix` — inline home + aspect
9. Create `modules/secrets/lib.nix` — tag-based user secret registry
10. Wire `aspect` keys in `den.hosts` in `modules/den.nix`
11. Delete old `hosts/*/home.nix` files ONLY after new aspects are verified

### File Mapping (old → new)

```
OLD FILE                              NEW FILE
──────────────────────────────────    ──────────────────────────────────────
hosts/framework/home.nix          ──► modules/users/haseeb/framework.nix
hosts/framebox/home.nix           ──► modules/users/haseeb/framebox.nix
hosts/workstation/home.nix        ──► modules/users/haseeb/workstation.nix
hosts/vm/home.nix                 ──► modules/users/haseeb/vm.nix
hosts/dell/home.nix               ──► modules/homes/haseebmajid@dell/module.nix
(git signing, SSH keys — scattered)──► modules/users/schema.nix
(sops secrets — per host)         ──► modules/secrets/lib.nix (user secrets only)
(no equivalent)                   ──► modules/users/haseeb/base.nix (new, shared)
```

### Migration strategy for each user-host pair

Do them one at a time:
1. Create the new aspect file
2. Build that specific host: `nix build .#nixosConfigurations.<host>.config.system.build.toplevel --dry-run`
3. Build that specific home: `nix build .#homeConfigurations."haseeb@<host>".activationPackage --dry-run`
4. Only after both pass, delete the old `hosts/<host>/home.nix`
5. Build again to confirm the deletion didn't break anything
6. Move to the next host

### How to verify

```bash
# After creating each user aspect, verify the host still builds:
nix build .#nixosConfigurations.framework.config.system.build.toplevel --dry-run
nix build .#homeConfigurations."haseeb@framework".activationPackage --dry-run

# After dell migration:
nix build .#homeConfigurations."haseebmajid@dell".activationPackage --dry-run

# After ALL user aspects are done:
nix flake check
# Run full validation suite from top of this document
```

### What to watch for

- User aspects use `{ __findFile, ... }:` not `{ den, ... }:` when using angle brackets
- The `user` class key (e.g. `user = { ... }`) forwards to `users.users.<name>` on NixOS — read `~/den/AGENTS_EXAMPLE.md §9` (user class)
- The dell standalone home uses inline `den.homes` declaration — read the Sharparam pattern in `docs/den-migration.md` Part 5
- `modules/secrets/lib.nix` is a plain Nix file (not a NixOS module) — it is `import`ed, not auto-loaded by import-tree

---

## Phase 4 — Role + Program Aspects

### What to read first

```
modules/nixos/roles/desktop/default.nix     ← NixOS side of desktop role (being replaced)
modules/home/roles/desktop/default.nix      ← HM side of desktop role (being replaced)
modules/nixos/roles/gaming/default.nix      ← gaming NixOS
modules/home/roles/gaming/default.nix       ← gaming HM
docs/den-migration.md Part 9 Phase 4
~/den/AGENTS_EXAMPLE.md §3.1  ← aspects
~/den/AGENTS_EXAMPLE.md §5.3  ← provides (sub-aspects)
```

### Per-Module Conversion Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│  FOR EACH MODULE (e.g. roles/gaming):                              │
│                                                                    │
│  ① Read both files:                                                │
│     modules/nixos/roles/gaming/default.nix  ← NixOS side           │
│     modules/home/roles/gaming/default.nix   ← HM side              │
│                                                                    │
│  ② Create colocated aspect:                                        │
│     modules/aspects/roles/gaming.nix                               │
│     ┌─────────────────────────────────┐                            │
│     │ den.aspects.gaming = {          │                            │
│     │   nixos = { ... };  ← from ①   │  NO mkEnableOption         │
│     │   homeManager = { ... }; ← ①   │  NO mkIf cfg.enable        │
│     │ };                              │  NO options.* declaration  │
│     └─────────────────────────────────┘                            │
│                                                                    │
│  ③ Update consumers:                                               │
│     - roles.gaming.enable = true;    ← DELETE this line            │
│     + includes = [ <aspects/roles/gaming> ];  ← ADD this           │
│                                                                    │
│  ④ BUILD ALL HOSTS (not just the one that uses it):                │
│     nix build .#nixosConfigurations.{framework,framebox,...} --dry  │
│     ALL must exit 0                                                │
│                                                                    │
│  ⑤ Only NOW delete old files:                                      │
│     rm -rf modules/nixos/roles/gaming/                             │
│     rm -rf modules/home/roles/gaming/                              │
│                                                                    │
│  ⑥ BUILD AGAIN after deletion (catch stale references)             │
│     ALL must exit 0                                                │
│                                                                    │
│  ⑦ git commit -m "migrate gaming role to den aspect"               │
│                                                                    │
│  ⑧ Repeat for next module                                         │
└─────────────────────────────────────────────────────────────────────┘
```

### Critical: stripping boilerplate

When converting each module, you MUST strip the enable boilerplate. This is
the transformation:

**Before (legacy module):**
```nix
{ config, lib, ... }:
with lib; let
  cfg = config.roles.desktop;
in {
  options.roles.desktop = {
    enable = mkEnableOption "desktop role";
  };
  config = mkIf cfg.enable {
    # actual config
  };
}
```

**After (Den aspect):**
```nix
{ den, ... }: {
  den.aspects.desktop = {
    nixos = { pkgs, ... }: {
      # actual NixOS config (no mkIf, no options declaration)
    };
    homeManager = { pkgs, ... }: {
      # actual HM config (was in a separate file)
    };
  };
}
```

The aspect's existence IS the enable mechanism. Including it activates it.
Do NOT keep `options.roles.*.enable` declarations.

### Migration order (do one at a time)

1. `common` — smallest, lowest risk, used everywhere
2. `desktop` — highest value, tests NixOS+HM colocation
3. `gaming` — add `nix-gaming` input, create sub-aspects (replays, gamescope, performance)
4. `performance` — tiered (base/responsive/max)
5. `development`
6. `social`, `non-nixos`, `video`, `gamedev`

### Per-module migration steps

For each role:
1. Read the NixOS module file AND the HM module file
2. Create the colocated aspect file in `modules/aspects/roles/`
3. Strip the `mkEnableOption` + `mkIf cfg.enable` boilerplate
4. Put the NixOS config under `nixos = { ... }:` and HM config under `homeManager = { ... }:`
5. Update user aspects that had `roles.<name>.enable = true` to use `includes = [ <aspects/roles/<name>> ]`
6. Build ALL hosts: every host must still evaluate
7. Only then delete the old `modules/nixos/roles/<name>/` and `modules/home/roles/<name>/` directories
8. Build again after deletion

### How to verify

```bash
# After EACH role conversion, test ALL hosts (not just the one that uses it):
nix build .#nixosConfigurations.framework.config.system.build.toplevel --dry-run
nix build .#nixosConfigurations.framebox.config.system.build.toplevel --dry-run
nix build .#nixosConfigurations.workstation.config.system.build.toplevel --dry-run
nix build .#nixosConfigurations.vm.config.system.build.toplevel --dry-run
nix build .#nixosConfigurations.vps.config.system.build.toplevel --dry-run
nix build .#homeConfigurations."haseebmajid@dell".activationPackage --dry-run
```

Test ALL hosts even if you think only one uses the role — roles can have
unexpected dependencies.

### What failure looks like

| Symptom | Cause | Fix |
|---------|-------|-----|
| `error: option 'roles.desktop.enable' does not exist` | User aspect still references `roles.desktop.enable = true` but the option was deleted | Update user aspect to use `includes = [ <aspects/roles/desktop> ]` instead |
| `error: attribute 'nixicle' not found in services` | Aspect still references `services.nixicle.*` but the custom option wrapper was deleted with the role | Replace with the actual NixOS config the wrapper was hiding |
| `infinite recursion` | Aspect includes itself | Check `includes` list for circular references |
| Different system closure hash | Config not equivalent | Diff the old and new NixOS options: `nix eval .#nixosConfigurations.framework.config.services` |

---

## Phase 5 — Service Aspects (framebox)

### What to read first

```
hosts/framebox/default.nix   ← current framebox host config (services being extracted)
modules/nixos/services/      ← current service modules
docs/den-migration.md Part 9 Phase 5
```

### What to change

Create one aspect per service in `modules/aspects/services/`. Each service
aspect is a Simple Aspect — just a `nixos` key with the service config.

Then create `modules/aspects/hosts/framebox.nix` that includes all service
aspects plus hardware imports.

### Hardcoded values — do NOT guess, use these exact strings

When writing service aspects, use these literal values (do not invent new ones):

| Value | String |
|-------|--------|
| Personal domain | `haseebmajid.dev` |
| Homelab subdomain | `homelab.haseebmajid.dev` |
| Cloudflare tunnel ID | `ecef5dbb-834e-43ed-84c6-355a2ac53e59` |
| Uptime Kuma tunnel ID | `0e845de6-544a-47f2-a1d5-c76be02ce153` |

These are currently hardcoded in each aspect file. A future cleanup will
extract them into `modules/aspects/services/_config.nix`. Until then, use
the literal strings above — do not create `den.schema.host` options for them.

### Per-service migration

Same pattern as Phase 4: create aspect → verify build → delete old module.

### How to verify

```bash
# framebox is the critical host — test it after every service aspect:
nix build .#nixosConfigurations.framebox.config.system.build.toplevel --dry-run

# After all services migrated, test everything:
nix flake check
# Full validation suite
```

---

## Phase 6 — flake-file

### What to read first

```
flake.nix                    ← being auto-generated after this phase
docs/den-migration.md Part 9 Phase 6
~/den/AGENTS_EXAMPLE.md      ← no specific section, but understand imports
```

### What to change

1. Add `flake-file` to flake inputs
2. Move input declarations from `flake.nix` into the module files that use them using `flake-file.inputs.<name>.url = "..."` syntax
3. Run `nix run .#write-flake` to regenerate `flake.nix`

### How to verify

```bash
# After regeneration:
nix flake check
nix build .#nixosConfigurations.framework.config.system.build.toplevel --dry-run
nix build .#nixosConfigurations.framebox.config.system.build.toplevel --dry-run
nix build .#homeConfigurations."haseebmajid@dell".activationPackage --dry-run

# Verify flake.nix is auto-generated (should have the DO-NOT-EDIT comment)
head -1 flake.nix
# Expected: # DO-NOT-EDIT. This file was auto-generated using github:vic/flake-file.
```

---

## Final Cleanup

### What to delete

Only delete after ALL phases are complete and verified:

```bash
# These directories should be empty of active code by now:
rm -rf modules/nixos/
rm -rf modules/home/
rm -rf modules/shared/
rm modules/legacy.nix

# Verify nothing broke:
nix flake check
nix build .#nixosConfigurations.framework.config.system.build.toplevel --dry-run
nix build .#nixosConfigurations.framebox.config.system.build.toplevel --dry-run
nix build .#nixosConfigurations.workstation.config.system.build.toplevel --dry-run
nix build .#nixosConfigurations.vm.config.system.build.toplevel --dry-run
nix build .#nixosConfigurations.vps.config.system.build.toplevel --dry-run
nix build .#homeConfigurations."haseeb@framework".activationPackage --dry-run
nix build .#homeConfigurations."haseeb@framebox".activationPackage --dry-run
nix build .#homeConfigurations."haseeb@workstation".activationPackage --dry-run
nix build .#homeConfigurations."haseeb@vm".activationPackage --dry-run
nix build .#homeConfigurations."haseebmajid@dell".activationPackage --dry-run
```

If ANY of those fail, do NOT delete — something is still depending on the
old modules.

---

## Rules for the Implementing Agent

1. **Never modify more than one phase at a time.** Complete and verify each phase fully before starting the next.

2. **Never delete old files until the new replacement is verified.** The import-tree bridge means both can coexist.

3. **Always run the full validation suite before claiming a phase is done.** All 5 NixOS hosts + all 5 home configurations must evaluate.

4. **Consult Den source files before guessing at API shapes.** Read `~/den/AGENTS_EXAMPLE.md` for the authoritative reference. The CI tests at `~/den/templates/ci/modules/features/` are the most reliable working examples.

5. **When converting a module to an aspect, strip ALL boilerplate.** No `mkEnableOption`, no `mkIf cfg.enable`, no `options.*` declarations. The aspect's existence IS the enable mechanism.

6. **When in doubt, read the community configs.** Moortu's config is at `/tmp/moortu-dotfiles` (may need re-cloning: `git clone --depth 1 https://codeberg.org/Moortu/dotfiles.git /tmp/moortu-dotfiles`). Sharparam's is at `https://github.com/Sharparam/nix-config`. quasigod's is at `https://tangled.org/quasigod.xyz/nixconfig`.

7. **Use angle-bracket syntax in all new aspect files.** `{ __findFile, ... }:` in the function args, then `<den/primary-user>`, `<aspects/roles/desktop>`, etc. in includes.

8. **The host deployment order for testing is: vm → vps → dell → workstation → framebox → framework.** Least critical first. Never deploy to framework (daily driver) without testing on vm first.

9. **If a build fails after a change, revert the change immediately.** `git stash` or `git checkout -- <file>`. Do not try to fix forward with more changes on top of a broken state.

10. **Commit after each successfully verified sub-step**, not after an entire phase. Small commits are easier to revert.
