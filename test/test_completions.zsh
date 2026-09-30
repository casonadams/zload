#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"

source ./zload.zsh

# 1. Assert _zload completion file exists in functions/ and has #compdef
COMP_FILE="${ZLOAD_HOME}/functions/_zload"
[[ -f "$COMP_FILE" ]] || {
  echo "FAIL: functions/_zload does not exist"
  exit 1
}

FIRST_LINE="$(head -n 1 "$COMP_FILE")"
[[ "$FIRST_LINE" == *"#compdef zload"* ]] || {
  echo "FAIL: functions/_zload missing #compdef header ($FIRST_LINE)"
  exit 1
}

# 2. Assert all subcommands are documented in completion definition
for cmd in update clean list doctor profile compile eval path fpath which cd compinit help; do
  grep -q "'$cmd:" "$COMP_FILE" || {
    echo "FAIL: command '$cmd' missing from _zload completion definition"
    exit 1
  }
done

# 3. Assert flags are included in completion definition
for flag in --on --defer --bin --path --build --on-dir --from; do
  grep -Fq -- "$flag" "$COMP_FILE" || {
    echo "FAIL: flag '$flag' missing from _zload completion definition"
    exit 1
  }
done

echo "PASS: test_completions (zload autocompletion file and syntax definition verified)"
