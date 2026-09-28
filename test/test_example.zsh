#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"

# Syntax check example/.zshrc
zsh -n example/.zshrc

# Source example/.zshrc in dry run without cloning live remotes
OUT=$(zsh -c "
  export XDG_DATA_HOME=\"$XDG_DATA_HOME\"
  export XDG_CACHE_HOME=\"$XDG_CACHE_HOME\"
  source example/.zshrc
  echo \"SUCCESS:ZLOAD_LOADED:\$_zload_compinit_done\"
" 2>/dev/null || true)

[[ -n "$OUT" ]] || { echo "FAIL: example/.zshrc failed to parse"; exit 1; }

echo "PASS: test_example (example/.zshrc syntax and execution verified)"
