# AGENTS.md

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

## Validation

Prefer evaluating affected hosts before pushing:

```sh
nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath
```

Deploy with deploy-rs only when asked.
