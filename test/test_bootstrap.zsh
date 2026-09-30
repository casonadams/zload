#!/usr/bin/env zsh
set -e

# Test bootstrap environment
TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT

export XDG_DATA_HOME="$TEST_TMP/data"
export XDG_CACHE_HOME="$TEST_TMP/cache"

source ./zload.zsh

# Check directories created
[[ -d "$ZLOAD_DATA" ]] || {
  echo "FAIL: ZLOAD_DATA not created"
  exit 1
}
[[ -d "$ZLOAD_CACHE" ]] || {
  echo "FAIL: ZLOAD_CACHE not created"
  exit 1
}
[[ -d "$ZLOAD_PLUGINS" ]] || {
  echo "FAIL: ZLOAD_PLUGINS not created"
  exit 1
}

# Check fpath registration
if ((! ${fpath[(Ie)${ZLOAD_HOME}/functions]})); then
  echo "FAIL: functions directory not added to fpath"
  exit 1
fi

# Check zload function is defined
typeset -f zload >/dev/null || {
  echo "FAIL: zload function not defined"
  exit 1
}

echo "PASS: test_bootstrap"
