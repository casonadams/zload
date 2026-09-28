#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"

source ./zload.zsh

# Create local mock plugin
MOCK_DIR="$SANDBOX/deferred-plugin"
mkdir -p "$MOCK_DIR"
cat << 'EOF' > "$MOCK_DIR/deferred.plugin.zsh"
export DEFERRED_WAS_SOURCED=1
EOF

# 1. Non-interactive execution: loads immediately
zload "$MOCK_DIR" --defer
[[ "$DEFERRED_WAS_SOURCED" == "1" ]] || { echo "FAIL: deferred not loaded in non-interactive shell"; exit 1; }

# 2. Interactive simulation: queue in _zload_deferred_specs, then trigger run_deferred
unset DEFERRED_WAS_SOURCED

MOCK_DIR2="$SANDBOX/deferred-plugin-2"
mkdir -p "$MOCK_DIR2"
cat << 'EOF' > "$MOCK_DIR2/deferred-2.plugin.zsh"
export DEFERRED_2_WAS_SOURCED=1
EOF

# Directly queue to test the deferred cycle
_zload_deferred_specs+=("$MOCK_DIR2")
[[ -z "$DEFERRED_2_WAS_SOURCED" ]] || { echo "FAIL: deferred-2 ran prematurely"; exit 1; }

# Trigger the precmd deferred runner
_zload_run_deferred

[[ "$DEFERRED_2_WAS_SOURCED" == "1" ]] || { echo "FAIL: deferred-2 was not sourced by runner"; exit 1; }
[[ "${#_zload_deferred_specs}" == "0" ]] || { echo "FAIL: deferred specs queue not cleared"; exit 1; }

echo "PASS: test_defer (post-prompt scheduling and non-interactive execution)"
