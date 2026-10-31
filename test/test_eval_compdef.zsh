#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"
export HOME="$SANDBOX/home"
mkdir -p "$HOME"

source ./zload.zsh

fail() {
  echo "FAIL: $1"
  exit 1
}

# 1. Changing the command under the same name rebuilds the cache.
zload eval demo "echo 'export DEMO=one'"
[[ "$DEMO" == one ]] || fail "first eval not applied"
zload eval demo "echo 'export DEMO=two'"
[[ "$DEMO" == two ]] || fail "changed command served from stale cache"

# 2. A failing command must not poison the cache with empty output.
if zload eval broken "false" 2>/dev/null; then
  fail "failing eval with no cache reported success"
fi
[[ ! -f "$ZLOAD_CACHE/eval/broken.zsh" ]] || fail "failed eval wrote a cache file"

# 3. A later failure keeps the last good cache.
zload eval demo "echo 'export DEMO=three'"
unset DEMO
zload eval demo "false" 2>/dev/null
[[ "$DEMO" == three ]] || fail "last good cache not kept after failure: '$DEMO'"

# 4. Deferred compdef arguments survive replay with their quoting intact.
_zload_deferred_compdefs=()
compdef _some_fn 'cmd with space' other
typeset -a seen
compdef() { seen=("$@"); }
for def in "${_zload_deferred_compdefs[@]}"; do
  eval "compdef $def"
done
[[ "${#seen}" == 3 && "$seen[2]" == "cmd with space" ]] || fail "compdef args mangled: ${(j:|:)seen}"

echo "PASS: test_eval_compdef (eval cache key/failure handling, compdef quoting)"
