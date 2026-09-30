#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT
unset ZSH
export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"
source ./zload.zsh

# Setup Oh-My-Zsh repository structure with real upstream function implementations
mkdir -p "$ZLOAD_PLUGINS/_omz/lib" "$ZLOAD_PLUGINS/_omz/plugins/git"

cat <<'EOF' >"$ZLOAD_PLUGINS/_omz/lib/git.zsh"
function current_branch() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null
}
function parse_git_dirty() {
  local STATUS="$(git status --porcelain 2>/dev/null)"
  if [[ -n $STATUS ]]; then
    echo "dirty"
  else
    echo "clean"
  fi
}
EOF

cat <<'EOF' >"$ZLOAD_PLUGINS/_omz/plugins/git/git.plugin.zsh"
alias gst="git status"
alias gcb="current_branch"
alias gl="git pull"
EOF

# Create a real Git repository
TEST_REPO="$SANDBOX/real_repo"
mkdir -p "$TEST_REPO"
git -C "$TEST_REPO" init -q -b "feature-omz-integration"
echo "data" >"$TEST_REPO/tracked.txt"
git -C "$TEST_REPO" config user.email "test@zload.test"
git -C "$TEST_REPO" config user.name "Zload Test"
git -C "$TEST_REPO" add .
git -C "$TEST_REPO" commit -q -m "initial commit"

# Load omz:git through zload
zload "omz:git"

# Verify current_branch in clean repo
cd "$TEST_REPO"
BRANCH=$(current_branch)
[[ "$BRANCH" == "feature-omz-integration" ]] || {
  echo "FAIL: current_branch returned '$BRANCH', expected 'feature-omz-integration'"
  exit 1
}

CLEAN_STATUS=$(parse_git_dirty)
[[ "$CLEAN_STATUS" == "clean" ]] || {
  echo "FAIL: parse_git_dirty returned '$CLEAN_STATUS', expected 'clean'"
  exit 1
}

# Dirty the repository
echo "uncommitted change" >>"$TEST_REPO/tracked.txt"
DIRTY_STATUS=$(parse_git_dirty)
[[ "$DIRTY_STATUS" == "dirty" ]] || {
  echo "FAIL: parse_git_dirty returned '$DIRTY_STATUS', expected 'dirty'"
  exit 1
}

echo "PASS: test_real_omz (real-world git branch and dirty status verification)"
