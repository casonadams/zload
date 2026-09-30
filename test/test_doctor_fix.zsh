#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"

source ./zload.zsh

# Create an uncompiled bundle and dump file
mkdir -p "$ZLOAD_CACHE"
echo 'export DOCTOR_TEST_BUNDLE=1' >"$ZLOAD_CACHE/bundle.zsh"
touch "$ZLOAD_CACHE/zcompdump-${ZSH_VERSION}"

# Assert wordcode does not exist yet
[[ ! -f "$ZLOAD_CACHE/bundle.zsh.zwc" ]] || {
  echo "FAIL: zwc already exists"
  exit 1
}

# Run doctor --fix
zload doctor --fix >/dev/null

# Assert wordcode was compiled by doctor --fix
[[ -f "$ZLOAD_CACHE/bundle.zsh.zwc" ]] || {
  echo "FAIL: bundle.zsh.zwc was not compiled by --fix"
  exit 1
}
[[ -f "$ZLOAD_CACHE/zcompdump-${ZSH_VERSION}.zwc" ]] || {
  echo "FAIL: zcompdump zwc was not compiled by --fix"
  exit 1
}

echo "PASS: test_doctor_fix (self-healing repair of missing wordcode caches)"
