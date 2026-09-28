#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"

source ./zload.zsh

# Create mock snippet file
SNIPPET_SOURCE="$SANDBOX/remote_script.zsh"
cat << 'EOF' > "$SNIPPET_SOURCE"
export SNIPPET_WAS_LOADED=1
snippet_cmd() {
  echo "snippet_cmd_works:$1"
}
EOF

# 1. Load via snippet: URL
zload "snippet:file://$SNIPPET_SOURCE"

[[ "$SNIPPET_WAS_LOADED" == "1" ]] || { echo "FAIL: snippet script not loaded"; exit 1; }
typeset -f snippet_cmd >/dev/null || { echo "FAIL: snippet_cmd not defined"; exit 1; }

RES=$(snippet_cmd "test")
[[ "$RES" == "snippet_cmd_works:test" ]] || { echo "FAIL: snippet_cmd output '$RES'"; exit 1; }

# Verify snippet file and .zwc exist on disk
SNIPPET_DIR="${ZLOAD_PLUGINS}/_snippets"
[[ -d "$SNIPPET_DIR" ]] || { echo "FAIL: _snippets directory not created"; exit 1; }

ZWC_COUNT=$(find "$SNIPPET_DIR" -name "*.zwc" | wc -l)
(( ZWC_COUNT > 0 )) || { echo "FAIL: snippet was not compiled to .zwc"; exit 1; }

# 2. Test bundle compilation with snippet
zload compile >/dev/null
unset SNIPPET_WAS_LOADED
source "$ZLOAD_CACHE/bundle.zsh"
[[ "$SNIPPET_WAS_LOADED" == "1" ]] || { echo "FAIL: snippet not loaded from compiled bundle"; exit 1; }

echo "PASS: test_snippet (raw snippet fetch, bytecode compilation, and bundle integration)"
