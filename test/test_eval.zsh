#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"

source ./zload.zsh

# 1. Cold eval execution
zload eval mytool "echo 'export MYTOOL_ACTIVE=1'"

[[ "$MYTOOL_ACTIVE" == "1" ]] || {
  echo "FAIL: MYTOOL_ACTIVE not set on cold eval"
  exit 1
}

CACHE_FILE="$ZLOAD_CACHE/eval/mytool.zsh"
ZWC_FILE="${CACHE_FILE}.zwc"

[[ -f "$CACHE_FILE" ]] || {
  echo "FAIL: eval cache file not created"
  exit 1
}
[[ -f "$ZWC_FILE" ]] || {
  echo "FAIL: eval zwc bytecode not compiled"
  exit 1
}

# 2. Warm eval execution: modify command to verify it sources cache, not command
unset MYTOOL_ACTIVE
zload eval mytool "echo 'export MYTOOL_ACTIVE=999'"
[[ "$MYTOOL_ACTIVE" == "1" ]] || {
  echo "FAIL: warm eval did not use cached script"
  exit 1
}

echo "PASS: test_eval (eval output caching and bytecode wordcode generation)"
