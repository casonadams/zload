#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"

source ./zload.zsh

# Mock an Oh-My-Zsh repository structure under a mock remote
OMZ_MOCK_REMOTE="$SANDBOX/omz-remote.git"
OMZ_MOCK_WORK="$SANDBOX/omz-work"

mkdir -p "$OMZ_MOCK_WORK/lib"
mkdir -p "$OMZ_MOCK_WORK/plugins/git"
mkdir -p "$OMZ_MOCK_WORK/plugins/extract"
mkdir -p "$OMZ_MOCK_WORK/themes"

# lib/git.zsh with current_branch and parse_git_dirty
cat <<'EOF' >"$OMZ_MOCK_WORK/lib/git.zsh"
current_branch() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null
}
parse_git_dirty() {
  echo "clean"
}
EOF

# lib/theme-and-appearance.zsh
cat <<'EOF' >"$OMZ_MOCK_WORK/lib/theme-and-appearance.zsh"
export OMZ_THEME_LOADED=1
EOF

# plugins/git/git.plugin.zsh calling current_branch
cat <<'EOF' >"$OMZ_MOCK_WORK/plugins/git/git.plugin.zsh"
alias gcb='current_branch'
alias gl='git pull'
EOF
# plugins/git/_git completion
touch "$OMZ_MOCK_WORK/plugins/git/_git"

# plugins/extract/extract.plugin.zsh
cat <<'EOF' >"$OMZ_MOCK_WORK/plugins/extract/extract.plugin.zsh"
extract() {
  echo "extracting $1"
}
EOF

# themes/robbyrussell.zsh-theme
cat <<'EOF' >"$OMZ_MOCK_WORK/themes/robbyrussell.zsh-theme"
PROMPT="%(?:%{$fg_bold[green]%}-> :%{$fg_bold[red]%}-> )"
EOF

# Initialize git repository
git -C "$OMZ_MOCK_WORK" init -q
git -C "$OMZ_MOCK_WORK" config user.email "test@zload.test"
git -C "$OMZ_MOCK_WORK" config user.name "Zload Test"
git -C "$OMZ_MOCK_WORK" add .
git -C "$OMZ_MOCK_WORK" commit -q -m "OMZ mock init"
git clone --bare -q "$OMZ_MOCK_WORK" "$OMZ_MOCK_REMOTE"

# Override git clone in _zload_ensure_omz to use local mock remote
_zload_ensure_omz() {
  local omz_dir="${ZLOAD_PLUGINS}/_omz"
  export ZSH="$omz_dir"
  export ZSH_CACHE_DIR="${ZLOAD_CACHE}/omz"
  mkdir -p "$ZSH_CACHE_DIR"

  if [[ -d "$omz_dir" ]]; then
    return 0
  fi

  mkdir -p "${omz_dir:h}"
  git clone --depth 1 "file://$OMZ_MOCK_REMOTE" "$omz_dir" >/dev/null 2>&1
}

# Test 1: Load omz:git
zload "omz:git"

# Check ZSH variable
[[ "$ZSH" == "${ZLOAD_PLUGINS}/_omz" ]] || {
  echo "FAIL: ZSH variable not set correctly"
  exit 1
}

# Check that current_branch from lib/git.zsh was loaded
typeset -f current_branch >/dev/null || {
  echo "FAIL: current_branch not defined"
  exit 1
}

# Check that git plugin alias is defined
alias gcb >/dev/null || {
  echo "FAIL: alias gcb not defined"
  exit 1
}

# Check that completions are in fpath
if ((! ${fpath[(Ie)${ZLOAD_PLUGINS}/_omz/plugins/git]})); then
  echo "FAIL: plugins/git not in fpath"
  exit 1
fi

# Test 2: Load second plugin omz:extract (verifying no re-clone)
zload "omz:plugins/extract"
typeset -f extract >/dev/null || {
  echo "FAIL: extract function not defined"
  exit 1
}

# Test 3: Load OMZ theme omz:themes/robbyrussell
zload "omz:themes/robbyrussell"
[[ "$OMZ_THEME_LOADED" == "1" ]] || {
  echo "FAIL: OMZ theme lib not loaded"
  exit 1
}
[[ -n "$PROMPT" ]] || {
  echo "FAIL: PROMPT not set by robbyrussell theme"
  exit 1
}

echo "PASS: test_omz (all OMZ plugin, lib shim, and theme tests)"
