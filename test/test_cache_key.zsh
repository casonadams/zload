#!/usr/bin/env zsh
set -e
zmodload -F zsh/stat b:zstat
mtime() { zstat +mtime "$@"; }

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"
export HOME="$SANDBOX/home"
export ZLOAD_NO_COMPINIT=1
mkdir -p "$HOME" "$SANDBOX/pa" "$SANDBOX/pb"
echo 'echo load-a' >"$SANDBOX/pa/pa.plugin.zsh"
echo 'echo load-b' >"$SANDBOX/pb/pb.plugin.zsh"

fail() {
  echo "FAIL: $1"
  exit 1
}

run_shell() {
  zsh -c "source ${(q)PWD}/zload.zsh; zload $1" 2>&1
}

# 1. Same-length specs must not share a cached bundle.
out_a="$(run_shell "$SANDBOX/pa")"
[[ "$out_a" == *load-a* ]] || fail "first spec not loaded: $out_a"
out_b="$(run_shell "$SANDBOX/pb")"
[[ "$out_b" == *load-b* && "$out_b" != *load-a* ]] || fail "same-length spec served stale bundle: $out_b"

# 2. Unchanged spec takes the warm path (bundle sourced, no rebuild).
before="$(mtime "$XDG_CACHE_HOME/zload/bundle.zsh")"
sleep 1.1
out_b2="$(run_shell "$SANDBOX/pb")"
[[ "$out_b2" == *load-b* ]] || fail "warm run did not load plugin: $out_b2"
after="$(mtime "$XDG_CACHE_HOME/zload/bundle.zsh")"
[[ "$before" == "$after" ]] || fail "warm run rebuilt the bundle"

# 3. The compiled bundle is actually used: tamper with the text, keep it older than the .zwc.
bundle="$XDG_CACHE_HOME/zload/bundle.zsh"
cp "$bundle" "$SANDBOX/bundle.orig"
echo 'echo TAMPERED' >"$bundle"
touch -r "$bundle.zwc" "$bundle"
touch -t 202001010000 "$bundle"
out_zwc="$(zsh -c "source ${(q)bundle}" 2>&1)"
cp "$SANDBOX/bundle.orig" "$bundle"
touch -r "$bundle.zwc" "$bundle"
[[ "$out_zwc" != *TAMPERED* ]] || fail "bundle.zsh.zwc ignored by zsh (compiled under wrong name)"

# 4. Rebuilding the bundle invalidates the completion dump.
touch "$XDG_CACHE_HOME/zload/zcompdump-test"
run_shell "$SANDBOX/pa" >/dev/null
[[ ! -e "$XDG_CACHE_HOME/zload/zcompdump-test" ]] || fail "zcompdump survived a bundle change"

# 5. Recompiling without changes (as update/sync do) keeps the warm key.
zsh -c "source ${(q)PWD}/zload.zsh; zload ${(q)SANDBOX}/pa >/dev/null; _zload_compile_bundle" >/dev/null 2>&1
before="$(mtime "$XDG_CACHE_HOME/zload/bundle.zsh")"
sleep 1.1
run_shell "$SANDBOX/pa" >/dev/null
after="$(mtime "$XDG_CACHE_HOME/zload/bundle.zsh")"
[[ "$before" == "$after" ]] || fail "key lost after recompiling bundle"

echo "PASS: test_cache_key (exact-key bundle cache, wordcode name, completion dump invalidation)"
