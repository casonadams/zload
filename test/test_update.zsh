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

echo 'export VER=1' > "$REMOTE_SRC/test.plugin.zsh"
git -C "$REMOTE_SRC" add .
git -C "$REMOTE_SRC" commit -q -m "v1"
git clone --bare -q "$REMOTE_SRC" "$REMOTE_BARE"

# Install plugin
zload "file://$REMOTE_BARE"
[[ "$VER" == "1" ]] || { echo "FAIL: initial version not 1"; exit 1; }

# Push update to remote
echo 'export VER=2' > "$REMOTE_SRC/test.plugin.zsh"
git -C "$REMOTE_SRC" commit -q -am "v2"
git -C "$REMOTE_SRC" push -q "$REMOTE_BARE" main

# Run zload update
UPDATE_OUT=$(zload update)
[[ "$UPDATE_OUT" == *"up to date"* || "$UPDATE_OUT" == *"update complete"* ]] || {
  echo "FAIL: zload update did not report completion"
  exit 1
}

# Verify bundle recompiled with new version
source "$ZLOAD_CACHE/bundle.zsh"
[[ "$VER" == "2" ]] || { echo "FAIL: update did not pull new version into bundle"; exit 1; }

echo "PASS: test_update (git pull and bundle recompile verified)"
