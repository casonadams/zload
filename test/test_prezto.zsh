#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"

source ./zload.zsh

# Mock Prezto repository
PREZTO_REMOTE="$SANDBOX/prezto-remote.git"
PREZTO_WORK="$SANDBOX/prezto-work"

mkdir -p "$PREZTO_WORK/modules/utility/functions"

# init.zsh
cat <<'EOF' >"$PREZTO_WORK/modules/utility/init.zsh"
export PREZTO_UTILITY_LOADED=1
EOF

# functions/prezto_helper
cat <<'EOF' >"$PREZTO_WORK/modules/utility/functions/prezto_helper"
prezto_helper() {
  echo "prezto_helper_works"
}
EOF

git -C "$PREZTO_WORK" init -q
git -C "$PREZTO_WORK" config user.email "test@zload.test"
git -C "$PREZTO_WORK" config user.name "Zload Test"
git -C "$PREZTO_WORK" add .
git -C "$PREZTO_WORK" commit -q -m "Prezto mock init"
git clone --bare -q "$PREZTO_WORK" "$PREZTO_REMOTE"

# Test cloning mock Prezto
mkdir -p "${ZLOAD_PLUGINS}/_prezto"
git clone --depth 1 -q "file://$PREZTO_REMOTE" "${ZLOAD_PLUGINS}/_prezto"

# Load prezto:utility
zload "prezto:utility"

[[ "$PREZTO_UTILITY_LOADED" == "1" ]] || {
  echo "FAIL: PREZTO_UTILITY_LOADED not set"
  exit 1
}

# Test autoloaded helper function from functions/
typeset -f prezto_helper >/dev/null || {
  echo "FAIL: prezto_helper not autoloaded"
  exit 1
}
RES=$(prezto_helper)
[[ "$RES" == "prezto_helper_works" ]] || {
  echo "FAIL: prezto_helper returned '$RES'"
  exit 1
}

echo "PASS: test_prezto (Prezto module and functions autoloading)"
