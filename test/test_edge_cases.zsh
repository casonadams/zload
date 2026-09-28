#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"

source ./zload.zsh

# 1. Test pre-existing compinit detection
_main_complete() { :; } # Simulate system compinit already loaded
typeset -g -A _comps
_comps=(git _git)

zload compinit --lazy
[[ "$_zload_compinit_done" == "1" ]] || {
  echo "FAIL: did not detect pre-existing compinit"
  exit 1
}

# 2. Test offline / failed install resilience
mkdir -p "$SANDBOX/p1"
echo "export P1=1" > "$SANDBOX/p1/p1.plugin.zsh"
zload "$SANDBOX/p1"

[[ -f "$ZLOAD_CACHE/bundle.zsh.zwc" ]] || { echo "FAIL: initial bundle missing"; exit 1; }
ORIG_HASH="$(< "$ZLOAD_CACHE/bundle.hash")"

# Now try to load an invalid repo that fails to clone
zload "https://invalid-nonexistent-domain-12345.com/fail.git" 2>/dev/null || true

# Assert existing valid bundle and hash are preserved intact
NEW_HASH="$(< "$ZLOAD_CACHE/bundle.hash")"
[[ "$ORIG_HASH" == "$NEW_HASH" ]] || {
  echo "FAIL: failed install corrupted existing bundle.hash"
  exit 1
}

echo "PASS: test_edge_cases (pre-existing compinit detection and failure resilience)"
