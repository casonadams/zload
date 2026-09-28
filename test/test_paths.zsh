#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"

source ./zload.zsh

# Create mock path directories
DIR_BIN1="$SANDBOX/bin1"
DIR_BIN2="$SANDBOX/bin2"
DIR_COMP1="$SANDBOX/completions1"
mkdir -p "$DIR_BIN1" "$DIR_BIN2" "$DIR_COMP1"

# 1. Test zload path
zload path "$DIR_BIN1" "$DIR_BIN2"

[[ "${path[1]}" == "$DIR_BIN1" ]] || { echo "FAIL: DIR_BIN1 not prepended to path"; exit 1; }
[[ "${path[2]}" == "$DIR_BIN2" ]] || { echo "FAIL: DIR_BIN2 not in path"; exit 1; }

# Test deduplication
zload path "$DIR_BIN1"
integer count=0
for p in "${path[@]}"; do
  [[ "$p" == "$DIR_BIN1" ]] && (( ++count ))
done
[[ "$count" == "1" ]] || { echo "FAIL: path was not deduplicated (count=$count)"; exit 1; }

# 2. Test zload fpath
zload fpath "$DIR_COMP1"
[[ "${fpath[1]}" == "$DIR_COMP1" ]] || { echo "FAIL: DIR_COMP1 not prepended to fpath"; exit 1; }

# Test fpath deduplication
zload fpath "$DIR_COMP1"
integer fcount=0
for fp in "${fpath[@]}"; do
  [[ "$fp" == "$DIR_COMP1" ]] && (( ++fcount ))
done
[[ "$fcount" == "1" ]] || { echo "FAIL: fpath was not deduplicated (count=$fcount)"; exit 1; }

echo "PASS: test_paths (path and fpath prepend and deduplication helpers)"
