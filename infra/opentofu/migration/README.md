# OIDC config migration: hand-written JSON → HCL with `for_each`

> **Status: EXECUTED 2026-09-20.** All 17 `state mv` operations ran successfully against the GitLab-managed backend (`glab opentofu init -R hmajid2301/nixicle default -- --reconfigure`). State went from 43 to 43 instances; the 13 clients are now `pocketid_client.app["<app>"]` and the 4 stored secrets `vault_kv_secret_v2.oidc["<app>"]`; no old addresses remain. `tofu plan` reports **0 to add, 0 to destroy**.
>
> The only planned changes are pre-existing drift that the old JSON config declared identically: 3 Gandi TXT records (provider quoting) and 2 Pocket ID clients (`grafana` group *ordering* only; `hister` wants `allowed_user_groups = []`). Nothing was applied.

`main.tf.json` (hand-written JSON) is replaced by `migration/oidc.tf` (HCL), collapsing **13 duplicated `pocketid_client` blocks** into one `for_each` resource and **4 `vault_kv_secret_v2` blocks** into another.

This is a **state-preserving** change: every Pocket ID client keeps its id/secret, provided the `state mv` steps below are run. If they are skipped, OpenTofu will plan to destroy and recreate clients — which would change every service's client id and secret.

`pocketid_group`, `pocketid_user`, `vault_mount` and the `pocketid_group.family` data source keep their addresses and need no moves. Outputs keep their names.

## Preconditions

- Backend credentials available (`task tofu:init` works today) and `infra/opentofu/terraform.tfvars` present.
- You are at `infra/opentofu`.
- Do **not** run `apply` during this migration.

## Steps

```sh
cd infra/opentofu

# 1. Snapshot state for comparison.
tofu state list | sort > /tmp/state-before.txt

# 2. Swap the config: HCL in, JSON out.
mv migration/oidc.tf main.tf
git rm main.tf.json

# 3. Re-initialise (new file, same providers/backend).
tofu init

# 4. Move every renamed resource. Each is a no-op for the real resource.
tofu state mv 'pocketid_client.goroutinely' 'pocketid_client.app["goroutinely"]'
tofu state mv 'pocketid_client.gotify' 'pocketid_client.app["gotify"]'
tofu state mv 'pocketid_client.gothreads' 'pocketid_client.app["gothreads"]'
tofu state mv 'pocketid_client.grafana' 'pocketid_client.app["grafana"]'
tofu state mv 'pocketid_client.hister' 'pocketid_client.app["hister"]'
tofu state mv 'pocketid_client.immich' 'pocketid_client.app["immich"]'
tofu state mv 'pocketid_client.jellyfin' 'pocketid_client.app["jellyfin"]'
tofu state mv 'pocketid_client.karakeep' 'pocketid_client.app["karakeep"]'
tofu state mv 'pocketid_client.lettucego' 'pocketid_client.app["lettucego"]'
tofu state mv 'pocketid_client.papra' 'pocketid_client.app["papra"]'
tofu state mv 'pocketid_client.sure' 'pocketid_client.app["sure"]'
tofu state mv 'pocketid_client.tandoor' 'pocketid_client.app["tandoor"]'
tofu state mv 'pocketid_client.tinyauth' 'pocketid_client.app["tinyauth"]'
tofu state mv 'vault_kv_secret_v2.goroutinely_oidc' 'vault_kv_secret_v2.oidc["goroutinely"]'
tofu state mv 'vault_kv_secret_v2.gothreads_oidc' 'vault_kv_secret_v2.oidc["gothreads"]'
tofu state mv 'vault_kv_secret_v2.immich_oidc' 'vault_kv_secret_v2.oidc["immich"]'
tofu state mv 'vault_kv_secret_v2.lettucego_oidc' 'vault_kv_secret_v2.oidc["lettucego"]'

# 5. Expect NO changes. Anything else means a move was missed.
tofu plan -var-file=terraform.tfvars

# 6. Compare the instance lists: same set of resources, new addresses.
tofu state list | sort > /tmp/state-after.txt
wc -l /tmp/state-before.txt /tmp/state-after.txt

# 7. Only once plan is clean:
git add main.tf main.tf.json migration
git commit -m "refactor(opentofu): replace hand-written oidc json with hcl for_each"
```

## If `tofu plan` proposes destroy/create

A `state mv` was missed or mistyped. Inspect:

```sh
tofu state list | grep pocketid_client
tofu state list | grep vault_kv_secret_v2
```

Every instance must use the new form (`pocketid_client.app["<app>"]`, `vault_kv_secret_v2.oidc["<app>"]`). Move any stragglers, then re-plan. `state mv` is reversible — move the address back and re-plan if needed.

## Rollback (before any apply)

```sh
git checkout infra/opentofu/main.tf.json
git rm infra/opentofu/main.tf        # or: mv main.tf migration/oidc.tf
tofu plan -var-file=terraform.tfvars  # must be clean again
```

Nothing was applied, so no cloud-side rollback is involved.

## Optional follow-ups

- `tasks/tofu.yml` has an `import` example using the old address form (`pocketid_client.grafana`); update it to `'pocketid_client.app["grafana"]'` after migrating.
- Domain literals inside `migration/oidc.tf` (`haseebmajid.dev`) are still hand-written; ticket 009's single-sourcing intent would need a variable or generation step.
