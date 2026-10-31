#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"
export HOME="$SANDBOX/home"
export ZLOAD_NO_COMPINIT=1
mkdir -p "$HOME"

source ./zload.zsh

fail() {
  echo "FAIL: $1"
  exit 1
}

SRC="$SANDBOX/pkg_src"
BARE="$SANDBOX/pkg.git"
mkdir -p "$SRC"
git -C "$SRC" init -q -b main
git -C "$SRC" config user.email t@zload.test
git -C "$SRC" config user.name t
echo 'export VER=1' >"$SRC/pkg.plugin.zsh"
git -C "$SRC" add . && git -C "$SRC" commit -q -m one
C1="$(git -C "$SRC" rev-parse HEAD)"
echo 'export VER=2' >"$SRC/pkg.plugin.zsh"
git -C "$SRC" commit -q -am two
C2="$(git -C "$SRC" rev-parse HEAD)"
git clone --bare -q "$SRC" "$BARE"
# Allow fetching arbitrary commits from the local remote.
git -C "$BARE" config uploadpack.allowAnySHA1InWant true

# Install at the newest commit (shallow), then lock to the OLDER commit.
zload "file://$BARE" >/dev/null 2>&1
NAME="${${(k)_zload_specs}[1]}"
DIR="$(print -l "$ZLOAD_PLUGINS"/*(N/) | grep -v _snippets)"
[[ -d "$DIR/.git" ]] || fail "plugin not installed"
print -l "# zload lockfile" "${DIR:t}:$C1" >"$SANDBOX/old.lock"

# 1. Shallow clone can reach an older commit.
zload sync "$SANDBOX/old.lock" >/dev/null || fail "sync reported failure for a reachable commit"
[[ "$(git -C "$DIR" rev-parse HEAD)" == "$C1" ]] || fail "older commit not checked out on shallow clone"

# 2. An unreachable commit is reported as a failure, not as success.
print -l "# zload lockfile" "${DIR:t}:deadbeefdeadbeefdeadbeefdeadbeefdeadbeef" >"$SANDBOX/bad.lock"
if zload sync "$SANDBOX/bad.lock" >/dev/null 2>&1; then
  fail "sync reported success for a commit that does not exist"
fi

# 3. A locked plugin that is declared but not installed gets installed at the locked commit.
rm -rf "$DIR"
print -l "# zload lockfile" "${DIR:t}:$C1" >"$SANDBOX/old.lock"
zload sync "$SANDBOX/old.lock" >/dev/null || fail "sync of missing plugin failed"
[[ "$(git -C "$DIR" rev-parse HEAD)" == "$C1" ]] || fail "missing plugin not restored to locked commit"

# 4. Path traversal in a lockfile name is rejected.
print -l "# zload lockfile" "../evil:$C1" >"$SANDBOX/evil.lock"
zload sync "$SANDBOX/evil.lock" >/dev/null 2>&1 || true
[[ ! -e "$ZLOAD_PLUGINS/../evil" ]] || fail "lockfile name escaped plugin directory"

echo "PASS: test_sync_shallow (shallow checkout, honest failure, restore missing, name validation)"
