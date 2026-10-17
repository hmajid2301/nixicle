# Upstream-gated package restoration

The repair job checks opt-in TODO markers on green Renovate merge request
pipelines. Failed pipelines keep the existing failure-repair behavior.

Put this marker immediately before a single commented package entry, with
matching indentation:

```nix
# TODO(nixpkgs): pr=569851 input=nixpkgs package=semgrep target=homeConfigurations."haseebmajid@dell".activationPackage
# semgrep
```

Fields, in this order:

- `pr`: the NixOS/nixpkgs pull request number.
- `input`: a direct root flake input locked to GitHub NixOS/nixpkgs.
- `package`: an attribute available in that input's native `legacyPackages`.
- `target`: a repository flake output to build after restoration. Use a Home
  Manager activation package or a NixOS system toplevel that uses the entry.

The bot requires the PR to be merged and the merge commit to be contained in
the locked revision. A merged PR alone is insufficient. The package must build
from that locked input. GitHub API errors, missing inputs, and package build
failures leave the marker unchanged. `GITHUB_TOKEN` or `GH_TOKEN`, when set,
authenticates GitHub API reads.

The existing CI agent receives the verified evidence and complete source. It
must approve the restoration with high confidence. The runner accepts only the
exact marker removal and package uncommenting, builds the affected target, and
runs flake checks before committing and pushing. Existing auto-merge and attempt
limits apply. No new MR is created, and the job does not deploy anything.

At most one eligible marker per file is offered in each pipeline. Ordinary
TODOs, follows aliases, non-GitHub inputs, multiline entries, and other workaround
forms are not processed. For an overlay or a different package set, the target
build is the final check against the actual configuration.

Run the local checks:

```sh
bash scripts/test_ci_repair_todos.sh
bash -n scripts/ci-repair.sh scripts/ci-repair-todos.sh scripts/test_ci_repair_todos.sh
```
