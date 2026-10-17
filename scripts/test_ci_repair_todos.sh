#!/usr/bin/env bash
set -euo pipefail

scripts="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
helper="$scripts/ci-repair-todos.sh"
temp="$(mktemp -d)"
trap 'rm -rf -- "$temp"' EXIT
mkdir "$temp/bin" "$temp/repo"
export PATH="$temp/bin:$PATH"
export MERGED=true STATUS=ahead BUILD_FAIL=false API_FAIL=false
cat > "$temp/bin/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[ "$API_FAIL" = false ] || exit 22
case "${*: -1}" in
  */pulls/569851) printf '{"merged":%s,"merge_commit_sha":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}\n' "$MERGED" ;;
  */compare/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa...bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb)
    printf '{"status":"%s"}\n' "$STATUS" ;;
  *) exit 1 ;;
esac
EOF
cat > "$temp/bin/nix" <<'EOF'
#!/usr/bin/env bash
[ "$BUILD_FAIL" = false ]
EOF
chmod +x "$temp/bin/"*
cd "$temp/repo"
git init -q
cat > host.nix <<'EOF'
{ pkgs, ... }: { home.packages = with pkgs; [
  # TODO(nixpkgs): pr=569851 input=nixpkgs package=semgrep target=homeConfigurations."user@dell".activationPackage
  # semgrep
]; }
EOF
cat > flake.lock <<'EOF'
{"root":"root","nodes":{"root":{"inputs":{"nixpkgs":"nixpkgs_2"}},"nixpkgs_2":{"locked":{"type":"github","owner":"NixOS","repo":"nixpkgs","rev":"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"}}}}
EOF
git add .
git -c user.name=Test -c user.email=test@example.invalid commit -qm fixture
cp host.nix "$temp/original"
sed '/# TODO(nixpkgs):/d;s/# semgrep/semgrep/' host.nix > "$temp/restored"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
reject() { if "$@"; then fail "unexpected acceptance: $*"; fi; }
collect() { bash "$helper" collect > "$temp/candidates.json"; }
empty() { collect; jq -e 'length == 0' "$temp/candidates.json" >/dev/null || fail 'ineligible marker collected'; }
reset_repo() { git reset --hard -q HEAD; }

collect
jq -e 'length == 1 and .[0].file == "host.nix" and .[0].line == 2 and .[0].replacement == "  semgrep\n"' "$temp/candidates.json" >/dev/null || fail 'eligible marker missing'
cmp host.nix "$temp/original"
STATUS=identical collect
jq -e 'length == 1' "$temp/candidates.json" >/dev/null
sed -i 's/NixOS/nixos/' flake.lock
collect
jq -e 'length == 1' "$temp/candidates.json" >/dev/null
reset_repo
MERGED=false empty
STATUS=behind empty
STATUS=diverged empty
BUILD_FAIL=true empty
API_FAIL=true empty
sed -i 's/# semgrep/# other/' host.nix
empty
reset_repo
sed -i 's/  # semgrep/ # semgrep/' host.nix
empty
reset_repo
sed -i 's/"nixpkgs":"nixpkgs_2"/"nixpkgs":["other","nixpkgs"]/' flake.lock
empty
reset_repo
rm host.nix
ln -s "$temp/original" host.nix
empty
reset_repo
cat "$temp/original" >> host.nix
collect
jq -e 'length == 1' "$temp/candidates.json" >/dev/null
reset_repo
git mv host.nix 'host with spaces.nix'
collect
jq -e 'length == 1 and .[0].file == "host with spaces.nix"' "$temp/candidates.json" >/dev/null
reset_repo
truncate -s -1 host.nix
collect
head -c -1 "$temp/restored" > "$temp/no-newline"
cp "$temp/no-newline" host.nix
bash "$helper" validate "$temp/candidates.json"
printf '\n' >> host.nix
reject bash "$helper" validate "$temp/candidates.json"
reset_repo
collect
reject bash "$helper" validate "$temp/candidates.json"
printf '' > "$temp/patch"
reject bash "$helper" check-patch "$temp/candidates.json" "$temp/patch" 2> "$temp/empty-patch.log"
cp "$temp/restored" host.nix
git diff > "$temp/patch"
bash "$helper" check-patch "$temp/candidates.json" "$temp/patch"
bash "$helper" validate "$temp/candidates.json"
BUILD_FAIL=true reject bash "$helper" validate "$temp/candidates.json"
chmod +x host.nix
reject bash "$helper" validate "$temp/candidates.json"
reset_repo
cp "$temp/restored" host.nix
sed -i 's/home.packages/other.packages/' host.nix
reject bash "$helper" validate "$temp/candidates.json"
reset_repo
cp "$temp/restored" host.nix
printf '{}\n' > flake.lock
git diff > "$temp/patch"
reject bash "$helper" check-patch "$temp/candidates.json" "$temp/patch"
reject bash "$helper" validate "$temp/candidates.json"
reset_repo
cp "$temp/restored" host.nix
git diff > "$temp/patch"
cat >> "$temp/patch" <<'EOF'
diff --git a/scripts/ci-repair-todos.sh b/scripts/ci-repair-todos.sh
--- a/scripts/ci-repair-todos.sh
+++ b/scripts/ci-repair-todos.sh
@@ -1 +1 @@
-return 1
+return 0
EOF
reject bash "$helper" check-patch "$temp/candidates.json" "$temp/patch"
reset_repo

mkdir repair
cp "$temp/candidates.json" repair/todo-candidates.json
cp "$temp/restored" host.nix
git diff > repair/repair.patch
reset_repo
sed '/^find_repair_note$/,$d' "$scripts/ci-repair.sh" > "$temp/harness.sh"
cat >> "$temp/harness.sh" <<'EOF'
todo_mode=true
todo_validator="$TEST_HELPER"
confidence="$TEST_CONFIDENCE"
commands_json="$TEST_COMMANDS"
patch="$(<repair/repair.patch)"
commit_and_push_fix() { touch repair/pushed; }
enable_auto_merge() { return 0; }
apply_patch_and_retest
EOF
export REPAIR_GITLAB_TOKEN=test OLLAMA_API_KEY=test TEST_HELPER="$helper"
for TEST_CONFIDENCE in medium low high; do
  export TEST_CONFIDENCE
  export TEST_COMMANDS='[]'
  bash "$temp/harness.sh"
  if [ "$TEST_CONFIDENCE" = high ]; then
    [ -f repair/pushed ] || fail 'approved restoration not pushed'
    cmp host.nix "$temp/restored"
  else
    [ ! -f repair/pushed ] || fail 'unapproved restoration pushed'
    cmp host.nix "$temp/original"
  fi
done
reset_repo
rm repair/pushed
TEST_CONFIDENCE=high TEST_COMMANDS='["nix flake update"]' bash "$temp/harness.sh"
[ ! -f repair/pushed ] || fail 'agent commands accepted'
cmp host.nix "$temp/original"
printf 'PASS: TODO restoration regression tests\n'
