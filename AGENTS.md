# AGENTS.md

## Task commands

Prefer the repository Taskfile for routine operations:

```sh
task --list
task hosts
task build HOST=framework
task check
task fmt
task lint
task write-flake
```

`task build` defaults to the current hostname, builds without activation, and
writes a `result-<host>` symlink. It does not update flake inputs.

`task rebuild` interactively selects a host, rsyncs the working tree to
`haseeb@<host>:~/nixicle`, and runs `sudo nh os switch` over SSH. It activates
system and Home Manager changes; it is not a local build-only command.
Use it only when activation is requested and SSH access is available.
`task deploy` uses deploy-rs; use it only when explicitly requested.
Do not restart a running TUIOS daemon or its panes without explicit approval.

## OpenTofu deployment

Use the Taskfile from the repository root:

```sh
task tofu:init
task tofu:validate
task tofu:plan
task tofu:apply
task tofu:import ADDRESS='pocketid_client.app["grafana"]' ID=grafana
```

`task tofu:init` runs `glab opentofu init -R hmajid2301/nixicle default -- -reconfigure`
in `infra/opentofu`. Authenticate with `glab` first. Override `GITLAB_PROJECT`
or `STATE` only when intentionally targeting a different backend.
Plan, apply, and import initialize the same GitLab backend automatically.
Do not use a fresh local state as a substitute for the GitLab-managed state.

Use `infra/opentofu/terraform.tfvars.example` as the template for the ignored
`terraform.tfvars`; never commit credentials, state, or plan files or print secrets.
`task tofu:validate` removes the local `.terraform` directory and initializes
without backend access; it does not validate live infrastructure or replace a plan.
Review `task tofu:plan` before applying. Apply and import change infrastructure
or state and require explicit approval; never add `-auto-approve` by default.
The apply task generates a new plan rather than applying a saved plan file.

## deploy-rs deployment

```sh
task build HOST=vps
task check
task deploy
```

`task deploy` prompts for the host, SSH user, check skipping, and remote build,
then asks for confirmation before invoking deploy-rs. Confirm the target and
SSH user before proceeding; keep deployment checks enabled unless explicitly
approved otherwise. The flake configures VPS SSH access as `nixos` with system
activation as `root`; the task's SSH-user prompt defaults to `root`, so choose
`nixos` for VPS deployments. Deployment activates the system, not just a build.
Only deploy when explicitly requested, and verify the affected services afterward.

## Nix checks

Before committing, run the same checks as the pre-commit hooks
(`deadnix`, `nixfmt`, `statix`). Tools come from the flake devshell:

```sh
nix develop -c bash -c '
  files=$(git ls-files "*.nix")
  deadnix --fail $files
  nixfmt --check $files
  statix check .
'
```

(`git ls-files` scopes the formatters to tracked files; a bare `nixfmt .`
also walks `.direnv/flake-inputs/` vendored inputs and fails on those.)

Fix in place when they fail:

```sh
nix develop -c bash -c '
  files=$(git ls-files "*.nix")
  deadnix --edit $files
  nixfmt $files
  statix fix .
'
```

Pre-commit runs these on staged `.nix` files and will refuse the commit on
failure, so fixing first avoids a re-stage loop.

## Commits

- Title line only, conventional-commit style (`fix(scope): ...`,
  `refactor(scope): ...`, `style(nix): ...`, `chore(...)`).
- Keep each commit atomic: one logical change, repo still evals.

## Comments

Strongly prefer no comments. Only add one when it is absolutely necessary to
explain something the code cannot express on its own.

## Validation

Prefer evaluating affected hosts before pushing:

```sh
nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath
```

Deploy with deploy-rs only when asked.
