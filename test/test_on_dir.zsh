#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"

source ./zload.zsh

# Create mock plugin
MOCK_DIR="$SANDBOX/git-tool"
mkdir -p "$MOCK_DIR"
cat << 'EOF' > "$MOCK_DIR/git-tool.plugin.zsh"
export GIT_TOOL_LOADED=1
EOF

# Setup two test directories: non-git and git
DIR_NORMAL="$SANDBOX/normal_workspace"
DIR_GIT="$SANDBOX/git_workspace"
mkdir -p "$DIR_NORMAL" "$DIR_GIT/.git"

# Start inside normal workspace
cd "$DIR_NORMAL"

# Load plugin conditioned on entering a directory with .git
zload "$MOCK_DIR" --on-dir ".git"

# 1. Assert not loaded yet
[[ -z "$GIT_TOOL_LOADED" ]] || { echo "FAIL: git-tool was loaded prematurely"; exit 1; }

# 2. cd into git workspace and trigger chpwd hooks
cd "$DIR_GIT"
chpwd_functions=( ${(k)functions[(I)_zload_on_dir_*]} )
for fn in "${chpwd_functions[@]}"; do
  "$fn"
done

# 3. Assert loaded
[[ "$GIT_TOOL_LOADED" == "1" ]] || { echo "FAIL: git-tool was not loaded after cd into .git directory"; exit 1; }

# 4. cd back to normal workspace
cd "$DIR_NORMAL"
for fn in "${chpwd_functions[@]}"; do
  "$fn" 2>/dev/null || true
done
[[ "$GIT_TOOL_LOADED" == "1" ]] || { echo "FAIL: unexpected state on leaving directory"; exit 1; }

echo "PASS: test_on_dir (directory-triggered lazy loading with --on-dir)"
