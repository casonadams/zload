#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"

# Create mock plugins
mkdir -p "$SANDBOX/p1" "$SANDBOX/p2" "$SANDBOX/p3"
echo 'export P1_LOADED=1' > "$SANDBOX/p1/p1.plugin.zsh"
echo 'export P2_LOADED=1' > "$SANDBOX/p2/p2.plugin.zsh"
echo 'export P3_LOADED=1' > "$SANDBOX/p3/p3.plugin.zsh"

LIST_INITIAL="$SANDBOX/p1
$SANDBOX/p2"

# 1. Cold run: initializes and compiles bundle
zsh -c "
  export XDG_DATA_HOME=\"$XDG_DATA_HOME\"
  export XDG_CACHE_HOME=\"$XDG_CACHE_HOME\"
  source ./zload.zsh
  zload \"$LIST_INITIAL\"
"

[[ -f "$XDG_CACHE_HOME/zload/bundle.zsh.zwc" ]] || {
  echo "FAIL: bundle.zsh.zwc not produced on cold run"
  exit 1
}

# 2. Warm run: benchmark timing and verify bundle loaded
WARM_RESULT=$(zsh -c "
  export XDG_DATA_HOME=\"$XDG_DATA_HOME\"
  export XDG_CACHE_HOME=\"$XDG_CACHE_HOME\"
  zmodload zsh/datetime
  t0=\$EPOCHREALTIME
  source ./zload.zsh
  zload \"$LIST_INITIAL\"
  t1=\$EPOCHREALTIME
  diff=\$(( (t1 - t0) * 1000 ))
  echo \"\$P1_LOADED:\$P2_LOADED:\$_zload_bundle_loaded:\$diff\"
")

IFS=':' read -r p1 p2 loaded duration <<< "$WARM_RESULT"
[[ "$p1" == "1" ]] || { echo "FAIL: P1 not loaded on warm run"; exit 1; }
[[ "$p2" == "1" ]] || { echo "FAIL: P2 not loaded on warm run"; exit 1; }
[[ "$loaded" == "1" ]] || { echo "FAIL: bundle was not loaded on warm run"; exit 1; }

printf "Warm startup time (including sourcing zload.zsh): %.3f ms\n" "$duration"

# Assert duration is well under budget (< 5ms on any machine, typically < 1ms)
if (( duration > 10.0 )); then
  echo "FAIL: warm startup took too long ($duration ms > 10.0 ms)"
  exit 1
fi

# 3. Cache Invalidation: Add p3 to list
LIST_UPDATED="$SANDBOX/p1
$SANDBOX/p2
$SANDBOX/p3"

INVALIDATION_RESULT=$(zsh -c "
  export XDG_DATA_HOME=\"$XDG_DATA_HOME\"
  export XDG_CACHE_HOME=\"$XDG_CACHE_HOME\"
  source ./zload.zsh
  zload \"$LIST_UPDATED\"
  echo \"\$P1_LOADED:\$P2_LOADED:\$P3_LOADED\"
")

IFS=':' read -r ip1 ip2 ip3 <<< "$INVALIDATION_RESULT"
[[ "$ip1" == "1" && "$ip2" == "1" && "$ip3" == "1" ]] || {
  echo "FAIL: cache invalidation did not load all 3 plugins ($ip1, $ip2, $ip3)"
  exit 1
}

echo "PASS: test_warm_startup (warm load < budget, cache invalidation verified)"
