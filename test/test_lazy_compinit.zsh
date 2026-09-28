#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"

source ./zload.zsh

# 1. Test compdef buffering prior to compinit
zload compinit --lazy

# Simulate a plugin calling compdef
compdef _my_tool my_tool
compdef _git g

[[ "${#_zload_deferred_compdefs}" == "2" ]] || {
  echo "FAIL: expected 2 deferred compdefs, got ${#_zload_deferred_compdefs}"
  exit 1
}

# 2. Trigger real compinit execution
_zload_real_compinit

# Verify real compdef is active (not our stub)
typeset -f compdef >/dev/null || { echo "FAIL: real compdef not defined"; exit 1; }
[[ "${#_zload_deferred_compdefs}" == "0" ]] || { echo "FAIL: deferred compdefs not drained"; exit 1; }

# Verify zcompdump and zcompdump.zwc are generated
DUMP_FILE="${ZLOAD_CACHE}/zcompdump-${ZSH_VERSION}"
[[ -f "$DUMP_FILE" ]] || { echo "FAIL: dump file $DUMP_FILE was not created"; exit 1; }
[[ -f "${DUMP_FILE}.zwc" ]] || { echo "FAIL: dump file zwc was not created"; exit 1; }

# 3. Verify idempotency
_zload_real_compinit
[[ "$_zload_compinit_done" == "1" ]] || { echo "FAIL: _zload_compinit_done is not 1"; exit 1; }

echo "PASS: test_lazy_compinit (compdef buffering, compinit deferral, bytecode dump)"
