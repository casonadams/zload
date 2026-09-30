#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"

# Copy repo into sandbox
SANDBOX_HOME="$SANDBOX/zload"
mkdir -p "$SANDBOX_HOME"
cp -R zload.zsh zload.plugin.zsh functions "$SANDBOX_HOME/"

source "$SANDBOX_HOME/zload.zsh"

# Run compile
zload compile >/dev/null

# Assert zload.zsh.zwc exists
[[ -f "$SANDBOX_HOME/zload.zsh.zwc" ]] || {
  echo "FAIL: zload.zsh.zwc not created"
  exit 1
}
[[ -f "$SANDBOX_HOME/zload.plugin.zsh.zwc" ]] || {
  echo "FAIL: zload.plugin.zsh.zwc not created"
  exit 1
}

# Assert functions have .zwc
FN_COUNT=$(ls -1 "$SANDBOX_HOME/functions"/*.zwc 2>/dev/null | wc -l)
((FN_COUNT > 5)) || {
  echo "FAIL: functions not compiled to .zwc (count=$FN_COUNT)"
  exit 1
}

echo "PASS: test_self_compile (self-compilation of core loader and modules)"
