#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"

source ./zload.zsh

# Create local mock plugin with multiple commands
MOCK_TOOL_DIR="$SANDBOX/my-tool"
mkdir -p "$MOCK_TOOL_DIR"
cat << 'EOF' > "$MOCK_TOOL_DIR/tool.plugin.zsh"
export TOOL_REAL_LOADED=1

cmd_alpha() {
  echo "alpha:$1"
}

cmd_beta() {
  echo "beta:$1"
}
EOF

# Load with lazy stubs for both cmd_alpha and cmd_beta
zload "$MOCK_TOOL_DIR" --on "cmd_alpha, cmd_beta"

# 1. Assert neither real code nor variable is loaded yet
[[ -z "$TOOL_REAL_LOADED" ]] || { echo "FAIL: tool was loaded prematurely"; exit 1; }

# 2. Assert both stubs exist
typeset -f cmd_alpha >/dev/null || { echo "FAIL: cmd_alpha stub missing"; exit 1; }
typeset -f cmd_beta >/dev/null || { echo "FAIL: cmd_beta stub missing"; exit 1; }

# 3. Invoke cmd_alpha
cmd_alpha "hello" > "$SANDBOX/out1"
RES1=$(cat "$SANDBOX/out1")
[[ "$RES1" == "alpha:hello" ]] || { echo "FAIL: cmd_alpha output '$RES1'"; exit 1; }
[[ "$TOOL_REAL_LOADED" == "1" ]] || { echo "FAIL: tool not marked loaded after stub call"; exit 1; }

# 4. Invoke cmd_beta (should now be the real function directly)
cmd_beta "world" > "$SANDBOX/out2"
RES2=$(cat "$SANDBOX/out2")
[[ "$RES2" == "beta:world" ]] || { echo "FAIL: cmd_beta output '$RES2'"; exit 1; }

echo "PASS: test_lazy_cmd (lazy command stubs and execution forwarding)"
