#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"
export HOME="$SANDBOX/home"
export ZLOAD_NO_COMPINIT=1
mkdir -p "$HOME" "$SANDBOX/pa" "$SANDBOX/pb" "$SANDBOX/pc"
echo 'echo load-a' >"$SANDBOX/pa/pa.plugin.zsh"
echo 'echo load-b' >"$SANDBOX/pb/pb.plugin.zsh"
echo 'echo load-c' >"$SANDBOX/pc/pc.plugin.zsh"

fail() {
  echo "FAIL: $1"
  exit 1
}

CACHE="$XDG_CACHE_HOME/zload"
run_shell() {
  zsh -c "source ${(q)PWD}/zload.zsh; zload $SANDBOX/pa; zload $SANDBOX/pb $SANDBOX/pc; $1" 2>&1
}

# 1. Separate calls all load, and each gets its own bundle slot.
out="$(run_shell 'print specs=${#_zload_specs}')"
for p in a b c; do [[ "$out" == *load-$p* ]] || fail "plugin $p not loaded: $out"; done
[[ "$out" == *specs=3* ]] || fail "specs not accumulated: $out"
[[ -f "$CACHE/bundle.zsh.zwc" && -f "$CACHE/bundle.2.zsh.zwc" ]] || fail "per-call bundles missing"

# 2. A second shell with the same calls rebuilds nothing.
m1="$(stat -f %m "$CACHE/bundle.zsh" "$CACHE/bundle.2.zsh")"
sleep 1.1
out="$(run_shell 'print specs=${#_zload_specs}')"
for p in a b c; do [[ "$out" == *load-$p* ]] || fail "warm plugin $p not loaded: $out"; done
[[ "$out" == *specs=3* ]] || fail "warm shell lost specs: $out"
[[ "$(stat -f %m "$CACHE/bundle.zsh" "$CACHE/bundle.2.zsh")" == "$m1" ]] || fail "warm shell rebuilt bundles"

# 3. Recompiling (update/sync/compile) keeps every slot warm.
run_shell '_zload_compile_bundle' >/dev/null
m2="$(stat -f %m "$CACHE/bundle.zsh" "$CACHE/bundle.2.zsh")"
sleep 1.1
run_shell ':' >/dev/null
[[ "$(stat -f %m "$CACHE/bundle.zsh" "$CACHE/bundle.2.zsh")" == "$m2" ]] || fail "recompile lost a slot key"

# 4. Changing only the second call rebuilds only that slot.
m3="$(stat -f %m "$CACHE/bundle.zsh")"
sleep 1.1
out="$(zsh -c "source ${(q)PWD}/zload.zsh; zload $SANDBOX/pa; zload $SANDBOX/pc" 2>&1)"
[[ "$out" == *load-a* && "$out" == *load-c* && "$out" != *load-b* ]] || fail "changed second call not honored: $out"
[[ "$(stat -f %m "$CACHE/bundle.zsh")" == "$m3" ]] || fail "unchanged first slot was rebuilt"

echo "PASS: test_multi_call (per-call bundle slots stay warm across separate zload calls)"
