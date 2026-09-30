#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"

# Create mock plugins
mkdir -p "$SANDBOX/p1" "$SANDBOX/p2"
echo 'export P1=1' >"$SANDBOX/p1/p1.plugin.zsh"
echo 'export P2=1' >"$SANDBOX/p2/p2.plugin.zsh"

LIST_PLUGINS="$SANDBOX/p1
$SANDBOX/p2"

# Spawn 5 concurrent zload instances trying to compile bundle at the same time
pids=()
for i in {1..5}; do
  (
    export XDG_DATA_HOME="$XDG_DATA_HOME"
    export XDG_CACHE_HOME="$XDG_CACHE_HOME"
    source ./zload.zsh
    zload "$LIST_PLUGINS"
  ) &
  pids+=($!)
done

# Wait for all background workers
failed=0
for pid in "${pids[@]}"; do
  wait "$pid" || ((failed++))
done

[[ "$failed" == "0" ]] || {
  echo "FAIL: concurrent zload instances failed (failed count: $failed)"
  exit 1
}

# Assert bundle is compiled and valid
[[ -f "$XDG_CACHE_HOME/zload/bundle.zsh" ]] || {
  echo "FAIL: bundle.zsh missing after concurrent run"
  exit 1
}
[[ -f "$XDG_CACHE_HOME/zload/bundle.zsh.zwc" ]] || {
  echo "FAIL: bundle.zsh.zwc missing after concurrent run"
  exit 1
}

# Assert lock directory was released
[[ ! -d "$XDG_CACHE_HOME/zload/.compile.lock" ]] || {
  echo "FAIL: lock directory was not released"
  exit 1
}

echo "PASS: test_concurrency (multi-process concurrent compilation and lock release)"
