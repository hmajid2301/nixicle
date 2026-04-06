# Migrating nixicle to the Dendritic Pattern (Den)

> **Scope:** Full Den-native migration. All outputs move into `modules/`. The
> `flake.nix` becomes a thin entry point. This document is both an explanation
> of *why* and a concrete *how*, using your actual config as the reference.
>
> **Repo access note:** Codeberg blocked web fetching but git clone worked for
> Moortu/dotfiles. Adda/nixos-config could not be reviewed. Sharparam/nix-config,
> quasigod/nixconfig, and Moortu/dotfiles were fully reviewed.

---

## Table of Contents

**Understanding the Pattern:**
- [Part 1 — What is the Dendritic Pattern?](#part-1--what-is-the-dendritic-pattern)
- [Part 2 — Advantages and Drawbacks](#part-2--advantages-and-drawbacks-honest-assessment)
- [Part 3 — How Den Works](#part-3--how-den-works-quick-reference)
- [Part 4 — Aspect Design Patterns](#part-4--aspect-design-patterns)
- [Part 5 — Community Patterns](#part-5--community-patterns-observed-in-the-wild)
- [Part 6 — File Organisation Principles](#part-6--file-organisation-principles)

**Analysis and Design:**
- [Part 7 — Current State of nixicle](#part-7--current-state-of-nixicle)
- [Part 8 — Greenfield Architecture](#part-8--greenfield-architecture-if-starting-from-scratch)

**Migration:**
- [Part 9 — Migration Plan (Phases 1-6)](#part-9--migration-plan)
- [Part 10 — Final Directory Structure](#part-10--final-directory-structure)
- [Part 11 — Migration Checklist](#part-11--migration-checklist)

**Reference:**
- [Part 12 — Key Den Patterns to Know](#part-12--key-den-patterns-to-know)
- [Part 13 — Quick Reference: Before / After](#part-13--quick-reference-before--after)
- [Footnotes](#footnotes)

---

## Part 1 — What is the Dendritic Pattern?

### The Design Pattern, Not a Library

The Dendritic Pattern is a **software design pattern** — not a library, not a
framework, not a template repository. It defines a *way of doing* things. Two
simple principles underpin it:

1. **Top-level modules:** Everything is constructed using a single type of
   module (the top-level module), which then defines lower-level modules.
2. **Features:** Code is bundled into *features*, which serve as the building
   blocks for the entire config.

Den[^1] is one implementation of this pattern for Nix. The pattern itself is
generic — it can be applied with plain `lib.evalModules`, flake-parts, or no
flakes at all.

### What is a Feature?

In the Dendritic Pattern a **feature** provides essential content that can be
used in *multiple configuration contexts* — NixOS, Darwin, Home-Manager, etc.

The shift is from *top-down* (host → services/apps/users) to *bottom-up*
(feature → used on hosts):

**Traditional (top-down):**
```
myHost (NixOS)
  ├── has system settings → services
  ├── has system settings → app installation
  └── has user settings  → home-manager
```

**Dendritic (bottom-up):**
```
featureX
  ├── NixOS    settings
  ├── Darwin   settings
  └── HM       settings
       ↓
  used on myHost1, myHost2, myHost3
  used as element of featureY
```

All feature-related settings are consolidated but still organised into separate
blocks per context. This makes code changes, bug fixes, and side-effect
management dramatically simpler.

Typical feature abstractions in a config like nixicle:

| Granularity | Examples from nixicle |
|-------------|----------------------|
| Specific service or app | `immich`, `authentik`, `traefik`, `tailscale` |
| App / service category | `homelab-services`, `desktop`, `gaming` |
| Usage area | `desktop`, `workstation` |
| Specific user or host | `haseeb-framework`, `haseebmajid-dell` |
| Nix tooling | `impermanence`, `lanzaboote`, `disko` |

### nixicle Today vs Den: Architecture Comparison

```
TODAY (host-centric, split by platform):

  flake.nix ──► inputs, mkSystem, mkHome, outputs
      │
      ├── hosts/framework/
      │     ├── default.nix  ── NixOS config
      │     └── home.nix     ── HM config          ← SAME FEATURE, DIFFERENT FILES
      │
      ├── modules/nixos/
      │     ├── roles/desktop/default.nix ── NixOS  ← SPLIT
      │     ├── roles/gaming/default.nix            │
      │     └── services/immich/default.nix         │
      │                                             │
      ├── modules/home/                             │
      │     ├── roles/desktop/default.nix ── HM    ← SPLIT (same role, different tree)
      │     ├── roles/gaming/default.nix            │
      │     └── cli/shells/fish/default.nix         │
      │                                             │
      └── 177 files with mkEnableOption + mkIf boilerplate


AFTER (feature-centric, colocated):

  flake.nix ──► 10 lines: evalModules(import-tree ./modules)
      │
      └── modules/
            ├── den.nix ──► hosts, schemas, defaults
            │
            ├── aspects/
            │     ├── roles/desktop.nix ──► nixos + HM in ONE file
            │     ├── roles/gaming.nix  ──► nixos + HM + sub-aspects
            │     ├── services/immich.nix ──► self-contained
            │     ├── programs/cli.nix ──► fish + atuin + starship
            │     └── hosts/framework.nix ──► includes list
            │
            ├── users/haseeb/base.nix ──► reads from typed schema
            └── homes/haseebmajid@dell/ ──► inline declaration

  Zero mkEnableOption. Zero mkIf. ~49 files total.
```

### The Cognitive Load Problem in nixicle

Configuring a single cross-cutting feature in nixicle today requires touching
multiple files that live far apart. Take impermanence — already enabled on
`framework`, `framebox`, and `workstation`:

| What | Where |
|------|-------|
| Input declaration | `flake.nix` |
| NixOS module import + options | `hosts/<host>/default.nix` |
| Home-Manager persistence | `hosts/<host>/home.nix` |

Three files, two module trees, one flake input — for one feature. This is the
standard host-centric model: **you start from a host and push config downward.**

With the Dendritic Pattern the same feature becomes one file. And with
`flake-file`[^12], even the *input declaration* lives in the same file:

```nix
# modules/aspects/impermanence.nix
{ den, inputs, ... }: {
  # The flake input — declared right here, not in flake.nix
  flake-file.inputs.impermanence.url = "github:nix-community/impermanence";

  den.aspects.impermanence = {
    nixos = {
      imports = with inputs; [ impermanence.nixosModules.default ];

      environment.persistence."/persistence".allowTrash = true;
    };

    homeManager.home.persistence."/persistence".hideMounts = false;
  };
}
```

One file. One concept. Input, NixOS config, and HM config all colocated. Adding
it to a host is one line:
`den.aspects.framework.includes = [ den.aspects.impermanence ];`.

This is **total colocation** — the input that provides the feature, the NixOS
configuration, and the Home-Manager configuration all live next to each other in
a single file. No jumping between `flake.nix`, `hosts/<host>/default.nix`, and
`hosts/<host>/home.nix` to configure one thing.

> **Without `flake-file`:** the input still lives in `flake.nix`, but the
> NixOS + HM config are still colocated in one aspect file. You go from 3 files
> to 2. With `flake-file`, you go from 3 files to 1.

### Why nixicle Benefits Specifically

Your repo has a well-structured roles system (`roles.desktop`, `roles.gaming`,
`roles.development`, etc.) but it is split: NixOS options live in
`modules/nixos/roles/` and HM options live in `modules/home/roles/`. Two halves
of the same idea, separated by tree structure.

In Den[^1], `roles.desktop` becomes `den.aspects.desktop`:

```nix
den.aspects.desktop = {
  nixos        = { ... };   # hardware.bluetooth, boot.binfmt, services.vpn ...
  homeManager  = { ... };   # session vars, tray target, packages ...
};
```

One file. Both sides. Zero `mkIf` boilerplate. No `options.roles.desktop.enable`
declaration needed anywhere.

Additional concrete benefits for nixicle:

- **framebox** has ~20 services. Each service can be a self-contained aspect
  (`den.aspects.immich`, `den.aspects.authentik`, etc.) reusable on a second
  homelab machine with one line.
- **dell** (Fedora/non-NixOS): the `nixos` class in any aspect is silently
  skipped for the standalone home — no `mkIf pkgs.stdenv.isLinux` required.
- **Parametric dispatch** means a function `{ host, user }: ...` is
  automatically skipped in host-only contexts. No conditionals anywhere.
- **`flake.nix` becomes ~10 lines.** All logic moves into `modules/`. The flake
  file is reduced to its essential purpose: declaring inputs and wiring them.

---

## Part 2 — Advantages and Drawbacks (Honest Assessment)

### Advantages

From Doc-Steve's comprehensive FAQ[^2], the benefits when you adopt the Dendritic
Pattern consistently are:

| Benefit | What it means for nixicle |
|---------|--------------------------|
| **Multi-platform support** | `nixos` + `homeManager` blocks for one feature coexist in one file. Adding Darwin later is adding one key to each aspect. |
| **Simplified structural design** | Every file is a feature module. "Where does this config go?" has a clear answer: in the aspect it belongs to. |
| **Reduced dependencies** | Adding/removing a feature is adding/removing one line from an `includes` list. |
| **Less glue code** | No `mkIf cfg.enable` boilerplate. Importing an aspect *is* enabling it. |
| **Enhanced reusability** | framebox's `immich` aspect can be used on a second server with one line. |
| **Improved bug fixing** | The impermanence bug is in `modules/aspects/impermanence.nix` — one place, not three. |
| **Freedom of file reorganisation** | Renaming or moving files does not break anything. No relative `../..` chains. |
| **Decluttered `flake.nix`** | `flake.nix` declares inputs only. All outputs live in modules. |

### Drawbacks (Real, Not Dismissed)

The pattern is not without cost:

- **Ecosystem dependency:** Den[^1]-style aspects only work in the Den ecosystem.
  Code written for plain NixOS modules needs wrapping to be included.
- **Learning curve:** The parametric dispatch model (`{ host, user }: ...`) is
  new. The first week will feel strange.
- **Migration cost:** You have an existing working config. Migration takes time
  and carries risk of breakage if not done incrementally.

The import-tree bridge (`den.provides.import-tree`)[^3] exists specifically to
manage this — your existing modules continue to work unchanged during migration.

---

## Part 3 — How Den Works (Quick Reference)

### Anatomy of an Aspect

An aspect is an attrset with class-keyed configs, optional dependencies
(`includes`), and optional sub-aspects (`provides`)[^4]:

```
┌─────────────────────────────────────────────────────┐
│  den.aspects.gaming                                 │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │  OWNED CONFIGS (keyed by Nix class)           │  │
│  │                                               │  │
│  │  nixos = { pkgs, ... }: { ... }               │  │
│  │  homeManager = { pkgs, ... }: { ... }         │  │
│  │  darwin = { pkgs, ... }: { ... }    (optional)│  │
│  │  user = { ... }: { ... }            (optional)│  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │  INCLUDES (dependencies on other aspects)     │  │
│  │                                               │  │
│  │  [ den.aspects.performance                    │  │
│  │    den.provides.primary-user ]                │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │  PROVIDES (named sub-aspects)                 │  │
│  │                                               │  │
│  │  provides.emulation = { nixos = { ... }; }    │  │
│  │  provides.replays   = { homeManager = {...};} │  │
│  │  provides.gamescope = { host, ... }: { ... }  │  │
│  │                                               │  │
│  │  Access: den.aspects.gaming._.emulation       │  │
│  │     or:  <aspects/roles/gaming/emulation>     │  │
│  └───────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

```nix
den.aspects.gaming = {
  nixos        = { pkgs, ... }: { programs.steam.enable = true; };
  homeManager  = { pkgs, ... }: { home.packages = [ pkgs.lutris ]; };

  includes = [ den.aspects.performance den.provides.primary-user ];

  # Sub-aspects (accessible as den.aspects.gaming._.emulation)
  provides.emulation = {
    nixos = { pkgs, ... }: { boot.binfmt.emulatedSystems = [ "aarch64-linux" ]; };
  };
};
```

### Parametric Dispatch — The Core Mechanism

Den[^1] uses `builtins.functionArgs` to inspect what context a function needs.
The context shape **is** the condition[^5]:

```
                         Den encounters a value in an aspect
                                       │
                                       ▼
                              ┌─────────────────┐
                              │  Is it a plain   │──── Yes ──► Apply unconditionally
                              │  attrset?        │              in all contexts
                              └────────┬─────────┘
                                       │ No (it's a function)
                                       ▼
                              ┌─────────────────┐
                              │  Inspect args    │
                              │  via builtins.   │
                              │  functionArgs    │
                              └────────┬─────────┘
                                       │
               ┌───────────────────────┼───────────────────────┐
               │                       │                       │
        needs { host }          needs { host, user }      needs { home }
               │                       │                       │
               ▼                       ▼                       ▼
     ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
     │ Runs in:        │    │ Runs in:        │    │ Runs in:        │
     │  • host ctx  ✓  │    │  • host ctx  ✗  │    │  • host ctx  ✗  │
     │  • user ctx  ✓  │    │  • user ctx  ✓  │    │  • user ctx  ✗  │
     │  • home ctx  ✗  │    │  • home ctx  ✗  │    │  • home ctx  ✓  │
     └─────────────────┘    └─────────────────┘    └─────────────────┘

     Examples:                Examples:               Examples:
     networking.hostName      users.users.X.groups     standalone HM
     hardware config          HM user-specific cfg     on non-NixOS
     system services          git signing key          (dell/Fedora)
```

```nix
{ nixos.networking.firewall.enable = true; }

({ host, ... }: { nixos.networking.hostName = host.hostName; })

({ host, user, ... }: {
  nixos.users.users.${user.userName}.extraGroups = [ "wheel" ];
})

({ home }: { homeManager.home.stateVersion = "24.05"; })
```

No `mkIf`, no `enable` flags to wire up. A function requiring `{ host, user }`
is silently skipped in contexts that only have `{ host }`.

### The Context Pipeline

Den[^1] traverses your infra entities in order[^6]:

```
                              ┌──────────────────────────────┐
                              │    den.hosts (NixOS hosts)   │
                              └──────────────┬───────────────┘
                                             │
                    ┌────────────────────────┬┴────────────────────────┐
                    ▼                        ▼                        ▼
            ┌───────────────┐       ┌───────────────┐       ┌───────────────┐
            │   framework   │       │   framebox    │       │  workstation  │  ...
            └───────┬───────┘       └───────┬───────┘       └───────┬───────┘
                    │                       │                       │
         den.ctx.host { host }   den.ctx.host { host }   den.ctx.host { host }
          ┌─────────┤             ┌─────────┤             ┌─────────┤
          │  nixos   │            │  nixos   │            │  nixos   │
          │  class   │            │  class   │            │  class   │
          └─────────┘             └─────────┘             └─────────┘
                    │                       │                       │
       den.ctx.user { host, user }         ...                     ...
          ┌─────────┤
          │  nixos   │  ← users.users.haseeb, groups, etc.
          │  HM      │  ← forwarded to home-manager module system
          └─────────┘

                              ┌──────────────────────────────┐
                              │  den.homes (standalone HM)   │
                              └──────────────┬───────────────┘
                                             │
                                   ┌─────────────────┐
                                   │ haseebmajid@dell │
                                   └────────┬────────┘
                                            │
                               den.ctx.home { home }
                                 ┌──────────┤
                                 │  HM only │  ← no nixos class, no host context
                                 └──────────┘
```

The key: `{ host }`, `{ host, user }`, and `{ home }` are the three contexts.
Parametric dispatch means a function requiring `{ host, user }` is silently
skipped when Den is only evaluating `{ host }`. A function requiring `{ host }`
is silently skipped for a standalone `{ home }` context.

### Batteries (Built-in Reusable Aspects)

Den[^1] ships batteries for common patterns[^7]:

| Battery | What it does |
|---------|-------------|
| `den._.define-user` | Creates `users.users.<name>` on OS + sets HM `home.username`/`home.homeDirectory` |
| `den._.hostname` | Sets `networking.hostName` from `host.hostName` |
| `den._.primary-user` | Adds `wheel`/`networkmanager` groups, sets `system.primaryUser` |
| `den._.user-shell "fish"` | Sets login shell at OS and HM levels |
| `den._.import-tree` | Loads a directory of plain Nix modules (migration bridge) |

### Namespaces

Den[^1] supports custom namespaces via `inputs.den.namespace`[^8]. Instead of
all aspects living under `den.aspects.*`, you can scope them under a project
name. quasigod's config uses this with `styx`:

```nix
# modules/den.nix
{ inputs, den, ... }: {
  _module.args.__findFile = den.lib.__findFile;
  imports = [
    inputs.den.flakeModule
    (inputs.den.namespace "styx" true)
  ];
}

# Then aspects live under styx.* instead of den.aspects.*:
styx.gaming.provides.min = { host, ... }: { nixos = { pkgs, ... }: { ... }; };
```

quasigod uses the namespace `styx` for his config. Namespaces are optional — for
nixicle we will skip namespacing and use `den.aspects.*` directly, keeping the
setup simpler. Angle-bracket paths resolve relative to `modules/` without needing
a namespace prefix.

### Angle Brackets (`<den/battery>`)

Den[^1] supports `<angle-bracket>` syntax for including batteries[^9], enabled by
setting `_module.args.__findFile = den.lib.__findFile` in `den.nix`.

```
How angle brackets resolve (in order):

  <den/primary-user>            ──► den.provides.primary-user  (built-in battery)
  <den/user-shell/fish>         ──► den.provides.user-shell.provides.fish

  <aspects/roles/desktop>       ──► den.aspects.aspects.provides.roles.provides.desktop
                                    (resolves via modules/aspects/roles/desktop.nix)

  <aspects/roles/gaming/replays>──► den.aspects...gaming.provides.replays

  <users/haseeb/base>           ──► den.aspects...haseeb.provides.base
                                    (resolves via modules/users/haseeb/base.nix)

  Rule: every / in the path maps to .provides. in the lookup.
        <a/b/c> = den.aspects.a.provides.b.provides.c
```

quasigod's `quasi.nix` demonstrates this cleanly:

```nix
{ __findFile, ... }: {
  den.aspects.quasi = {
    includes = [
      <den/primary-user>      # built-in battery
      <styx/helix/with-tools> # project-scoped namespace path
      <styx/nushell>
      <styx/shell>
    ];
  };
}
```

This is more readable than `den.provides.primary-user` for long include lists.

---

## Part 4 — Aspect Design Patterns

Doc-Steve's guide[^2] catalogues 8 recurring patterns. These are the ones most
directly applicable to nixicle, mapped to concrete examples from your config
and from community repos.

### Pattern 1: Simple Aspect

**Use case:** A feature used in one or more contexts, independently, no
dependencies on other aspects.

Most of your services fit this pattern. Each is self-contained:

```nix
# modules/aspects/services/tailscale.nix
{ den, ... }: {
  den.aspects.tailscale = {
    nixos = { ... }: { services.nixicle.tailscale.enable = true; };
  };
}
```

A role that spans NixOS and HM is also a Simple Aspect — just with multiple
class keys:

```nix
# modules/aspects/roles/gaming.nix
{ den, ... }: {
  den.aspects.gaming = {
    nixos       = { pkgs, ... }: { programs.steam.enable = true; ... };
    homeManager = { pkgs, ... }: { home.packages = [ pkgs.lutris ]; ... };
  };
}
```

### Pattern 2: Inheritance Aspect

**Use case:** Extend an existing aspect. User-host pairs use this — each pair
extends a base user aspect.

```nix
# modules/users/haseeb/framework.nix
{ den, ... }: {
  den.aspects.haseeb-framework = {
    # Inherit everything from haseeb-base
    includes = [ den.aspects.haseeb-base ];

    # Extend with framework-specific config
    homeManager = { ... }: {
      desktops.addons.swayidle.enable = true;
      # laptop-specific settings ...
    };
  };
}
```

The `includes` list is Den's[^1] equivalent of `imports` — it composes aspects
into a hierarchy.

### Pattern 3: Multi-Context Aspect

**Use case:** A feature primarily used in one context (NixOS) that also needs
to configure a nested context (Home-Manager).

Your `desktop` role is the canonical example. The NixOS host imports the aspect,
which simultaneously configures both OS-level settings and HM settings:

```nix
den.aspects.desktop = {
  nixos       = { ... }: { hardware.bluetooth.enable = true; ... };
  homeManager = { ... }: { home.sessionVariables = { MOZ_ENABLE_WAYLAND = 1; }; ... };
};
```

### Pattern 4: Conditional Aspect

**Use case:** Parts of an aspect that apply only under certain conditions — most
commonly platform differences within the same class.

Use `lib.mkMerge` (not `//`) when merging conditional parts:

```nix
den.aspects.fonts = {
  homeManager = { pkgs, lib, ... }:
    lib.mkMerge [
      { fonts.fontconfig.enable = true; }
      (lib.mkIf pkgs.stdenv.isLinux {
        home.packages = [ pkgs.fontconfig ];
      })
    ];
};
```

> In Den's[^1] parametric model you often avoid this entirely by using the
> `guard` mechanism on forwarded classes instead. But `lib.mkIf` inside owned
> configs is always valid when the condition is within a class context.

### Pattern 5: Collector Aspect

**Use case:** A feature whose configuration is built up by contributions from
multiple other features. Syncthing peer IDs are the canonical example — each
host contributes its own ID to the shared syncthing aspect.

quasigod's config[^10] uses this for syncthing: each host file adds its own
device entry to the shared `styx.services.syncthing` aspect without a central
registry file.

```nix
# modules/aspects/services/syncthing.nix — base definition
{ den, ... }: {
  den.aspects.syncthing = {
    nixos = { ... }: { services.syncthing.enable = true; };
  };
}

# modules/aspects/hosts/framebox.nix — framebox contributes its peer ID
{ den, ... }: {
  den.aspects.syncthing = {
    nixos = { ... }: {
      services.syncthing.settings.devices.framebox = {
        id = "FRAMEBOX-DEVICE-ID-HERE";
      };
    };
  };
}
```

Because Den[^1] merges all `den.aspects.syncthing` definitions across all files,
each host contributes its own peer data without a central file.

### Pattern 6: Constants Aspect

**Use case:** Shared typed metadata that other aspects read — things like admin
email, org name, domain names.

In Den[^1] this is done via `den.schema`[^4]:

```nix
den.schema.conf = { lib, ... }: {
  options.domain = lib.mkOption { default = "haseebmajid.dev"; };
  options.org    = lib.mkOption { default = "nixicle"; };
};
```

### Pattern 7: DRY Aspect

**Use case:** Modularise repeated attribute-set assignments. In nixicle the NFS
mount configuration repeated verbatim on `framebox` and `workstation` is a
textbook DRY aspect opportunity:

```nix
# Define once, reuse on both hosts
den.aspects.nfs-truenas = {
  nixos = { ... }: {
    services.rpcbind.enable = true;
    fileSystems."/mnt/homelab" = {
      device  = "truenas:/mnt/main/main-encrypted";
      fsType  = "nfs";
      options = [ "nfsvers=4" "noatime" "nofail"
                  "x-systemd.automount" "x-systemd.idle-timeout=60"
                  "x-systemd.requires=tailscaled.service"
                  "x-systemd.after=tailscaled.service" ];
    };
    fileSystems."/mnt/truenas" = { ... };
  };
};

den.aspects.framebox.includes   = [ den.aspects.nfs-truenas ... ];
den.aspects.workstation.includes = [ den.aspects.nfs-truenas ... ];
```

### Pattern 8: Factory Aspect

**Use case:** Parametric feature generation — aspects built from arguments.
Den's[^1] built-in batteries like `den._.user-shell "fish"` are factory aspects.

quasigod's config[^10] uses `den.lib.parametric` to build tiered aspects:

```nix
# gaming.nix — min and max tiers built parametrically
styx.gaming.provides = {
  min = { host, ... }: {
    nixos = { pkgs, ... }: {
      programs.gamescope.args = [
        "-W ${toString host.primaryDisplay.width}"
        "-H ${toString host.primaryDisplay.height}"
        "-r ${toString host.primaryDisplay.refresh}"
        "-O ${host.primaryDisplay.name}"
      ];
    };
  };

  max = den.lib.parametric {
    includes = [ styx.gaming._.replays styx.gaming._.min styx.gaming._.mcsr ];
    nixos = { pkgs, ... }: { ... };
  };
};
```

The `host.primaryDisplay.*` read from `den.schema.host` typed metadata — the
display resolution and refresh rate are declared on each host and consumed by
the aspect without hard-coding. We can apply the same pattern to nixicle:

```nix
# Declare display metadata on hosts
den.schema.host = { lib, ... }: {
  options.isLaptop = lib.mkEnableOption "laptop profile";
  options.primaryDisplay = {
    name    = lib.mkOption { default = "eDP-1"; };
    width   = lib.mkOption { default = 2256; type = lib.types.int; };
    height  = lib.mkOption { default = 1504; type = lib.types.int; };
    refresh = lib.mkOption { default = 60;   type = lib.types.int; };
  };
};

# framework
den.hosts.x86_64-linux.framework = {
  isLaptop = true;
  primaryDisplay = { name = "eDP-1"; width = 2256; height = 1504; refresh = 120; };
};

# workstation
den.hosts.x86_64-linux.workstation = {
  isLaptop = false;
  primaryDisplay = { name = "DP-1"; width = 3440; height = 1440; refresh = 144; };
};

# Gamescope aspect reads it — no hard-coded resolution anywhere
den.aspects.gaming.provides.gamescope = { host, ... }: {
  nixos.programs.gamescope.args = [
    "-W ${toString host.primaryDisplay.width}"
    "-H ${toString host.primaryDisplay.height}"
    "-r ${toString host.primaryDisplay.refresh}"
    "-O ${host.primaryDisplay.name}"
    "-f" "--adaptive-sync" "--mangoapp"
  ];
};
```

### Pattern 9: Performance Tiers via Sub-Aspects

**Discovered in:** quasigod's `performance.nix`[^10]

A base performance aspect with opt-in escalating tiers via `provides`:

```nix
# modules/aspects/performance.nix
{ den, ... }: {
  den.aspects.performance = {
    nixos.boot.kernel.sysctl = {
      "transparent_hugepage" = "always";
      "vm.nr_hugepages_defrag" = 0;
    };

    provides = {
      # Tier 1: responsive (includes base)
      responsive = {
        includes = [ den.aspects.performance ];
        nixos.boot.kernel.sysctl."vm.swappiness" = 1;
        nixos.boot.kernelParams = [
          "nowatchdog" "nosoftlockup" "preempt=full" "threadirqs"
        ];
      };

      # Tier 2: max performance (includes responsive)
      max = {
        includes = [ den.aspects.performance._.responsive ];
        nixos.boot.kernelParams = [
          "cpufreq.default_governor=performance"
          "workqueue.power_efficient=false"
        ];
      };
    };
  };
}
```

Usage — hosts opt into the tier they need:

```nix
# framework (laptop — balanced)
den.aspects.framework.includes = [ den.aspects.performance._.responsive ];

# workstation (desktop — max)
den.aspects.workstation.includes = [ den.aspects.performance._.max ];

# framebox (server — base only, no latency tuning needed)
den.aspects.framebox.includes = [ den.aspects.performance ];
```

This replaces the current approach of duplicating kernel params in each host
config.

### Pattern 10: GPU Screen Recorder as a Systemd User Service

**Discovered in:** quasigod's `gaming.nix`[^10]

GPU screen recorder running as a persistent systemd user service with SIGUSR1
replay saves — directly applicable to nixicle's gaming setup on framework and
workstation:

```nix
# modules/aspects/roles/gaming.nix — replay sub-aspect
den.aspects.gaming.provides.replays = {
  homeManager = { pkgs, lib, ... }: {
    home.packages = [ pkgs.gpu-screen-recorder ];
    systemd.user.services.gpu-screen-recorder = {
      Unit.Description    = "gpu-screen-recorder replay service";
      Install.WantedBy    = [ "graphical-session.target" ];
      Service.ExecStart   = ''
        ${lib.getExe pkgs.gpu-screen-recorder} \
          -w portal -f 60 -r 60 -k av1 \
          -a 'default_output' -a 'default_input' \
          -c mp4 -q high \
          -o %h/Videos/Replays \
          -restore-portal-session yes -v no
      '';
    };
  };
};

# Usage — hosts that want replay support opt in:
den.aspects.framework.includes  = [ den.aspects.gaming._.replays ];
den.aspects.workstation.includes = [ den.aspects.gaming._.replays ];
```

Save a replay: `killall -SIGUSR1 gpu-screen-recorder`

### Selecting the Right Pattern

Doc-Steve's process[^2] for any new feature:

1. Clearly define the requirements vs existing features
2. Assess which pattern(s) match
3. Implement

A single feature can use multiple patterns simultaneously. Your `haseeb-framework`
user aspect uses **Inheritance** (extends `haseeb-base`) + **Multi-Context**
(configures both HM and NixOS via the `user` class).

---

## Part 5 — Community Patterns (Observed in the Wild)

These patterns are drawn from reviewing real Den[^1] configs. They are directly
adoptable into nixicle.

### Repos Reviewed

| Repo | Access | Notes |
|------|--------|-------|
| [Sharparam/nix-config][sharparam] | ✅ Full access | Den + flake-file + Darwin + nvf; typed `den.schema.user`/`den.schema.home`; `homes/user@host/` directory; profile aspects; `base/` per-tool granularity |
| [quasigod/nixconfig][quasigod] | ✅ Full access | Den namespaces (`styx`), angle-bracket syntax, typed host schema, tiered performance aspects, GPU recorder service |
| [Moortu/dotfiles][moortu] | ✅ Full access (git clone) | Den + stylix + niri + sops + lanzaboote + disko; `flake.modules.nixos.*` reusable NixOS module registry; `provides.to-users` for per-host niri/display overrides; tag-based SOPS secret registry; multi-user (moortu + kris) with different roles per host; dark-*/light-* host variants |
| [Adda/nixos-config][adda] | ❌ Codeberg blocked | Could not review |

[sharparam]: https://github.com/Sharparam/nix-config
[quasigod]: https://tangled.org/quasigod.xyz/nixconfig
[moortu]: https://codeberg.org/Moortu/dotfiles
[adda]: https://codeberg.org/Adda/nixos-config

---

### Pattern: Typed `den.schema.user` and `den.schema.home`

**Source:** Sharparam/nix-config[^11] — `modules/users/schema.nix`

Sharparam extends both `den.schema.user` and `den.schema.home` with typed
options for the user's identity — full name, email, git/jujutsu signing key,
and SSH public keys. These are set once with defaults and consumed by any aspect
that needs them, without passing `specialArgs` or duplicating values:

```nix
# modules/users/schema.nix
let
  defaultEmail      = "haseeb@haseebmajid.dev";
  defaultSigningKey = "key::ssh-ed25519 AAAA...";
in {
  den.schema.user = { lib, ... }: {
    options = {
      email      = lib.mkOption { type = lib.types.str; default = defaultEmail; };
      signingKey = lib.mkOption { type = lib.types.nullOr lib.types.str; default = defaultSigningKey; };
      authorizedKeys = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ defaultSigningKey ]; };
    };
    config = {
      email      = lib.mkDefault defaultEmail;
      signingKey = lib.mkDefault defaultSigningKey;
    };
  };

  # Also extend den.schema.home for standalone HM homes (dell)
  den.schema.home = { lib, ... }: {
    options = {
      email      = lib.mkOption { type = lib.types.str; default = defaultEmail; };
      signingKey = lib.mkOption { type = lib.types.nullOr lib.types.str; default = defaultSigningKey; };
    };
  };
}
```

Then in user/home aspects, read them from context instead of hard-coding:

```nix
# modules/users/haseeb/base.nix
{ den, ... }: {
  den.aspects.haseeb-base = {
    homeManager = { user, pkgs, ... }: {
      programs.git = {
        userEmail  = user.email;
        signing.key = user.signingKey;
        signing.signByDefault = true;
      };
    };

    nixos = { user, ... }: {
      users.users.haseeb.openssh.authorizedKeys.keys = user.authorizedKeys;
    };
  };
}
```

**Why this matters for nixicle:** Your git signing key, email, and SSH
authorized keys are currently duplicated across multiple host files. A single
`modules/users/schema.nix` sets them once with typed defaults; any aspect that
needs them reads from `user.*` or `home.*` context.

---

### Pattern: Inline Aspect + Home Declaration in One File

**Source:** Sharparam/nix-config[^11] — `modules/homes/sharparam@melina/module.nix`

The home directory contains a single `module.nix` that declares both the
`den.homes` entry *and* the aspect for that home, colocating everything about
that standalone machine in one place:

```nix
# modules/homes/haseebmajid@dell/module.nix
{ __findFile, ... }:
let
  username = "haseebmajid";
  hostname = "dell";
  identifier = "${username}@${hostname}";
in {
  # The home declaration
  den.homes.x86_64-linux."${identifier}" = {
    userName = username;
    aspect   = identifier;
  };

  # The aspect for this home — all in the same file
  den.aspects."${identifier}" = {
    includes = [
      <haseeb/base>
      <nixicle/desktop>
      <nixicle/development>
    ];

    homeManager = { config, lib, pkgs, ... }: {
      roles.non-nixos.enable = true;
      home.stateVersion      = "23.11";
      sops.defaultSymlinkPath       = lib.mkForce "/run/user/1003/secrets";
      sops.defaultSecretsMountPoint = lib.mkForce "/run/user/1003/secrets.d";

      home.sessionVariables = {
        FLAKE_CONFIG_URI = ''$HOME/repos/nixicle#homeConfigurations.\"$USER@$HOST\"'';
      };
    };
  };
}
```

The `FLAKE_CONFIG_URI` session variable (also from Sharparam) is a useful
convention: it gives every shell session a variable pointing at the exact flake
output for that machine, making `home-manager switch` scripting trivial.

For nixicle, replace `modules/users/haseebmajid/dell.nix` with a directory
`modules/homes/haseebmajid@dell/module.nix` — same content, but the directory
name itself documents that this is a standalone home.

---

### Pattern: Profile Aspects (Composable Role Bundles)

**Source:** Sharparam/nix-config[^11] — `modules/profiles/`

Sharparam has a thin `profiles/` directory with aspects that bundle tools for
a specific *context* (work machine, dev machine). They use angle-bracket syntax
exclusively — no tool config, just composition:

```nix
# modules/profiles/work.nix
{ __findFile, ... }: {
  den.aspects.work = {
    includes = [
      <programs/azure>
      <programs/slack>
    ];
    darwin.homebrew.casks = [ "microsoft-auto-update" "microsoft-teams" ];
    darwin.homebrew.masApps."Microsoft Outlook" = 985367838;
  };
}

# modules/profiles/dev.nix
{ __findFile, ... }: {
  den.aspects.dev = {
    includes = [
      <programs/ast-grep>
      <programs/emacs>
      <programs/mise>
      <programs/neovim>
      <programs/podman>
      <programs/postman>
      <programs/uv>
    ];
  };
}
```

For nixicle, this maps directly to the existing roles system — but with the
profile as a pure `includes` list, not an option module. The distinction from
`base/` aspects is intent: `profiles/` = "this machine is used for X",
`base/` = "every machine gets this tool".

Adopt for nixicle:

```nix
# modules/profiles/homelab.nix — framebox is a homelab server
{ __findFile, ... }: {
  den.aspects.homelab = {
    includes = [
      <aspects/services/traefik>
      <aspects/services/tailscale>
      <aspects/services/monitoring>
      <aspects/nfs-truenas>
    ];
  };
}
```

---

### Pattern: Per-Tool Granularity in `base/`

**Source:** Sharparam/nix-config[^11] — `modules/base/`

Sharparam's `base/` directory has one file per tool — `atuin.nix`, `bat.nix`,
`direnv.nix`, `fzf.nix`, `zellij.nix`, etc. Each is a minimal aspect. The base
*bundle* aspect then includes them all via angle brackets:

```nix
# modules/base/module.nix
{ __findFile, ... }: {
  den.aspects.base.includes = [
    <ssh>
    <programs/atuin-desktop>
    <programs/discord>
    <programs/ghostty>
    <programs/kde-connect>
    <programs/obs>
    <programs/signal>
    <programs/spotify>
    <programs/telegram>
  ];
}
```

Each individual program file is a Simple Aspect that can be included
independently. This is the maximum colocation granularity — every program owns
its own config (NixOS service + HM program config) in one file.

For nixicle, we adopt a middle ground — **one file per category** rather than
per-tool:

```
modules/
  aspects/
    programs/
      cli.nix         ← fish, atuin, starship, direnv, bat, ripgrep (HM + NixOS)
      editors.nix     ← nixcats, helix (HM + NixOS)
      terminals.nix   ← zellij, ghostty (HM + NixOS)
      security.nix    ← sops-nix, gpg, ssh keys (NixOS + HM)
```

Each category file is a Multi-Context Aspect — colocating NixOS and HM config
for a group of related tools. If a category grows too large, split it further.

---

### Pattern: `flake.modules.nixos.*` — Reusable NixOS Module Registry

**Source:** Moortu/dotfiles[^15]

Moortu registers reusable NixOS modules under `flake.modules.nixos.*` and
references them via `inputs.self.modules.nixos`:

```nix
# modules/nixos/services/stylix.nix
{ inputs, ... }: {
  flake.modules.nixos.stylix = { pkgs, ... }: {
    stylix = {
      enable = true;
      autoEnable = true;
      polarity = "dark";
      base16Scheme = { base00 = "24283B"; base0D = "91BEF5"; /* ... */ };
      image = ../../../resources/wallpapers/Fantasy-IcyMountain.png;
      fonts.monospace = { package = pkgs.nerd-fonts.hack; name = "Hack Nerd Font Mono"; };
      cursor = { package = pkgs.adwaita-icon-theme; name = "Adwaita"; size = 24; };
    };
  };
}

# modules/nixos/system/lanzaboote.nix
{ inputs, ... }: {
  flake.modules.nixos.lanzaboote = { pkgs, lib, ... }: {
    imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];
    boot.lanzaboote = { enable = true; pkiBundle = "/var/lib/sbctl"; };
    boot.loader.systemd-boot.enable = lib.mkForce false;
    environment.systemPackages = [ pkgs.sbctl ];
  };
}
```

Then host aspects import them by name:

```nix
# modules/hosts/nexus/nexus.nix
den.aspects.nexus.nixos = { pkgs, ... }: {
  imports = with inputs.self.modules.nixos; [
    nexus-hw amd-cpu nvidia-rtx-5000 ssd
    desktop-base personal work lanzaboote
  ];
};
```

**Why this matters for nixicle:** Your `modules/nixos/` tree already has
per-feature files (roles, services, hardware). The `flake.modules.nixos.*`
pattern gives each one a name that's accessible from anywhere via
`inputs.self.modules.nixos.*`, without needing `imports = [ ./relative/path ]`.
This is a useful bridge pattern during the import-tree migration — register
existing NixOS modules as named flake modules, then reference them from host
aspects.

---

### Pattern: `provides.to-users` for Per-Host Display Overrides

**Source:** Moortu/dotfiles[^15]

Moortu uses `provides.to-users.homeManager` on host aspects to push
per-host niri output/display configuration into the user's HM config:

```nix
# modules/hosts/sentinel/sentinel.nix
den.aspects.sentinel = {
  nixos = { ... };

  provides.to-users.homeManager = {
    programs.niri.settings.outputs."Lenovo Group Limited 0x40A9 Unknown" = {
      mode = { width = 1920; height = 1080; refresh = 60.033; };
      scale = 1.0;
      position = { x = 0; y = 0; };
    };
  };
};
```

**Why this matters for nixicle:** Your niri display settings currently live in
each `home.nix`. With `provides.to-users`, the host aspect pushes display-
specific config into the user HM — the user aspect stays display-agnostic. This
is the same `mutual-provider` pattern described in Part 12, applied to niri
outputs specifically. Combined with `den.ctx.user.includes = [den._.mutual-provider]`
in `den.nix`, it enables host → user config forwarding.

---

### Pattern: Tag-Based SOPS Secret Registry

**Source:** Moortu/dotfiles[^15] — `secrets/lib.nix`

Moortu's most distinctive pattern is a single `secrets/lib.nix` that acts as a
registry of all secrets, tagged by category (`base`, `work`, `personal`). Users
declare which tags they need, and the registry generates the `sops.secrets` and
SSH pubkey activation scripts automatically:

```nix
# secrets/lib.nix (simplified)
let
  registry = {
    ssh-nixos-ed25519  = { path = ".ssh/nixos_ed25519"; tags = ["base"]; pub = "nixos_ed25519.pub"; };
    ssh-work-ed25519   = { path = ".ssh/work_ed25519";  tags = ["work"]; pub = "work_ed25519.pub"; };
    aws-credentials    = { path = ".aws/credentials";    tags = ["work"]; };
    kubeconfig         = { path = ".kube/config";        tags = ["work"]; };
    # ...
  };
in {
  # Generate sops.secrets for a user with given tags
  forUser = userName: home: tags: /* filters registry by tags, generates sops.secrets */;

  # Generate activation scripts for SSH pubkey deployment
  pubkeysFor = userName: home: tags: /* installs pubkeys for matching tags */;
}

# modules/users/moortu.nix — usage
{ den, ... }: let sec = import ../../secrets/lib.nix; in {
  den.aspects.moortu.nixos = { ... }: {
    sops.secrets = sec.forUser "moortu" "/home/moortu" ["base" "personal" "work"] // {
      moortu-password.neededForUsers = true;
    };
    system.activationScripts.moortu-pubkeys = sec.pubkeysFor "moortu" "/home/moortu" ["base" "personal" "work"];
  };
}

# modules/users/kris.nix — different user, different tags
{ den, ... }: let sec = import ../../secrets/lib.nix; in {
  den.aspects.kris.nixos = { ... }: {
    sops.secrets = sec.forUser "kris" "/home/kris" ["base" "work"] // {
      kris-password.neededForUsers = true;
    };
    system.activationScripts.kris-pubkeys = sec.pubkeysFor "kris" "/home/kris" ["base" "work"];
  };
}
```

**Why this matters for nixicle:** You use sops-nix with per-host `secrets.yaml`
files. The tag-based registry centralises secret declarations — adding a new
secret to all work machines is one line in the registry, not editing every host.
Particularly relevant for nixicle with `haseeb` across 4 NixOS hosts and
`haseebmajid` on dell.

---

### Pattern: `den.default.nixos` for Global NixOS Defaults

**Source:** Moortu/dotfiles[^15] — `modules/flake/den.nix`

Moortu's `den.default.nixos` imports all shared NixOS modules (disko, sops,
niri, stylix, flatpak, facter) and sets global config (overlays, unfree,
experimental features, stateVersion) in one place:

```nix
den.default.nixos = { pkgs, ... }: {
  imports = [
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
    inputs.niri.nixosModules.niri
    inputs.stylix.nixosModules.stylix
    inputs.nixos-facter-modules.nixosModules.facter
    inputs.nix-flatpak.nixosModules.nix-flatpak
  ];
  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [ /* ... */ ];
  nix.settings.experimental-features = ["nix-command" "flakes"];
  system.stateVersion = "25.11";
};
```

**Why this matters for nixicle:** Your Phase 1 `den.default` only sets
`stateVersion` and includes batteries. Following Moortu, move the shared NixOS
module imports (disko, sops, niri, nixos-facter, stylix) into `den.default.nixos`
so they apply to every host automatically. Host aspects then only need
host-specific imports (hardware, lanzaboote, etc.).

---

### Pattern: `desktop-base` Profile — Composing Named Modules

**Source:** Moortu/dotfiles[^15] — `modules/nixos/system/profile/desktop-base.nix`

Moortu's `desktop-base` is a `flake.modules.nixos` that composes other named
modules — it reads as a manifest of what a desktop machine includes:

```nix
flake.modules.nixos.desktop-base = { pkgs, ... }: {
  imports = with inputs.self.modules.nixos; [
    locale networking nix-settings firmware fonts
    bluetooth pipewire xdg-portal browser cli-tools
    ly media niri office ssh stylix clone-config
  ];
  services.upower.enable = true;
  services.gnome.gnome-keyring.enable = true;
  services.printing.enable = true;
  services.flatpak.enable = true;
  programs.nix-ld.enable = true;
  # ...
};
```

Then `personal` and `work` profiles add on top:

```nix
flake.modules.nixos.personal = { imports = with inputs.self.modules.nixos; [ games virtualization ]; };
flake.modules.nixos.work     = { imports = with inputs.self.modules.nixos; [ work-apps ]; };
```

And hosts compose profiles:

```nix
den.aspects.nexus.nixos.imports = with inputs.self.modules.nixos; [
  nexus-hw amd-cpu nvidia-rtx-5000 ssd desktop-base personal work lanzaboote
];
```

This is the same layered composition as our `profiles/` directory but using
named flake modules instead of Den aspects. Either approach works — the key
insight is that a host reads as a flat list of capabilities.

---

### Pattern: `flake-file` — Auto-generated `flake.nix`

**Source:** Sharparam/nix-config[^11]

The `flake.nix` is auto-generated and must not be edited manually:

```nix
# DO-NOT-EDIT. This file was auto-generated using github:vic/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
  inputs  = { den.url = "github:vic/den"; ... };
}
```

`flake-file`[^12] generates the `flake.nix` from a module in `modules/` — so
even the input declarations move into the module tree. Each feature that needs
an input declares it in its own module file. This is an optional step adoptable
after Phase 2 is stable.

---

### Pattern: Typed Host Schema for Display Metadata

**Source:** quasigod/nixconfig[^10]

quasigod declares `primaryDisplay` metadata on each host via `den.schema.host`
and reads it in the `gaming.nix` gamescope aspect. This eliminates hard-coded
resolutions:

```nix
# host declares its display
den.hosts.x86_64-linux.hades = {
  primaryDisplay = { name = "DP-1"; width = 2560; height = 1440; refresh = 144; };
};

# aspect reads it — works for any host without duplication
den.aspects.gaming.provides.min = { host, ... }: {
  nixos.programs.gamescope.args = [
    "-W ${toString host.primaryDisplay.width}"
    "-r ${toString host.primaryDisplay.refresh}"
  ];
};
```

Adopt this for nixicle: declare `isLaptop`, `primaryDisplay`, and `hasGpu` in
`den.schema.host` so aspects can self-configure per host without knowing
hostname.

---

### Pattern: Den Namespace Scoping (Not Adopted)

**Source:** quasigod/nixconfig[^10]

Instead of all aspects living under `den.aspects.*`, you can scope them under a
project name:

```nix
# modules/den.nix
{ inputs, den, ... }: {
  imports = [
    inputs.den.flakeModule
    (inputs.den.namespace "styx" true)  # aspects under styx.* instead of den.aspects.*
  ];
}
```

Benefits: avoids name collision, makes grep unambiguous, clearly brands code.

**Decision for nixicle:** We chose *not* to adopt a namespace. `den.aspects.*`
is simpler and avoids an extra concept. Angle-bracket paths (`<aspects/...>`)
provide the same readability benefit without requiring a namespace.

---

### Pattern: Angle Bracket Battery Includes

**Source:** Sharparam/nix-config[^11] and quasigod/nixconfig[^10]

With `_module.args.__findFile = den.lib.__findFile` set, include lists become
more readable and path-based:

```nix
{ __findFile, ... }: {
  den.aspects.haseeb = {
    includes = [
      <den/primary-user>              # built-in battery
      <den/user-shell/fish>           # parametric battery
      <aspects/roles/desktop>         # project aspect
      <aspects/roles/development>
      <aspects/roles/gaming>
      <aspects/programs/editors>      # program category
    ];
  };
}
```

Both Sharparam and quasigod use angle brackets as the *only* way to wire
includes — no `den.provides.*` or `den.aspects.*` references in include lists,
just paths. Without a namespace, paths resolve relative to `modules/`.

---

### Pattern: `nix-gaming` for Low-Latency Pipewire + Platform Optimisations

**Source:** quasigod/nixconfig[^10]

```nix
den.aspects.gaming.provides.max = {
  nixos = { pkgs, ... }: {
    imports = [
      inputs.nix-gaming.nixosModules.platformOptimizations
      inputs.nix-gaming.nixosModules.pipewireLowLatency
    ];
    services.pipewire.lowLatency = { enable = true; quantum = 512; };
    programs.steam.platformOptimizations.enable  = true;
    programs.steam.remotePlay.openFirewall        = true;
  };
};
```

Add `nix-gaming` as a flake input and wire it into `den.aspects.gaming.provides.max`
for framebox and workstation.

---

## Part 6 — File Organisation Principles

From Doc-Steve's guide[^2], adapted to nixicle:

- All features live in `modules/` — every `.nix` file is a feature module
- Feature name = file name (or directory name if split across multiple files)
- Hardware/data files that are not feature modules live *outside* the feature
  tree (in `hosts/`) and are imported from within the aspect's `nixos` key
- Sub-directories add structure as the feature count grows
- File names are documentation — follow a consistent naming convention
- Files prefixed with `_` are excluded from import-tree auto-import (useful for
  disabling WIP code or for data files that are not modules)
- **No "what" comments.** Only write a comment if it explains *why* something is
  done in a non-obvious way. If the code already says what it does, a comment
  restating it adds noise — delete it.

```
modules/
  aspects/          ← all feature aspects
    roles/          ← cross-cutting role features
    services/       ← individual service features
    hosts/          ← host-level composition aspects
  users/            ← user-host pair aspects
  den.nix           ← host/home declarations, namespace setup
  flake-outputs.nix ← non-OS flake outputs

hosts/              ← hardware only (not feature modules)
  framework/        ← disks.nix, facter.json, hw-config, secrets.yaml
  framebox/
  ...
```

---

## Part 7 — Current State of nixicle

### Host Inventory

| Host | Type | User(s) | Notes |
|------|------|---------|-------|
| `framework` | NixOS x86_64 | haseeb | Framework 13 laptop, impermanence, secure boot |
| `framebox` | NixOS x86_64 | haseeb | Homelab server, ~20 services, gaming |
| `workstation` | NixOS x86_64 | haseeb | Desktop, gaming, NFS mounts |
| `vm` | NixOS x86_64 | haseeb | VM for testing |
| `vps` | NixOS x86_64 | nixos | Headless VPS, traefik reverse proxy |
| `dell` | Standalone HM | haseebmajid | Fedora work laptop, non-NixOS |

### What Already Exists in Den

`modules/den.nix` and `modules/legacy.nix` already exist. The foundation is in
place — this migration builds on it.

```nix
# modules/den.nix (current — only framework declared)
{ inputs, ... }: {
  imports = [ inputs.den.flakeModule ];
  den.hosts.x86_64-linux.framework.users.haseeb = { };
}

# modules/legacy.nix (current — import-tree bridge intact)
{ den, ... }: {
  den.ctx.host.includes = [ (den.provides.import-tree._.host ./hosts) ];
  den.ctx.user.includes = [ (den.provides.import-tree._.user ./users) ];
}
```

The import-tree bridge is your safety net throughout the migration — existing
modules continue to work unchanged in parallel with new aspects.

---

## Part 8 — Greenfield Architecture (If Starting From Scratch)

### The Boilerplate Problem (By the Numbers)

The current config has **177 out of 195** module files (91%) following this pattern:

```nix
# Every single module file looks like this:
{ config, lib, ... }:
with lib; let
  cfg = config.services.nixicle.foo;    # ← 1. cfg binding
in {
  options.services.nixicle.foo = {       # ← 2. option declaration
    enable = mkEnableOption "foo";       # ← 3. enable option
  };
  config = mkIf cfg.enable {            # ← 4. conditional guard
    # actual config here
  };
}
```

That is 4 lines of ceremony per file x 177 files = **~700 lines of pure
boilerplate**. In Den, all of this disappears — including an aspect *is*
enabling it. All custom option namespaces (`services.nixicle.*`, `cli.programs.*`,
`roles.*`, `desktops.*`) are replaced by aspect inclusion.

### The Double-Dispatch Problem

To enable desktop gaming on framework today requires 6 files:

```
hosts/framework/home.nix ─── sets roles.gaming.enable = true ───┐
                                                                 ├─► modules/home/roles/gaming/default.nix
                                                                 │     mkIf cfg.enable { HM gaming config }
hosts/framework/default.nix ─ sets roles.gaming.enable = true ───┤
                                                                 └─► modules/nixos/roles/gaming/default.nix
                                                                       mkIf cfg.enable { NixOS gaming config }
```

In Den this becomes 2 files:

```
modules/aspects/hosts/framework.nix
  └── includes = [ <aspects/roles/gaming> ]
                         │
                         └── modules/aspects/roles/gaming.nix
                               ├── nixos = { ... }
                               └── homeManager = { ... }
```

### What Disappears vs What Gets Created

```
DELETED:                                               FILES
──────────────────────────────────────────────────────  ─────
modules/nixos/roles/*/default.nix                       ~15
modules/home/roles/*/default.nix                        ~15
modules/nixos/services/*/default.nix                    ~25
modules/home/services/*/default.nix                     ~10
modules/nixos/cli/*/default.nix                         ~10
modules/home/cli/*/default.nix                          ~15
modules/home/browsers/*/default.nix                      ~5
modules/home/desktops/*/default.nix                     ~15
modules/shared/*/default.nix                             ~5
hosts/*/default.nix + hosts/*/home.nix                   12
mkEnableOption declarations                              77
mkIf cfg.enable guards                                  241
Custom option namespaces (services.nixicle.* etc.)      all
                                                        ────
                                                       ~127 files deleted

CREATED:                                               FILES
──────────────────────────────────────────────────────  ─────
modules/den.nix (expanded)                                1
modules/aspects/roles/*.nix (colocated)                  ~8
modules/aspects/services/*.nix                          ~20
modules/aspects/programs/*.nix (by category)             ~4
modules/aspects/hosts/*.nix                               5
modules/profiles/*.nix                                   ~3
modules/users/haseeb/*.nix                                5
modules/users/schema.nix                                  1
modules/homes/haseebmajid@dell/module.nix                 1
modules/secrets/lib.nix                                   1
                                                        ────
                                                        ~49 files created

NET: ~127 deleted, ~49 created. Codebase shrinks ~40% in file count.
     Zero boilerplate in surviving files.
```

### Architecture Overview

```
                    ┌─────────────────────────────────────────┐
                    │              flake.nix                   │
                    │  (auto-generated by flake-file)          │
                    │  outputs = evalModules(import-tree ./modules)│
                    └────────────────────┬────────────────────┘
                                         │
                    ┌────────────────────┴────────────────────┐
                    │             modules/                     │
                    │  Every .nix file is a top-level module   │
                    │  Auto-imported by import-tree             │
                    └────────────────────┬────────────────────┘
                                         │
       ┌──────────┬──────────┬───────────┼───────────┬──────────┬──────────┐
       │          │          │           │           │          │          │
    den.nix   aspects/   users/     homes/     profiles/  secrets/  flake-
    (schema,  (features) (user     (standalone  (role     (registry outputs.nix
     hosts,              aspects)   HM homes)  bundles)   lib.nix)
     defaults)
       │          │          │           │
       │    ┌─────┼─────┐    │           │
       │    │     │     │    │           │
       │  roles/ svcs/ progs/│           │
       │    │     │     │    │           │
       │    │    one    │  haseeb/   haseebmajid@dell/
       │    │   aspect   │  base.nix     module.nix
       │    │   per svc  │  framework.nix
       │    │            │
       │  desktop.nix  cli.nix
       │  gaming.nix   editors.nix
       │  dev.nix      terminals.nix
```

### How Aspect Composition Works (framework example)

```
den.aspects.framework (host aspect)
    │
    ├─ includes ──► <aspects/roles/desktop>
    │                 ├── nixos: bluetooth, audio, plymouth, nix-ld
    │                 ├── homeManager: session vars, tray, wayland pkgs
    │                 └── provides:
    │                      ├── niri   (nixos + HM)
    │                      └── greetd (nixos)
    │
    ├─ includes ──► <aspects/roles/gaming>
    │                 ├── nixos: steam, graphics
    │                 └── provides:
    │                      ├── replays    (HM: gpu-screen-recorder systemd)
    │                      ├── gamescope  ({host}: reads host.primaryDisplay)
    │                      └── performance (nixos: nix-gaming, low-latency)
    │
    ├─ includes ──► <aspects/performance/responsive>
    │                 └── nixos: swappiness=1, nowatchdog, preempt=full
    │
    ├─ nixos ──────► hardware-config, disks.nix, lanzaboote
    │                sops.secrets (host-specific only)
    │
    └─ provides.to-users.homeManager
         └── programs.niri.settings.outputs."eDP-1" = { ... }
             (pushed into haseeb's HM via den._.mutual-provider)


den.aspects.haseeb-framework (user aspect)
    │
    ├─ includes ──► <users/haseeb/base>
    │                 ├── includes: <den/primary-user>, <den/user-shell/fish>
    │                 ├── homeManager: git (reads user.email, user.signingKey)
    │                 └── nixos: authorized SSH keys (reads user.authorizedKeys)
    │
    └─ homeManager ──► noctalia (laptop=true), swayidle timeouts
```

### The Secret Flow (Hybrid Model)

```
User secrets (centralized):         Service secrets (per-host):
┌────────────────────────┐          ┌───────────────────────┐
│  secrets/lib.nix       │          │ hosts/framebox/        │
│  (tag-based registry)  │          │   secrets.yaml         │
│                        │          │   cloudflared          │
│ ssh-nixos   [base]     │          │   b2_access_key        │
│ ssh-work    [work]     │          │   b2_secret_key        │
│ git-signing [base]     │          │   gitlab_runner_env    │
└───────────┬────────────┘          └───────────┬───────────┘
            │                                   │
  sec.forUser "haseeb"               Host aspect imports
  ["base","personal"]                directly from sopsFile
            │                                   │
            ▼                                   ▼
  sops.secrets = {                   sops.secrets = {
    ssh-nixos = ...;                   cloudflared = { sopsFile = ... };
    git-signing = ...;                 b2_access_key = { sopsFile = ... };
  }                                  }
```

### Display Configuration Flow

```
den.schema.host                  den.hosts.framework
  ├── isLaptop                     ├── isLaptop = true
  └── primaryDisplay               └── primaryDisplay
       ├── name                         ├── name = "eDP-1"
       ├── width                        ├── width = 2256
       ├── height                       ├── height = 1504
       └── refresh                      └── refresh = 120
                                              │
                  ┌───────────────────────────┤
                  │                           │
    gaming.provides.gamescope          framework host aspect
    reads { host, ... }:               provides.to-users.homeManager:
    ┌─────────────────────┐            ┌──────────────────────────┐
    │ gamescope.args = [  │            │ programs.niri.settings   │
    │   "-W 2256"         │            │   .outputs."eDP-1" = {  │
    │   "-H 1504"         │            │   mode.width = 2256;    │
    │   "-r 120"          │            │   scale = 1.5;          │
    │   "-O eDP-1"        │            │ };                      │
    │ ]                   │            └──────────┬───────────────┘
    └─────────────────────┘                       │
                                    den._.mutual-provider
                                                  │
                                                  ▼
                                    haseeb's HM gets niri
                                    output config automatically
```

### Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Namespace | None — use `den.aspects.*` | Simpler, one fewer concept |
| Include syntax | Angle brackets only | Readable, path-based, used by all community configs |
| Enable boilerplate | Strip as we convert | Aspect inclusion IS enabling — no `mkEnableOption` needed |
| Option namespaces | Replace all with aspects | `den.aspects.immich` replaces `services.nixicle.immich.enable` |
| SOPS secrets | Hybrid — registry for users, per-host for services | User secrets centralized, service secrets stay host-local |
| den.default.nixos | Shared frameworks | disko, sops, niri, stylix, nixos-facter imported globally |
| Programs | Grouped by category | `cli.nix`, `editors.nix`, `terminals.nix` — not per-tool |
| nix-gaming | Add it | Low-latency pipewire + steam platform optimizations |
| flake-file | Phase 6 | Input declarations move into the modules that need them |
| mutual-provider | Enable globally | `den.ctx.user.includes = [den._.mutual-provider]` in Phase 1 |

---

## Part 9 — Migration Plan

Six phases. Each phase leaves the config in a buildable state. **Never break
the build between phases.**

```
                    MIGRATION PHASES — DEPENDENCY & RISK MAP

  Phase 1 ───► Phase 2 ───► Phase 3 ───► Phase 4 ───► Phase 5 ───► Phase 6
  Hosts &       Thin         Users &      Roles &      Services    flake-file
  Schemas      flake.nix     Homes        Programs     (framebox)  (inputs)
  ─────────    ──────────    ─────────    ─────────    ──────────  ──────────
  RISK: Zero   RISK: Low    RISK: Low    RISK: Med    RISK: Med   RISK: Low
  SCOPE: 1     SCOPE: 2     SCOPE: ~12   SCOPE: ~20   SCOPE: ~25  SCOPE: all
   file         files         files        files        files       inputs

  ◄═══════════ import-tree bridge active ══════════════►│
  │  Old modules/nixos/ and modules/home/ still load    │
  │  via modules/legacy.nix throughout these phases     │ bridge removed
  │  New aspects run ALONGSIDE the old code             │ in final cleanup
  ◄═════════════════════════════════════════════════════►│

  FILES TOUCHED PER PHASE:
  ────────────────────────
  Ph1: modules/den.nix (expand)
  Ph2: flake.nix (rewrite) + modules/flake-outputs.nix (create)
  Ph3: modules/users/**  modules/homes/**  modules/secrets/lib.nix  modules/den.nix
  Ph4: modules/aspects/roles/**  modules/aspects/programs/**  modules/profiles/**
       DELETE: modules/nixos/roles/**  modules/home/roles/**
  Ph5: modules/aspects/services/**  modules/aspects/hosts/**
       DELETE: hosts/*/default.nix
  Ph6: all module files (add flake-file.inputs)  flake.nix (auto-generated)
```

### Graceful Migration Strategy

Each phase follows this safety protocol:

```
┌─────────────────────────────────────────────────────────────────┐
│                    PER-PHASE WORKFLOW                            │
│                                                                 │
│  1. Branch ──► git checkout -b den/phase-N                      │
│                                                                 │
│  2. Implement ──► make changes for this phase only              │
│                                                                 │
│  3. Validate ──► for each host/home:                            │
│       nix build .#nixosConfigurations.<host>.config              │
│         .system.build.toplevel                                  │
│       home-manager build --flake .#"<user>@<host>"              │
│                                                                 │
│  4. Test on VM ──► nixos-rebuild build-vm --flake .#vm          │
│                    ./result/bin/run-*-vm                         │
│                                                                 │
│  5. Deploy to least-critical host first:                        │
│       vm → vps → dell → workstation → framebox → framework      │
│                                                                 │
│  6. If anything breaks:                                         │
│       git stash && nixos-rebuild switch --flake .#<host>        │
│       (import-tree bridge keeps old modules working)            │
│                                                                 │
│  7. Merge ──► git checkout main && git merge den/phase-N        │
└─────────────────────────────────────────────────────────────────┘
```

**The import-tree bridge is the safety net.** During Phases 1-4, your existing
`modules/nixos/` and `modules/home/` trees continue to load through
`modules/legacy.nix`. New aspects run alongside them. You never delete old
modules until the new aspects are verified. Phase by phase:

| Phase | Old modules | New aspects | Risk |
|-------|-------------|-------------|------|
| 1 | All loaded via import-tree | Host declarations only | Zero — additive |
| 2 | All loaded via import-tree | flake.nix simplified, outputs moved | Low — only plumbing changes |
| 3 | All loaded via import-tree | User aspects created alongside old `home.nix` | Low — old home.nix deleted only after new aspects verified |
| 4 | Being replaced one at a time | Role aspects colocate NixOS + HM | Medium — mkEnableOption stripped, aspect inclusion replaces enable flags |
| 5 | Remaining services replaced | Service aspects for framebox | Medium — same pattern as Phase 4 |
| 6 | All deleted | flake-file auto-generates flake.nix | Low — inputs move, no functional change |

**Per-module migration within Phase 4/5:**

When converting a module (e.g. `modules/nixos/roles/gaming/default.nix` +
`modules/home/roles/gaming/default.nix`) to an aspect:

1. Create `modules/aspects/roles/gaming.nix` with both NixOS + HM config
2. Strip the `mkEnableOption` + `mkIf cfg.enable` boilerplate — the aspect's
   existence IS the enable mechanism
3. Update the user aspects that used `roles.gaming.enable = true` to instead
   use `includes = [ <aspects/roles/gaming> ]`
4. Build and test: `nix build .#nixosConfigurations.framework.config.system.build.toplevel`
5. Once verified, delete the old `modules/nixos/roles/gaming/` and
   `modules/home/roles/gaming/` directories
6. Repeat for the next module

---

### Phase 1 — Declare All Hosts, Schemas, and Shared Defaults

**Goal:** Every host and home declared in `den.hosts`/`den.homes`. Legacy
`mkSystem`/`mkHome` still works. Enable angle-bracket
syntax. The import-tree bridge keeps existing modules loading unchanged.

**Expand `modules/den.nix`:**

```nix
{ inputs, den, lib, ... }: {
  _module.args.__findFile = den.lib.__findFile;

  imports = [ inputs.den.flakeModule ];

  # Enable mutual-provider globally (host → user config forwarding via provides.to-users)
  den.ctx.user.includes = [den._.mutual-provider];

  den.default = {
    includes = [
      <den/define-user>   # creates users.users.<name> + HM home dirs
      <den/hostname>      # sets networking.hostName from host.hostName
    ];
    nixos = { ... }: {
      imports = [
        inputs.disko.nixosModules.disko
        inputs.sops-nix.nixosModules.sops
        inputs.niri.nixosModules.niri
        inputs.stylix.nixosModules.stylix
        inputs.nixos-facter-modules.nixosModules.facter
      ];
      nixpkgs.config.allowUnfree = true;
      nix.settings.experimental-features = [ "nix-command" "flakes" ];
      system.stateVersion = "24.05";
    };
    homeManager.home.stateVersion = "24.05";
  };

  den.schema.user = { lib, ... }: {
    config.classes = lib.mkDefault [ "homeManager" ];
  };

  # Typed host metadata — read by aspects, no hard-coding needed
  den.schema.host = { lib, ... }: {
    options.isLaptop       = lib.mkEnableOption "laptop profile";
    options.primaryDisplay = {
      name    = lib.mkOption { type = lib.types.str;  default = "DP-1"; };
      width   = lib.mkOption { type = lib.types.int;  default = 1920; };
      height  = lib.mkOption { type = lib.types.int;  default = 1080; };
      refresh = lib.mkOption { type = lib.types.int;  default = 60; };
    };
  };

  den.hosts.x86_64-linux.framework = {
    isLaptop       = true;
    primaryDisplay = { name = "eDP-1"; width = 2256; height = 1504; refresh = 120; };
    users.haseeb   = { };
  };
  den.hosts.x86_64-linux.framebox.users.haseeb    = { };
  den.hosts.x86_64-linux.workstation = {
    primaryDisplay = { name = "DP-1"; width = 3440; height = 1440; refresh = 144; };
    users.haseeb   = { };
  };
  den.hosts.x86_64-linux.vm.users.haseeb          = { };
  den.hosts.x86_64-linux.vps.users.nixos           = { };

  # Standalone home — Fedora work laptop, home-manager only, no NixOS class
  den.homes.x86_64-linux."haseebmajid@dell"        = { };
}
```

**Validation:** `nix flake check` — all existing builds still pass.

---

### Phase 2 — Simplify `flake.nix` to a Thin Evaluator

**Goal:** Remove `mkSystem`, `mkHome`, `mkHomeModule`. All outputs come from
`modules/`. The `flake.nix` becomes ~10 lines.

**Create `modules/flake-outputs.nix`:**

```nix
# modules/flake-outputs.nix
{ inputs, lib, ... }:
let
  supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
  forAllSystems    = lib.genAttrs supportedSystems;
  overlays = [
    inputs.gomod2nix.overlays.default
    inputs.nur.overlays.default
    inputs.nix-topology.overlays.default
    inputs.niri.overlays.niri
    (final: prev: {
      zjstatus = inputs.zjstatus.packages.${prev.stdenv.hostPlatform.system}.default;
    })
    (final: prev: {
      inherit (inputs) get-shit-done;
      nixicle = lib.nixicle.importPackages final ./packages // {
        zellij-mcp = prev.callPackage ./packages/zellij-mcp { inherit inputs; };
      };
    })
  ];
  mkPkgs = system: import inputs.nixpkgs {
    inherit system overlays;
    config.allowUnfree = true;
  };
in {
  flake.packages  = forAllSystems (system: (mkPkgs system).nixicle // { iso-graphical = ...; });
  flake.devShells = forAllSystems (system: { default = (mkPkgs system).mkShell { packages = [ ... ]; }; });
  flake.deploy    = lib.nixicle.mkDeploy {
    inherit (inputs) self;
    overrides = {
      framebox.profiles.system.sshUser    = "haseeb";
      framework.profiles.system.sshUser   = "haseeb";
      workstation.profiles.system.sshUser = "haseeb";
      vm.profiles.system.sshUser          = "haseeb";
      vps.profiles.system.sshUser         = "nixos";
    };
  };
  flake.checks   = builtins.mapAttrs
    (system: deploy-lib: deploy-lib.deployChecks inputs.self.deploy)
    inputs.deploy-rs.lib;
  flake.topology =
    let host = inputs.self.nixosConfigurations.framebox;
    in import inputs.nix-topology {
      inherit (host) pkgs;
      modules = [
        (import ./topology { inherit (host) config; })
        { inherit (inputs.self) nixosConfigurations; }
      ];
    };
}
```

**New `flake.nix`:**

```nix
{
  description = "Haseeb's Nix/NixOS Config";

  inputs = {
    # ... all current inputs unchanged ...
    den.url        = "github:vic/den";
    import-tree.url = "github:vic/import-tree";
    flake-file.url  = "github:vic/flake-file";  # optional: auto-generate flake.nix
  };

  outputs = inputs:
    (inputs.nixpkgs.lib.evalModules {
      modules           = [ (inputs.import-tree ./modules) ];
      specialArgs.inputs = inputs;
    }).config.flake;
}
```

Den[^1] auto-populates `config.flake.nixosConfigurations` and
`config.flake.homeConfigurations`. The `mkSystem`/`mkHome` helpers are deleted.

**Validation:**

```bash
nix flake check
nixos-rebuild build --flake .#framework
nixos-rebuild build --flake .#framebox
home-manager  build --flake .#"haseeb@framework"
home-manager  build --flake .#"haseebmajid@dell"
```

---

### Phase 3 — User-Host Pair Aspects

**Goal:** Each user-host combination gets its own named aspect (Inheritance
Pattern). A base aspect holds shared config; pair aspects extend it with
host-specific overrides.

**Directory structure:**

```
modules/
  users/
    schema.nix          ← den.schema.user + den.schema.home (typed identity)
    haseeb/
      base.nix          ← Simple Aspect: shared fish shell, git signing, primary-user
      framework.nix     ← Inheritance Aspect: extends base, laptop-specific
      framebox.nix      ← Inheritance Aspect: extends base, no desktop idle
      workstation.nix   ← Inheritance Aspect: extends base, NFS groups, gaming
      vm.nix            ← Inheritance Aspect: extends base, minimal
    nixos/
      vps.nix           ← Simple Aspect: headless VPS user
  homes/
    haseebmajid@dell/
      module.nix        ← Inline home declaration + aspect (Sharparam pattern)
```

**`modules/users/haseeb/base.nix`** (Simple Aspect, reads typed schema):

```nix
{ __findFile, ... }: {
  den.aspects.haseeb-base = {
    includes = [
      <den/primary-user>        # wheel, networkmanager groups
      <den/user-shell/fish>     # fish shell at OS + HM level
    ];

    # Reads user.email and user.signingKey from den.schema.user
    # (set with defaults in modules/users/schema.nix)
    homeManager = { user, pkgs, ... }: {
      programs.git = {
        # Reads user.email and user.signingKey from den.schema.user
        userEmail        = user.email;
        signing.key      = user.signingKey;
        signing.format   = "ssh";
        signing.signByDefault = true;
      };
      gtk.gtk4.theme = null;
    };

    nixos = { user, ... }: {
      users.users.haseeb.openssh.authorizedKeys.keys = user.authorizedKeys;
    };

    user = { pkgs, ... }: {   # → users.users.haseeb on NixOS
      description = "Haseeb Majid";
    };
  };
}
```

**`modules/users/haseeb/framework.nix`** (Inheritance Aspect):

```nix
{ __findFile, ... }: {
  den.aspects.haseeb-framework = {
    includes = [
      <users/haseeb/base>                 # inherit shared user config
      <aspects/roles/desktop>             # role: desktop
      <aspects/roles/gaming>              # role: gaming
      <aspects/roles/gaming/replays>      # sub-aspect: GPU replays
      <aspects/roles/gaming/gamescope>    # sub-aspect: gamescope (reads host.primaryDisplay)
    ];

    homeManager = { ... }: {
      desktops = {
        niri.enable = true;
        addons.noctalia = {
          enable   = true;
          laptop   = true;
          settings.osd.monitors = [ "eDP-1" ];
        };
        addons.swayidle = {
          enable   = true;
          timeouts = { lock = 300; dpms = 330; suspend = 0; hibernate = 900; };
        };
      };
    };
  };
}
```

**`modules/homes/haseebmajid@dell/module.nix`** (Inline home + aspect, Sharparam pattern):

```nix
# Standalone HM on Fedora — nixos class silently skipped by Den[^1] because
# den.homes produces a { home } context, not a { host, user } context.
{ __findFile, ... }:
let
  username   = "haseebmajid";
  hostname   = "dell";
  identifier = "${username}@${hostname}";
in {
  den.homes.x86_64-linux."${identifier}" = {
    userName = username;
    aspect   = identifier;
  };

  den.aspects."${identifier}" = {
    includes = [
      <den/primary-user>
      <aspects/roles/desktop>
      <aspects/roles/development>
    ];

    homeManager = { pkgs, lib, ... }: {
      roles.non-nixos.enable = true;
      home.stateVersion      = "23.11";
      sops.defaultSymlinkPath       = lib.mkForce "/run/user/1003/secrets";
      sops.defaultSecretsMountPoint = lib.mkForce "/run/user/1003/secrets.d";
      home.packages = with pkgs; [
        semgrep pre-commit bun
        pkgs.nixicle.monolisa
        pkgs.noto-fonts-color-emoji pkgs.noto-fonts
        pkgs.nerd-fonts.symbols-only
      ];
      home.sessionVariables.FLAKE_CONFIG_URI =
        ''$HOME/repos/nixicle#homeConfigurations.\"${identifier}\"'';
    };
  };
}
```

**Wire in `modules/den.nix`** (NixOS hosts only — dell is declared inline in its
own `module.nix`):

```nix
den.hosts.x86_64-linux.framework.users.haseeb   = { aspect = "haseeb-framework"; };
den.hosts.x86_64-linux.framebox.users.haseeb    = { aspect = "haseeb-framebox"; };
den.hosts.x86_64-linux.workstation.users.haseeb = { aspect = "haseeb-workstation"; };
den.hosts.x86_64-linux.vm.users.haseeb          = { aspect = "haseeb-vm"; };
den.hosts.x86_64-linux.vps.users.nixos          = { aspect = "nixos-vps"; };
# den.homes."haseebmajid@dell" is declared in modules/homes/haseebmajid@dell/module.nix
```

---

### Phase 4 — Role Aspects (Colocation Payoff)

**Goal:** Replace `modules/nixos/roles/` + `modules/home/roles/` with unified
Den[^1] aspects (Multi-Context Aspect pattern).

**Before:** Two files for one feature.

```
modules/nixos/roles/desktop/default.nix   ← NixOS side
modules/home/roles/desktop/default.nix    ← HM side
```

**After:** One file, both contexts side by side (Multi-Context Aspect).

**`modules/aspects/roles/desktop.nix`:**

```nix
{ den, ... }: {
  den.aspects.desktop = {
    nixos = { pkgs, ... }: {
      boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
      hardware = {
        audio.enable         = true;
        bluetooth.enable     = true;
        logitechMouse.enable = true;
        zsa.enable           = true;
      };
      services = {
        nixicle.avahi.enable = true;
        nixicle.vpn.enable   = true;
        upower.enable        = true;
      };
      system.boot.plymouth = true;
      cli.programs = { nh.enable = true; nix-ld.enable = true; };
    };

    homeManager = { pkgs, ... }: {
      systemd.user.targets.tray.Unit = {
        Description = "Home Manager System Tray";
        Requires    = [ "graphical-session-pre.target" ];
      };
      services.nixicle.kdeconnect.enable = true;
      desktops.addons.xdg.enable         = true;
      home.sessionVariables = {
        MOZ_ENABLE_WAYLAND = 1;
        QT_QPA_PLATFORM    = "wayland;xcb";
        LIBSEAT_BACKEND    = "logind";
        EDITOR             = "nixCats";
        MANPAGER           = "nixCats +Man!";
      };
      home.packages = with pkgs; [
        ddcutil wl-clipboard clipse pamixer playerctl
        grimblast slurp satty
      ];
    };

    # Opt-in addons via provides sub-aspects
    provides.niri   = { nixos = { ... }; homeManager = { ... }; };
    provides.greetd = { nixos = { ... }; };
  };
}
```

**`modules/aspects/roles/gaming.nix`** — with performance tiers and GPU recorder:

```nix
{ den, inputs, ... }: {
  den.aspects.gaming = {
    nixos = { pkgs, ... }: {
      programs.steam.enable = true;
      hardware.graphics.enable32Bit = true;
    };

    provides = {
      # Performance optimisations (opt-in)
      performance = {
        includes = [ den.aspects.performance._.max ];
        nixos = { pkgs, ... }: {
          imports = [
            inputs.nix-gaming.nixosModules.platformOptimizations
            inputs.nix-gaming.nixosModules.pipewireLowLatency
          ];
          programs.steam.platformOptimizations.enable = true;
          services.pipewire.lowLatency = { enable = true; quantum = 512; };
        };
      };

      # Gamescope — reads display metadata from host schema
      gamescope = { host, ... }: {
        nixos.programs.gamescope.args = [
          "-W ${toString host.primaryDisplay.width}"
          "-H ${toString host.primaryDisplay.height}"
          "-r ${toString host.primaryDisplay.refresh}"
          "-O ${host.primaryDisplay.name}"
          "-f" "--adaptive-sync" "--mangoapp"
        ];
      };

      # GPU screen recorder as systemd user service (from quasigod pattern)
      replays = {
        homeManager = { pkgs, lib, ... }: {
          home.packages = [ pkgs.gpu-screen-recorder ];
          systemd.user.services.gpu-screen-recorder = {
            Unit.Description  = "gpu-screen-recorder replay service";
            Install.WantedBy  = [ "graphical-session.target" ];
            Service.ExecStart = ''
              ${lib.getExe pkgs.gpu-screen-recorder} \
                -w portal -f 60 -r 60 -k av1 \
                -a 'default_output' -a 'default_input' \
                -c mp4 -q high \
                -o %h/Videos/Replays \
                -restore-portal-session yes -v no
            '';
          };
        };
      };
    };
  };
}
```

Also extract **NFS mounts** (DRY Aspect) since they are duplicated on both
`framebox` and `workstation`:

```nix
# modules/aspects/nfs-truenas.nix
{ den, ... }: {
  den.aspects.nfs-truenas = {
    nixos = { ... }: {
      services.rpcbind.enable = true;
      fileSystems."/mnt/homelab" = { ... };
      fileSystems."/mnt/truenas" = { ... };
    };
  };
}
```

**Role migration order:**

1. `common` — baseline for all hosts, lowest risk
2. `desktop` — highest value, used on 3 hosts
3. `gaming` — framework, framebox, workstation (include new sub-aspects)
4. `performance` — tiered system-wide performance aspect
5. `development` — most user homes
6. `social`, `non-nixos`, `video`, `gamedev`

---

### Phase 5 — Service Aspects (framebox Homelab)

**Goal:** Each of framebox's ~20 services becomes a self-contained Simple
Aspect. Services are reusable, independently testable, and movable to a second
server by including the aspect.

**`modules/aspects/hosts/framebox.nix`** (Collector/Inheritance Aspect):

```nix
{ __findFile, inputs, ... }: {
  den.aspects.framebox = {
    includes = [
      # Roles
      <aspects/roles/desktop>             <aspects/roles/desktop/niri>
      <aspects/roles/gaming>              <aspects/roles/gaming/replays>
      <aspects/performance>               <aspects/nfs-truenas>

      # Services (one aspect per service)
      <aspects/services/immich>           <aspects/services/authentik>
      <aspects/services/attic>            <aspects/services/cloudflare>
      <aspects/services/monitoring>       <aspects/services/ollama>
      <aspects/services/postgresql>       <aspects/services/redis>
      <aspects/services/traefik>          <aspects/services/tailscale>
      <aspects/services/btrbk>            <aspects/services/gitea>
      <aspects/services/gitlab-runner>    <aspects/services/karakeep>
      <aspects/services/open-webui>       <aspects/services/paperless>
      <aspects/services/tangled>          <aspects/services/tandoor>
      <aspects/services/crowdsec>         <aspects/services/goroutinely>
    ];

    nixos = { config, inputs, ... }: {
      imports = [
        ../../hosts/framebox/hardware-configuration.nix
        ../../hosts/framebox/disks.nix
        inputs.nixos-facter-modules.nixosModules.facter
        { config.facter.reportPath = ../../hosts/framebox/facter.json; }
        inputs.nixos-hardware.nixosModules.framework-desktop-amd-ai-max-300-series
      ];

      sops.secrets = {
        user_password     = { sopsFile = ../../hosts/framebox/secrets.yaml; neededForUsers = true; };
        gitlab_runner_env = { sopsFile = ../../hosts/framebox/secrets.yaml; };
        cloudflared       = { sopsFile = ../../hosts/framebox/secrets.yaml; };
        b2_access_key     = { sopsFile = ../../hosts/framebox/secrets.yaml; };
        b2_secret_key     = { sopsFile = ../../hosts/framebox/secrets.yaml; };
      };

      user.passwordSecretFile        = config.sops.secrets.user_password.path;
      users.groups.media.gid         = 3000;
      users.users.haseeb.extraGroups = [ "media" ];

      system = {
        impermanence.enable = true;
        boot = { enable = true; secureBoot = true; };
      };

      networking.hostName = "framebox";
      system.stateVersion = "24.05";
    };
  };
}
```

### Phase 5 — Hardcoded Values in Service Aspects

When migrating service aspects, the following values are currently hardcoded
inline in each aspect file. They should eventually be extracted into a shared
`modules/aspects/services/config.nix` or passed via `den.schema.host` options:

| Value | Current hardcoded string | Appears in |
|-------|--------------------------|-----------|
| Personal domain | `haseebmajid.dev` | traefik routes, cloudflare ingress, gotify, karakeep, goroutinely, navidrome, tandoor, authentik, banterbus, paperless, open-webui |
| Homelab subdomain | `homelab.haseebmajid.dev` | traefik `mkTraefikService` default domain, atticd, gitea |
| Cloudflare tunnel ID | `ecef5dbb-834e-43ed-84c6-355a2ac53e59` | cloudflare.nix, authentik, atuin, banterbus, goroutinely, karakeep, navidrome, open-webui, paperless, tandoor, tangled, gotify, audiobookshelf, papra, hortusfox, trek |
| Uptime Kuma tunnel ID | `0e845de6-544a-47f2-a1d5-c76be02ce153` | uptime-kuma.nix |

**Recommended follow-up:** Add these to `den.schema.host` or a shared `let`
block in a common `modules/aspects/services/_config.nix` imported by all
service aspects, so changing domain or tunnel ID only requires one edit.

Example pattern using a shared config file:

```nix
# modules/aspects/services/_config.nix  (imported, not a den module)
{
  domain = "haseebmajid.dev";
  homelabDomain = "homelab.haseebmajid.dev";
  cloudflareTunnelId = "ecef5dbb-834e-43ed-84c6-355a2ac53e59";
}
```

```nix
# modules/aspects/services/gotify.nix
{ den, ... }:
let cfg = import ./_config.nix; in
{
  den.aspects.gotify = {
    nixos = { lib, ... }: {
      services.cloudflared.tunnels.${cfg.cloudflareTunnelId}.ingress."notify.${cfg.domain}" = "http://localhost:8051";
    };
  };
}
```

---

### Phase 6 — flake-file Adoption (Inputs Move Into Modules)

**Goal:** The `flake.nix` is auto-generated by `flake-file`[^12]. Every input
declaration moves into the aspect file that uses it — the input, NixOS config,
and HM config all colocated in one place.

**Step 1 — Add `flake-file` to `flake.nix` inputs:**

```nix
flake-file.url = "github:vic/flake-file";
```

**Step 2 — Add `flake-file.inputs.<name>` to each aspect file, alongside the config that uses it.**

The pattern: open the aspect file, add `flake-file.inputs.<name>.url` at the
top, remove the input from `flake.nix`. Each file becomes fully self-contained.

```nix
# modules/aspects/impermanence.nix
{ den, inputs, ... }: {
  flake-file.inputs.impermanence.url = "github:nix-community/impermanence";

  den.aspects.impermanence = {
    nixos = {
      imports = with inputs; [ impermanence.nixosModules.default ];
      environment.persistence."/persistence".allowTrash = true;
    };
    homeManager.home.persistence."/persistence".hideMounts = false;
  };
}

# modules/aspects/boot.nix
{ den, inputs, ... }: {
  flake-file.inputs.lanzaboote.url = "github:nix-community/lanzaboote";
  # ... existing lanzaboote config ...
}

# modules/aspects/niri.nix
{ den, inputs, ... }: {
  flake-file.inputs.niri = {
    url = "github:sodiboo/niri-flake";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  flake-file.inputs.nfsm = {
    url = "github:gvolpe/nfsm";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  # ... existing niri + nfsm config ...
}

# modules/aspects/profiles/non-nixos.nix
{ den, inputs, ... }: {
  flake-file.inputs.nixgl.url = "github:nix-community/nixGL";
  flake-file.inputs.pam-shim = {
    url = "github:Cu3PO42/pam_shim/next";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  # ... existing non-nixos config ...
}

# modules/aspects/profiles/video.nix
{ den, inputs, ... }: {
  flake-file.inputs.catppuccin-obs = {
    url = "github:catppuccin/obs";
    flake = false;
  };
  # ... existing video config ...
}

# modules/aspects/services/tangled.nix
{ den, inputs, ... }: {
  flake-file.inputs.tangled = {
    url = "git+https://tangled.sh/@tangled.sh/core";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  # ... existing tangled config ...
}

# modules/aspects/services/authentik.nix
{ den, inputs, ... }: {
  flake-file.inputs.authentik-nix.url = "github:nix-community/authentik-nix";
  # ... existing authentik config ...
}

# modules/aspects/services/goroutinely.nix
{ den, inputs, ... }: {
  flake-file.inputs.goroutinely = {
    url = "gitlab:hmajid2301/goroutinely/feat/move-to-internal";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  # ... existing goroutinely config ...
}

# modules/aspects/services/banterbus.nix
{ den, inputs, ... }: {
  flake-file.inputs.banterbus = {
    url = "gitlab:hmajid2301/banterbus";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  # ... existing banterbus config ...
}

# modules/aspects/services/nixery.nix
{ den, inputs, ... }: {
  flake-file.inputs.nixery = {
    url = "github:tazjin/nixery";
    flake = false;
  };
  # ... existing nixery config ...
}

# modules/hosts/framework.nix — only host that uses nixos-hardware
{ den, inputs, ... }: {
  flake-file.inputs.nixos-hardware.url = "github:nixos/nixos-hardware";
  # ... existing framework config ...
}

# modules/flake-outputs.nix — deploy + ISO tooling
{ inputs, ... }: {
  flake-file.inputs.deploy-rs = {
    url = "github:serokell/deploy-rs";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  flake-file.inputs.nixos-generators = {
    url = "github:nix-community/nixos-generators";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  flake-file.inputs.nixos-anywhere.url = "github:numtide/nixos-anywhere";
  # ... existing outputs config ...
}

# modules/den.nix — global inputs with no single owner
{ den, inputs, ... }: {
  flake-file.inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  flake-file.inputs.sops-nix = {
    url = "github:mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  flake-file.inputs.disko = {
    url = "github:nix-community/disko";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  flake-file.inputs.stylix.url = "github:danth/stylix";
  flake-file.inputs.catppuccin.url = "github:catppuccin/nix";
  flake-file.inputs.nur.url = "github:nix-community/NUR";
  flake-file.inputs.gomod2nix = {
    url = "github:nix-community/gomod2nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  flake-file.inputs.nix-topology = {
    url = "github:oddlama/nix-topology";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  flake-file.inputs.nix-index-database.url = "github:nix-community/nix-index-database";
  flake-file.inputs.nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
  flake-file.inputs.noctalia = {
    url = "github:noctalia-dev/noctalia-shell";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  flake-file.inputs.dankMaterialShell = {
    url = "github:AvengeMedia/DankMaterialShell";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  flake-file.inputs.zjstatus.url = "github:dj95/zjstatus";
  flake-file.inputs.get-shit-done.url = "...";  # wherever get-shit-done lives
  # ... rest of den.nix ...
}

# HM neovim aspect (to be created in a future phase)
{ den, inputs, ... }: {
  flake-file.inputs.nixCats.url = "github:BirdeeHub/nixCats-nvim";
  flake-file.inputs.neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  flake-file.inputs.oxy2dev-nvim-scripts = { url = "github:OXY2DEV/nvim"; flake = false; };
  flake-file.inputs.plugins-cmp-dbee = { url = "github:MattiasMTS/cmp-dbee"; flake = false; };
  flake-file.inputs.plugins-gx-nvim = { url = "github:chrishrb/gx.nvim"; flake = false; };
  flake-file.inputs.plugins-maximize-nvim = { url = "github:declancm/maximize.nvim"; flake = false; };
  flake-file.inputs.plugins-nvim-dap-view = { url = "github:igorlfs/nvim-dap-view"; flake = false; };
  flake-file.inputs.plugins-webify-nvim = { url = "github:pabloariasal/webify.nvim"; flake = false; };
  flake-file.inputs.plugins-templ-goto-definition = { url = "github:catgoose/templ-goto-definition"; flake = false; };
  flake-file.inputs.plugins-tiny-code-actions = { url = "github:rachartier/tiny-code-action.nvim"; flake = false; };
  flake-file.inputs.plugins-cmp-go-deep = { url = "github:samiulsami/cmp-go-deep"; flake = false; };
  flake-file.inputs.plugins-inline-edit = { url = "github:AndrewRadev/inline_edit.vim"; flake = false; };
  flake-file.inputs.fenix = {
    url = "github:nix-community/fenix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  # ... neovim config ...
}
```

**Step 3 — Regenerate `flake.nix`:**

```bash
nix run .#write-flake
```

The generated `flake.nix` starts with `# DO-NOT-EDIT` — never edit it manually.

**Validation:**
```bash
nix flake check
nix build .#nixosConfigurations.framework.config.system.build.toplevel --dry-run
nix build .#homeConfigurations."haseebmajid@dell".activationPackage --dry-run
```

---

## Part 10 — Final Directory Structure

After all phases are complete:

```
nixicle/
  flake.nix                        ← ~10 lines: evalModules → config.flake

  modules/
    den.nix                        ← host/home declarations, namespace, den.default, den.schema.host
    flake-outputs.nix              ← packages, devShells, deploy, checks, topology, iso

    aspects/
      roles/
        common.nix                 ← Simple Aspect
        desktop.nix                ← Multi-Context + provides (niri, greetd)
        gaming.nix                 ← Multi-Context + provides (replays, gamescope, performance)
        development.nix            ← Multi-Context
        social.nix                 ← Simple/Multi-Context
        performance.nix            ← Tiered (base / responsive / max)
        nfs-truenas.nix            ← DRY: shared across framebox + workstation
        desktop-addons/            ← alternative layout for provides as separate files
          niri.nix   greetd.nix   hyprland.nix   xdg-portal.nix

      services/                    ← Simple Aspects, one per service
        immich.nix   authentik.nix   traefik.nix   tailscale.nix
        attic.nix    cloudflare.nix  monitoring.nix ollama.nix
        postgresql.nix  redis.nix    btrbk.nix      gitea.nix
        gitlab-runner.nix  karakeep.nix  open-webui.nix  paperless.nix
        tangled.nix  tandoor.nix  crowdsec.nix  goroutinely.nix

      programs/                    ← Program aspects grouped by category
        cli.nix                    ← shells, prompts, CLI tools (fish, atuin, starship, direnv)
        editors.nix                ← nixcats, helix, etc.
        terminals.nix              ← zellij, ghostty, etc.
        security.nix               ← sops, gpg, ssh keys

      hosts/                       ← Collector Aspects
        framework.nix   framebox.nix   workstation.nix
        vm.nix          vps.nix

    profiles/                      ← Composable role bundles (Sharparam pattern)
      homelab.nix                  ← includes: services/* + nfs-truenas
      laptop.nix                   ← includes: desktop + performance/responsive

    users/
      schema.nix             ← den.schema.user + den.schema.home (typed identity)
      haseeb/
        base.nix             ← Simple Aspect (shared across all haseeb instances)
        framework.nix        ← Inheritance Aspect (laptop)
        framebox.nix         ← Inheritance Aspect (homelab)
        workstation.nix      ← Inheritance Aspect (desktop)
        vm.nix               ← Inheritance Aspect (minimal)
      nixos/
        vps.nix              ← Simple Aspect (headless)

    homes/                         ← Standalone HM homes (Sharparam pattern)
      haseebmajid@dell/
        module.nix           ← Inline home declaration + aspect

    secrets/
      lib.nix                  ← tag-based user secret registry (Moortu pattern)

  hosts/                           ← hardware only — not feature modules
    framework/   framebox/   workstation/   vm/   vps/
    (disks.nix, facter.json, hardware-configuration.nix, secrets.yaml)

  lib/       packages/   infra/   topology/    ← unchanged
```

---

## Part 10.5 — Greenfield Migration: What Was Actually Done

This section records the greenfield approach taken for the `den-migration`
branch (framework + VM scope only). It supersedes the incremental plan in
Part 9 for these two hosts.

### What was done

**Phase 1 — Scaffold**
- All existing config moved to `old/`; `modules/` created fresh
- `flake.nix` replaced with thin `evalModules` evaluator
- `modules/den.nix`: host declarations, schema, default imports
- `modules/legacy.nix`: import-tree bridge loading `old/modules/nixos` and
  `old/modules/home` so all existing option namespaces still work
- `modules/flake-outputs.nix`: packages, devShells, deploy, checks, topology

**Phase 2 — Host aspects** (`modules/aspects/hosts/`)
- `framework.nix`: hardware imports, sops secrets, impermanence, secure boot
- `vm.nix`: QEMU/spice, impermanence, boot config

**Phase 3 — User aspects + typed schema** (`modules/users/`)
- `schema.nix`: `den.schema.user` with email, signingKey, authorizedKeys defaults
- `haseeb/base.nix`: parametric includes for SSH authorizedKeys and git identity
  from schema; static HM config for gtk + git signing format
- `haseeb/framework.nix`: `provides.framework` sub-aspect with HM home dirs,
  stateVersion 24.05
- `haseeb/vm.nix`: `provides.vm` sub-aspect with stateVersion 23.11

**Phase 4 — Profile aspects** (`modules/aspects/profiles/`, `modules/aspects/`)
- `common.nix`, `desktop.nix`, `development.nix`, `gaming.nix`, `social.nix`:
  den aspects with actual NixOS + HM config inline (no `roles.*` option layer)
- `desktop` chains `common → development → niri` via includes
- `niri.nix`: niri WM setup + greetd + nautilus/portal config; greetd autologin
  driven by `host.autologin` schema field (default true, false for framework)

### Key decisions made

**Greenfield over incremental.** All existing files moved to `old/` and loaded
via import-tree bridge. New aspects run alongside old code with zero risk.

**`den.homes` for NixOS hosts is an anti-pattern.** `den.homes."haseeb@framework"`
is redundant when `den.hosts.framework.users.haseeb` already exists — den
generates the embedded HM config from the host declaration. Standalone homes
are only for non-NixOS machines (e.g. a Fedora laptop). Declaring both creates
a broken standalone build because the old module bridge has NixOS-only
dependencies (`lib.nixicle`, old modules using `inputs` in `imports`) that
don't work in a bare HM context.

**Old modules using `inputs` in HM `imports` break standalone builds.** The
neovim module does `imports = [ inputs.nixCats.homeModule ]`. `inputs` comes
from `_module.args`, which is evaluated after imports — infinite recursion. The
fix for standalone builds is to pass `inputs` via `extraSpecialArgs` using the
`den.homes.*.instantiate` override, not via `_module.args`. But old modules
also use `lib.nixicle` (which is only extended in NixOS builds via
`mkInstantiate`), so standalone HM remains blocked until those modules are
migrated off the old bridge.

**`homeManager = { user, ... }:` does not receive den's `user` context.** The
`homeManager` owned config in an aspect is forwarded into the NixOS HM module
system where `user` is not a module arg. Use `includes` with
`({ user, ... }: { nixos.home-manager.users.haseeb.* = ...; })` instead, with
`lib.mkForce` to win over any hardcoded values in old bridge modules.

**`lib.nixicle` helpers are an anti-pattern in den.** `mkOpt`, `mkBoolOpt`,
`enabled`, `disabled` etc. exist solely to support the old `options +
mkIf cfg.enable` pattern — the very pattern den eliminates. In den aspects
there are no `options` declarations and no `mkIf`, so these helpers have no
place. Never use `lib.nixicle` in new den module code. The 64 old HM modules
in `old/` that use it are fine to leave untouched; they will be deleted as
each is replaced by a den aspect. Do not refactor them — they are already
slated for removal.

**Host aspects do not propagate `homeManager` to users.** When a host aspect
includes a multi-context aspect (one with both `nixos` and `homeManager`
settings), den only applies the `nixos` portion at host level. The
`homeManager` portion is silently ignored — it is not forwarded to any user's
HM config. For HM config to reach a user, the aspect must be included via a
**user aspect** (e.g. `den.aspects.haseeb.provides.framework`). Host aspects
should only contain NixOS config (hardware, boot, secrets, hostname) and
optionally `provides.to-users` for config that must be pushed to all users
from the host side.

**No what-not-why comments.** See Part 6.

---

## Part 11 — Migration Checklist

### Current State (as of 2026-04-06)

All 6 configs evaluate cleanly: `vm`, `framework`, `framebox`, `workstation`, `vps` (NixOS), `haseebmajid@dell` (standalone HM).

**Repo structure:**
```
hosts/
  dell/default.nix        ← haseebmajid standalone home aspect
  framebox/default.nix    ← den.aspects.haseeb base + provides.framebox + den.aspects.framebox
  framework/default.nix   ← den.aspects.haseeb.provides.framework + den.aspects.framework
  workstation/default.nix ← den.aspects.haseeb.provides.workstation + den.aspects.workstation
  vm/default.nix          ← den.aspects.haseeb.provides.vm + den.aspects.vm
  vps/default.nix         ← den.aspects.vps
modules/
  den.nix                 ← flake entry: hosts, homes, schemas, ctx pipelines
  legacy.nix              ← HM bridge (nfsm input + den.default.homeManager import-tree + ctx)
  flake-outputs.nix       ← packages, devShells, deploy, topology, iso
  aspects/
    ai/                   ← claude-code, opencode, gsd — fully migrated
    neovim/               ← nixCats-based neovim — fully migrated
    profiles/             ← common, desktop, gaming, development, social, video, gamedev, non-nixos
    services/             ← all framebox services (~20 files)
    niri.nix, boot.nix, impermanence.nix, audio.nix, tailscale.nix, kvm.nix, nfs.nix, stylix.nix
old/modules/
  home/                   ← 41 modules still loaded via legacy.nix bridge (down from 76)
  nixos/                  ← DELETED
flake.nix                 ← DO-NOT-EDIT (auto-generated by write-flake)
```

**Migrated so far (2026-04-06):**
- `modules/aspects/neovim/` — full nixCats neovim aspect (files moved from old/modules/home/cli/editors/neovim/)
- `modules/aspects/ai/` — claude-code, opencode, GSD (was empty placeholder + 3 old modules)
- `development.nix` — inlined 20+ trivial CLI tool modules (atuin, bat, bottom, direnv, eza, fzf, gsesh, htop, nix-index, starship, yazi, zoxide, core-tools, development-tools, homelab, tui, network-tools, docker)
- `common.nix` — inlined foot, ghostty, zk, k8s tools, guis/nautilus, removed core-tools ref
- `desktop.nix` — inlined XDG config, removed dead spotify option

**What's remaining in old/modules/home/ (41 files):**
- `browsers/firefox` — uses `host` arg; keep until den passes host to HM ctx
- `cli/multiplexers/tmux, zellij` — complex (zellij has layouts/plugins)
- `cli/shells/fish, zsh` — complex; fish uses `host` arg
- `cli/terminals/alacritty, kitty, wezterm` — simple but unused? check
- `cli/tools/attic` — sops secrets; keep until secrets migration
- `cli/tools/envoluntary` — per-host config option (used in dell)
- `cli/tools/git` — per-host options (email, allowedSigners)
- `cli/tools/gpg` — complex (agent, keyring)
- `cli/tools/ssh` — per-host options (enableKeychain)
- `desktops/addons/*` (22 files) — desktop addons (swayidle, waybar, noctalia, etc.)
- `desktops/niri` — HM niri config (NixOS side already migrated to aspects/niri.nix)
- `desktops/hyprland` — hyprland HM config (probably unused on current hosts)
- `development/android, podman` — simple
- `services/kdeconnect, syncthing` — simple

**What's needed before legacy.nix can be deleted:**
1. Migrate all 41 remaining old/modules/home/ files to aspects/inline
2. Remove all old-style option references (`desktops.*`, `cli.shells.*`, etc.) from profile aspects and host files

**What's remaining (priority order):**
1. **Desktop addons + niri HM** — biggest remaining category (22+ files)
2. **Fish shell** — complex, needs `host` passthrough in den ctx or inline with `config.networking.hostName`
3. **Firefox** — same `host` issue; likely inline with known hostname pattern
4. **Git/SSH** — per-host options; consider moving to den schema
5. **Zellij** — complex multiplexer with layouts
6. **Attic** — sops secrets path needs updating
7. **Final cleanup** — delete legacy.nix and old/ once all above done
8. **Optional** — `den.schema.user` typed identity, `modules/secrets/lib.nix` tag-based registry



### Phase 1 — Host Declaration + Schemas
- [x] Expand `modules/den.nix` with all 5 NixOS hosts (dell moves to `modules/homes/`)
- [x] Add `_module.args.__findFile = den.lib.__findFile` (enables `<angle/bracket>` syntax)
- [x] Add `den.ctx.user.includes = [den._.mutual-provider]` (enables provides.to-users)
- [x] Add `den.default` with `<den/define-user>`, `<den/hostname>`, stateVersion
- [x] Add shared framework imports to `den.default.nixos` (disko, sops, niri, stylix, facter)
- [x] Add `den.schema.host` with `isLaptop`, `primaryDisplay.*`
- [ ] Add `den.schema.user` with `classes`, email, signingKey, authorizedKeys (typed identity)
- [ ] Add `den.schema.home` mirroring user schema for standalone homes
- [ ] Create `modules/users/schema.nix` with typed user identity defaults
- [x] Set `primaryDisplay` and `isLaptop` on framework and workstation
- [x] Verify `modules/legacy.nix` import-tree bridge is intact
- [x] `nix flake check` passes

### Phase 2 — flake.nix Simplification
- [x] Create `modules/flake-outputs.nix` (packages, devShells, deploy, checks, topology, iso)
- [x] Replace `flake.nix` with thin `evalModules` evaluator
- [x] Add `den`, `import-tree`, and optionally `flake-file` to inputs
- [x] Delete `mkSystem`, `mkHome`, `mkHomeModule` helpers
- [x] `nixos-rebuild build --flake .#framework`
- [x] `nixos-rebuild build --flake .#framebox`
- [x] `home-manager build --flake .#"haseeb@framework"`
- [x] `home-manager build --flake .#"haseebmajid@dell"`

### Phase 3 — User Aspects + Standalone Homes
- [x] `hosts/framebox/default.nix` contains `den.aspects.haseeb` base + `den.aspects.haseeb.provides.framebox`
- [x] `hosts/framework/default.nix` contains `den.aspects.haseeb.provides.framework`
- [x] `hosts/workstation/default.nix` contains `den.aspects.haseeb.provides.workstation`
- [x] `hosts/vm/default.nix` contains `den.aspects.haseeb.provides.vm`
- [x] `hosts/dell/default.nix` → `den.aspects.haseebmajid.provides.dell` standalone home
- [x] `hosts/vps/default.nix` (NixOS-only, no user HM)
- [x] `modules/users/` folder deleted — all user aspects inlined into host files
- [ ] Create `modules/secrets/lib.nix` (tag-based user secret registry, Moortu pattern)
- [ ] Wire `aspect` keys in `den.hosts`

### Phase 4 — Role + Program Aspects
- [x] `modules/aspects/profiles/common.nix`
- [x] `modules/aspects/profiles/desktop.nix` (Multi-Context + includes niri aspect)
- [x] `modules/aspects/profiles/gaming.nix` (Multi-Context)
- [x] `modules/aspects/profiles/development.nix`
- [x] `modules/aspects/profiles/social.nix`
- [x] `modules/aspects/profiles/video.nix`
- [x] `modules/aspects/profiles/gamedev.nix`
- [x] `modules/aspects/profiles/non-nixos.nix` (nixGL, xwayland-satellite, dell standalone home)
- [x] `modules/aspects/niri.nix` (greetd, polkit, xdg-portal, niri NixOS module)
- [ ] `modules/aspects/performance.nix` (Tiered: base / responsive / max)
- [ ] `modules/aspects/nfs-truenas.nix` (DRY)
- [x] Delete old `old/modules/nixos/roles/desktop/addons/niri/`
- [x] Delete old `old/modules/nixos/security/firewall/`, `polkit/`
- [x] Delete old `old/modules/nixos/services/evolution/`, `tailscale/`, `virtualisation/`

### Phase 5 — Service Aspects
- [x] `modules/aspects/services/monitoring.nix` (prometheus, grafana, loki, tempo, alertmanager — all inlined)
- [x] `modules/aspects/services/vpn.nix`
- [x] `modules/aspects/services/traefik.nix`
- [x] `modules/aspects/services/postgres.nix`
- [x] `modules/aspects/services/redis.nix`
- [x] `modules/aspects/services/authentik.nix`
- [x] `modules/aspects/services/otel.nix`
- [x] `modules/aspects/services/tangled.nix`
- [x] `modules/aspects/services/goroutinely.nix`
- [x] `modules/aspects/services/banterbus.nix`
- [x] `modules/aspects/services/nixery.nix`
- [x] `modules/aspects/services/nixflix.nix`
- [x] `modules/aspects/hosts/framebox.nix` (Collector Aspect)
- [x] `modules/aspects/hosts/framework.nix` (Collector Aspect)
- [x] `modules/aspects/hosts/workstation.nix` (Collector Aspect)
- [x] `modules/aspects/hosts/vm.nix` (Collector Aspect)
- [x] `modules/aspects/hosts/vps.nix` (Collector Aspect)
- [ ] Wire `den.hosts.*.aspect` in `modules/den.nix` (hosts still use nixos modules directly)
- [x] Migrate/delete all `old/modules/nixos/` — fully deleted
- [x] pcr-verification inlined into `hosts/framework/default.nix`
- [x] Remove nixos bridge from `modules/legacy.nix`

### Phase 6 — flake-file
- [x] Add `flake-file` to flake inputs
- [x] Move input declarations from `flake.nix` into the module files that use them (via `flake-file.inputs.*`)
- [ ] Add remaining inputs: nixCats, neovim plugins, hyprland, nixflix, comma, fenix, opencode, nix-playwright-mcp, zellij-mcp, omerxx-dotfiles
- [ ] Run `nix run .#write-flake` to auto-generate `flake.nix` (replaces hand-written file)
- [ ] Verify `nix flake check` passes with generated `flake.nix`
- [ ] Commit the auto-generated `flake.nix`
### Final Cleanup
- [ ] Delete `modules/legacy.nix` (import-tree bridge no longer needed)
- [ ] Delete `old/modules/nixos/` and `old/modules/home/` trees
- [ ] Final `nix flake check` across all hosts
- [ ] Final `nix build .#nixosConfigurations.framebox.config.system.build.toplevel`

---

## Part 12 — Key Den Patterns to Know

### Cross-platform user (haseebmajid on dell)

```nix
den.aspects.haseebmajid-dell = {
  # nixos class silently skipped — dell is { home } context, not { host, user }
  nixos       = { ... };   # ← Den[^1] skips this automatically
  homeManager = { ... };   # ← only this applies
};
```

### Mutual providers (host ↔ user config)

Workstation has a `media` group that affects `haseeb`. Use `provides.to-users`[^13]:

```nix
den.aspects.workstation.provides.to-users = {
  nixos = { ... }: { users.users.haseeb.extraGroups = [ "media" ]; };
};
```

### Typed host metadata via `den.schema`

```nix
# Declared on host, read by any aspect — no hard-coding
den.hosts.x86_64-linux.framework.isLaptop = true;

den.aspects.power-management = { host, ... }: {
  nixos = lib.optionalAttrs host.isLaptop { services.tlp.enable = true; };
};
```

### Guarded forwarding (conditional class application)[^14]

```nix
persys = { host }: den._.forward {
  each       = lib.singleton true;
  fromClass  = _: "persys";
  intoClass  = _: host.class;
  intoPath   = _: [ "environment" "persistence" "/nix/persist/system" ];
  fromAspect = _: den.aspects.${host.aspect};
  guard      = { options, ... }: _: options ? environment.persistence;
};

den.ctx.host.includes = [ persys ];

# Aspects just use persys class directly — no conditional required:
den.aspects.framework.persys.hideMounts = true;
```

---

## Part 13 — Quick Reference: Before / After

### Host declaration

**Before:**
```nix
nixosConfigurations.framework = mkSystem {
  hostname = "framework";
  extraModules = [ (mkHomeModule { username = "haseeb"; hostname = "framework"; }) ];
};
```

**After:**
```nix
den.hosts.x86_64-linux.framework.users.haseeb = { aspect = "haseeb-framework"; };
# Den[^1] auto-generates nixosConfigurations.framework
```

### Cross-cutting feature (impermanence)

**Before:** 3 files — `flake.nix` input, `hosts/framework/default.nix` NixOS
side, `hosts/framework/home.nix` HM side.

**After:** 1 file — `modules/aspects/impermanence.nix` with `nixos` and
`homeManager` keys side by side.

### Non-NixOS standalone home (dell/Fedora)

**Before:**
```nix
homeConfigurations."haseebmajid@dell" = mkHome {
  username = "haseebmajid"; hostname = "dell";
};
```

**After:**
```nix
den.homes.x86_64-linux."haseebmajid@dell" = { aspect = "haseebmajid-dell"; };
# nixos class in the aspect is silently skipped — no mkIf needed
```

### Gamescope with host-typed resolution

**Before:** Hard-coded in each host's config.

**After:**
```nix
# Declared once on the host in den.schema.host
den.hosts.x86_64-linux.framework.primaryDisplay = {
  name = "eDP-1"; width = 2256; height = 1504; refresh = 120;
};
# Aspect reads it — works for every host automatically
```

### Reusing a service on a second server

**Before:** Copy-paste service config. Keep in sync manually.

**After:**
```nix
den.aspects.server2.includes = [ den.aspects.immich ];
```

---

## Footnotes

[^1]: **Den** — Aspect-oriented, context-driven Dendritic Nix configurations.
      Source: <https://github.com/vic/den>
      Docs: <https://den.oeiuwq.com>

[^2]: **Doc-Steve's Dendritic Design Guide** — Framework-agnostic pattern
      reference including FAQ, advantages/drawbacks, and 8 aspect patterns.
      <https://github.com/Doc-Steve/dendritic-design-with-flake-parts/wiki>

[^3]: **import-tree battery** — Den's bridge for loading plain NixOS/HM modules
      unchanged into the Den context pipeline.
      <https://den.oeiuwq.com/guides/batteries/>

[^4]: **Den Core Principles** — Aspects, classes, provides, includes, schema.
      <https://den.oeiuwq.com/explanation/core-principles/>

[^5]: **Parametric dispatch** — How Den uses `builtins.functionArgs` to
      conditionally apply aspect configs based on context shape.
      <https://den.oeiuwq.com/explanation/parametric/>

[^6]: **Context pipeline** — How Den traverses hosts → users → homes and
      applies aspect configs at each stage.
      <https://den.oeiuwq.com/explanation/context-pipeline/>

[^7]: **Batteries** — Den's built-in reusable aspects (define-user, hostname,
      primary-user, user-shell, import-tree, etc.).
      <https://den.oeiuwq.com/guides/batteries/>

[^8]: **Den namespaces** — Scoping aspects under a project-specific name.
      <https://den.oeiuwq.com/guides/namespaces/>

[^9]: **Angle brackets** — `<den/battery>` syntax for readable include lists.
      <https://den.oeiuwq.com/guides/angle-brackets/>

[^10]: **quasigod/nixconfig** — Real-world Den config using namespaces, typed
       host schema, tiered performance aspects, GPU screen recorder service.
       <https://tangled.org/quasigod.xyz/nixconfig>

[^11]: **Sharparam/nix-config** — Real-world Den + flake-file + Darwin config.
       Notable patterns: typed `den.schema.user`/`den.schema.home`, inline
       home+aspect declaration, per-tool `base/` granularity, profile aspects,
       angle-bracket-only includes, `FLAKE_CONFIG_URI` session variable.
       <https://github.com/Sharparam/nix-config>

[^12]: **flake-file** — Auto-generates `flake.nix` from a module, moving input
       declarations into the module tree.
       <https://github.com/vic/flake-file>

[^13]: **Mutual providers** — Den pattern for bidirectional host ↔ user config.
       <https://den.oeiuwq.com/guides/mutual/>

[^14]: **Custom classes and guarded forwarding** — Den's mechanism for
       conditional class application without `mkIf` scattered everywhere.
       <https://den.oeiuwq.com/guides/custom-classes/>

[^15]: **Moortu/dotfiles** — Real-world Den config with stylix, niri, sops-nix,
       lanzaboote, disko. Notable patterns: `flake.modules.nixos.*` named module
       registry, `provides.to-users` for per-host display config, tag-based SOPS
       secret registry, `den.default.nixos` for global shared imports, composable
       profiles via named modules, multi-user support (moortu + kris).
       <https://codeberg.org/Moortu/dotfiles>
