#!/usr/bin/env zsh
set -e

# Setup clean sandbox
SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"

source ./zload.zsh

# Create a local Git repo as a mock remote plugin
MOCK_REMOTE="$SANDBOX/remote-plugin.git"
MOCK_WORK="$SANDBOX/work-plugin"
mkdir -p "$MOCK_WORK"
git -C "$MOCK_WORK" init -q
git -C "$MOCK_WORK" config user.email "test@zload.test"
git -C "$MOCK_WORK" config user.name "Zload Test"

echo 'export MOCK_PLUGIN_LOADED=1' > "$MOCK_WORK/mock-plugin.plugin.zsh"
git -C "$MOCK_WORK" add .
git -C "$MOCK_WORK" commit -q -m "Initial commit"
git -C "$MOCK_WORK" tag "v1.0.0"

# Create a branch
git -C "$MOCK_WORK" checkout -q -b "feature-branch"
echo 'export MOCK_PLUGIN_FEATURE=1' >> "$MOCK_WORK/mock-plugin.plugin.zsh"
git -C "$MOCK_WORK" commit -q -am "Add feature"
git -C "$MOCK_WORK" checkout -q -

# Clone to bare repo to serve as remote URL
git clone --bare -q "$MOCK_WORK" "$MOCK_REMOTE"

# Test 1: Install from URL
zload "file://$MOCK_REMOTE"
[[ "$MOCK_PLUGIN_LOADED" == "1" ]] || { echo "FAIL: MOCK_PLUGIN_LOADED not set"; exit 1; }

# Test 2: Install from URL with tag
unset MOCK_PLUGIN_FEATURE
zload "file://$MOCK_REMOTE@v1.0.0"
[[ -z "$MOCK_PLUGIN_FEATURE" ]] || { echo "FAIL: Feature branch leaked into tag checkout"; exit 1; }

# Test 3: Install with lazy stub (--on)
MOCK_LAZY_REMOTE="$SANDBOX/remote-lazy.git"
MOCK_LAZY_WORK="$SANDBOX/work-lazy"
mkdir -p "$MOCK_LAZY_WORK"
git -C "$MOCK_LAZY_WORK" init -q
git -C "$MOCK_LAZY_WORK" config user.email "test@zload.test"
git -C "$MOCK_LAZY_WORK" config user.name "Zload Test"
cat << 'EOF' > "$MOCK_LAZY_WORK/lazy-tool.plugin.zsh"
lazy_cmd() {
  echo "lazy_cmd_result:$1"
}
EOF
git -C "$MOCK_LAZY_WORK" add .
git -C "$MOCK_LAZY_WORK" commit -q -m "Initial commit"
git clone --bare -q "$MOCK_LAZY_WORK" "$MOCK_LAZY_REMOTE"

zload "file://$MOCK_LAZY_REMOTE" --on "lazy_cmd"

# Verify lazy_cmd is defined as a stub initially
typeset -f lazy_cmd >/dev/null || { echo "FAIL: lazy_cmd not stubbed"; exit 1; }

# Invoke lazy_cmd and verify it replaces itself and executes
RES=$(lazy_cmd "hello")
[[ "$RES" == "lazy_cmd_result:hello" ]] || { echo "FAIL: lazy_cmd output '$RES'"; exit 1; }

# Test 4: Local directory plugin directly
LOCAL_DIR="$SANDBOX/my-local-plugin"
mkdir -p "$LOCAL_DIR"
cat << 'EOF' > "$LOCAL_DIR/my-local-plugin.plugin.zsh"
export LOCAL_PLUGIN_ACTIVE="yes"
EOF

zload "$LOCAL_DIR"
[[ "$LOCAL_PLUGIN_ACTIVE" == "yes" ]] || { echo "FAIL: local plugin not loaded"; exit 1; }

echo "PASS: test_install (all 4 test cases)"
