#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"

source ./zload.zsh

# Create mock repository
SRC_DIR="$SANDBOX/pkg_src"
BARE_DIR="$SANDBOX/pkg.git"
mkdir -p "$SRC_DIR"
git -C "$SRC_DIR" init -q -b main
git -C "$SRC_DIR" config user.email "test@zload.test"
git -C "$SRC_DIR" config user.name "Zload Test"

echo 'export VER=1' > "$SRC_DIR/pkg.plugin.zsh"
git -C "$SRC_DIR" add .
git -C "$SRC_DIR" commit -q -m "commit 1"
COMMIT_1="$(git -C "$SRC_DIR" rev-parse HEAD)"

git clone --bare -q "$SRC_DIR" "$BARE_DIR"

# Install plugin
zload "file://$BARE_DIR"

# 1. Generate lockfile
LOCK_FILE="$SANDBOX/custom.lock"
zload lock "$LOCK_FILE"

[[ -f "$LOCK_FILE" ]] || { echo "FAIL: lockfile not created"; exit 1; }
grep -Fq "$COMMIT_1" "$LOCK_FILE" || { echo "FAIL: commit 1 missing from lockfile"; exit 1; }

# 2. Advance remote commit and pull update
echo 'export VER=2' > "$SRC_DIR/pkg.plugin.zsh"
git -C "$SRC_DIR" commit -q -am "commit 2"
git -C "$SRC_DIR" push -q "$BARE_DIR" main
COMMIT_2="$(git -C "$SRC_DIR" rev-parse HEAD)"

zload update >/dev/null

local -A parsed
_zload_parse_spec parsed "file://$BARE_DIR"
INSTALLED_DIR="${parsed[dir]}"

CURR_COMMIT="$(git -C "$INSTALLED_DIR" rev-parse HEAD)"
[[ "$CURR_COMMIT" == "$COMMIT_2" ]] || { echo "FAIL: update did not advance to commit 2"; exit 1; }

# 3. Synchronize from lockfile back to locked commit 1
zload sync "$LOCK_FILE" >/dev/null

RESTORED_COMMIT="$(git -C "$INSTALLED_DIR" rev-parse HEAD)"
[[ "$RESTORED_COMMIT" == "$COMMIT_1" ]] || {
  echo "FAIL: sync did not restore to locked commit 1 ($RESTORED_COMMIT != $COMMIT_1)"
  exit 1
}

echo "PASS: test_lock (reproducible lockfile generation and sync verification)"
