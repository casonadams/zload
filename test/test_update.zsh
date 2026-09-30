#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"

source ./zload.zsh

# Create mock remote
REMOTE_SRC="$SANDBOX/remote-src"
REMOTE_BARE="$SANDBOX/remote.git"
mkdir -p "$REMOTE_SRC"
git -C "$REMOTE_SRC" init -q -b main
git -C "$REMOTE_SRC" config user.email "test@zload.test"
git -C "$REMOTE_SRC" config user.name "Zload Test"

echo 'export VER=1' >"$REMOTE_SRC/test.plugin.zsh"
git -C "$REMOTE_SRC" add .
git -C "$REMOTE_SRC" commit -q -m "v1"
git clone --bare -q "$REMOTE_SRC" "$REMOTE_BARE"

# Install plugin
zload "file://$REMOTE_BARE"
[[ "$VER" == "1" ]] || {
  echo "FAIL: initial version not 1"
  exit 1
}

# Push update to remote
echo 'export VER=2' >"$REMOTE_SRC/test.plugin.zsh"
git -C "$REMOTE_SRC" commit -q -am "v2"
git -C "$REMOTE_SRC" push -q "$REMOTE_BARE" main

# Run zload update (should show updated)
UPDATE_OUT=$(zload update)
[[ "$UPDATE_OUT" == *"updated"* && "$UPDATE_OUT" == *"update complete"* ]] || {
  echo "FAIL: zload update did not report updated (output: $UPDATE_OUT)"
  exit 1
}

# Run zload update again (should show up to date)
SECOND_OUT=$(zload update)
[[ "$SECOND_OUT" == *"up to date"* ]] || {
  echo "FAIL: second zload update did not report up to date (output: $SECOND_OUT)"
  exit 1
}

# Verify bundle recompiled with new version
source "$ZLOAD_CACHE/bundle.zsh"
[[ "$VER" == "2" ]] || {
  echo "FAIL: update did not pull new version into bundle"
  exit 1
}
# Test dirty working tree and force update (-f)
installed_dirs=("${ZLOAD_PLUGINS}"/*(N/))
target_plugin="${installed_dirs[1]}"
echo 'export VER=local_dirty' >"$target_plugin/test.plugin.zsh"

# Push v3 to remote
echo 'export VER=3' >"$REMOTE_SRC/test.plugin.zsh"
git -C "$REMOTE_SRC" commit -q -am "v3"
git -C "$REMOTE_SRC" push -q "$REMOTE_BARE" main

# Normal update without -f fails
DIRTY_OUT=$(zload update 2>&1)
[[ "$DIRTY_OUT" == *"update failed"* ]] || {
  echo "FAIL: update on dirty repo should have failed (output: $DIRTY_OUT)"
  exit 1
}

# Forced update with -f succeeds
FORCE_OUT=$(zload update -f)
[[ "$FORCE_OUT" == *"updated"* ]] || {
  echo "FAIL: forced update with -f did not succeed (output: $FORCE_OUT)"
  exit 1
}

source "$ZLOAD_CACHE/bundle.zsh"
[[ "$VER" == "3" ]] || {
  echo "FAIL: force update did not pull v3 into bundle"
  exit 1
}

echo "PASS: test_update (git pull, commit diff tracking, force update, and bundle recompile verified)"
