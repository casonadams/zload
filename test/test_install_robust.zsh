#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"
export HOME="$SANDBOX/home"
export ZLOAD_NO_COMPINIT=1
mkdir -p "$HOME"

source ./zload.zsh

fail() {
  echo "FAIL: $1"
  exit 1
}

SRC="$SANDBOX/pkg_src"
mkdir -p "$SRC"
git -C "$SRC" init -q -b main
git -C "$SRC" config user.email t@zload.test
git -C "$SRC" config user.name t
echo 'export VER=1' >"$SRC/pkg.plugin.zsh"
git -C "$SRC" add . && git -C "$SRC" commit -q -m one
C1="$(git -C "$SRC" rev-parse HEAD)"
echo 'export VER=2' >"$SRC/pkg.plugin.zsh"
git -C "$SRC" commit -q -am two
git -C "$SRC" config uploadpack.allowAnySHA1InWant true

# 1. A failing build hook fails the install and leaves nothing half-built behind.
local -A bad
_zload_parse_spec bad "file://$SRC --build ${(q)$(print -r -- 'echo boom >&2; exit 3')}"
if _zload_install bad 2>"$SANDBOX/err"; then
  fail "install succeeded despite a failing build hook"
fi
[[ ! -d "${bad[dir]}" ]] || fail "failed build left the plugin directory behind"
grep -q boom "$SANDBOX/err" || fail "build output not surfaced"

# 2. Pinning to a commit SHA works.
local -A pinned
_zload_parse_spec pinned "file://$SRC@${C1[1,12]}"
_zload_install pinned >/dev/null 2>&1 || fail "install pinned to a SHA failed"
[[ "$(git -C "${pinned[dir]}" rev-parse HEAD)" == "$C1" ]] || fail "SHA pin checked out the wrong commit"

# 3. Clone failures surface git's reason.
local -A missing
_zload_parse_spec missing "file://$SANDBOX/nope"
_zload_install missing 2>"$SANDBOX/err2" >/dev/null && fail "install of missing repo succeeded"
[[ -s "$SANDBOX/err2" && "$(<"$SANDBOX/err2")" == *"nope"* ]] || fail "clone failure reason not shown"

echo "PASS: test_install_robust (build failure cleanup, SHA pinning, clone error output)"
