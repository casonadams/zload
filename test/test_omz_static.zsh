#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"
export HOME="$SANDBOX/home"
export ZLOAD_NO_COMPINIT=1
unset ZSH ZSH_CACHE_DIR
mkdir -p "$HOME"

fail() {
  echo "FAIL: $1"
  exit 1
}

# Pre-installed Oh-My-Zsh checkout (no network).
OMZ="$XDG_DATA_HOME/zload/plugins/_omz"
mkdir -p "$OMZ/lib" "$OMZ/plugins/git" "$OMZ/plugins/extract"
echo 'current_branch() { echo main; }' >"$OMZ/lib/git.zsh"
echo "alias gcb=current_branch" >"$OMZ/plugins/git/git.plugin.zsh"
echo "extract() { echo extracting; }" >"$OMZ/plugins/extract/extract.plugin.zsh"

run_shell() {
  zsh -c "source ${(q)PWD}/zload.zsh; zload $1; print ZSH=\$ZSH; print -r -- \"fn=\${+functions[current_branch]}\"" 2>&1
}

# 1. Cold start with an existing checkout still exports ZSH / ZSH_CACHE_DIR.
out="$(run_shell "omz:git omz:extract")"
[[ "$out" == *"ZSH=$OMZ"* ]] || fail "ZSH not exported on cold start: $out"
[[ "$out" == *"fn=1"* ]] || fail "git lib not loaded on cold start: $out"

BUNDLE="$XDG_CACHE_HOME/zload/bundle.zsh"

# 2. The bundle resolves library needs at compile time instead of running the shim.
grep -Fq "source $OMZ/lib/git.zsh" "$BUNDLE" || fail "bundle does not source lib/git.zsh directly"
[[ "$(grep -c "lib/git.zsh" "$BUNDLE")" == 1 ]] || fail "lib/git.zsh emitted more than once"
if grep -q '^_zload_omz_shim' "$BUNDLE"; then
  fail "bundle still invokes _zload_omz_shim at startup"
fi

# 3. Warm start gives the same result.
out="$(run_shell "omz:git omz:extract")"
[[ "$out" == *"ZSH=$OMZ"* && "$out" == *"fn=1"* ]] || fail "warm start differs: $out"

echo "PASS: test_omz_static (omz env on cold start, compile-time lib resolution)"
