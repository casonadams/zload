#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"

source ./zload.zsh

# Create mock plugins
mkdir -p "$ZLOAD_PLUGINS/zsh-users---zsh-autosuggestions"
mkdir -p "$ZLOAD_PLUGINS/_omz/plugins/git"

# 1. Test zload which with full slug
OUT1="$(zload which zsh-users---zsh-autosuggestions)"
[[ "$OUT1" == "${ZLOAD_PLUGINS}/zsh-users---zsh-autosuggestions" ]] || {
  echo "FAIL: zload which failed for full slug ($OUT1)"
  exit 1
}

# 2. Test zload which with shorthand
OUT2="$(zload which zsh-autosuggestions)"
[[ "$OUT2" == "${ZLOAD_PLUGINS}/zsh-users---zsh-autosuggestions" ]] || {
  echo "FAIL: zload which failed for shorthand ($OUT2)"
  exit 1
}

# 3. Test zload which for OMZ plugin
OUT3="$(zload which omz:git)"
[[ "$OUT3" == "${ZLOAD_PLUGINS}/_omz/plugins/git" ]] || {
  echo "FAIL: zload which failed for omz:git ($OUT3)"
  exit 1
}

# 4. Test zload cd
zload cd zsh-autosuggestions
[[ "$PWD" == "${ZLOAD_PLUGINS}/zsh-users---zsh-autosuggestions" ]] || {
  echo "FAIL: zload cd failed to change directory ($PWD)"
  exit 1
}

# 5. Test nonexistent plugin
if zload which nonexistent-plugin-1234 2>/dev/null; then
  echo "FAIL: zload which should have exited with error for nonexistent plugin"
  exit 1
fi

echo "PASS: test_which_cd (plugin directory resolution and navigation verified)"
