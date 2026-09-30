#!/usr/bin/env zsh
set -e

# 1. Assert man file exists and contains valid troff macro header
MAN_FILE="man/man1/zload.1"
[[ -f "$MAN_FILE" ]] || {
  echo "FAIL: man/man1/zload.1 missing"
  exit 1
}

FIRST_LINE="$(head -n 1 "$MAN_FILE")"
[[ "$FIRST_LINE" == *".TH ZLOAD 1"* ]] || {
  echo "FAIL: unexpected troff header: $FIRST_LINE"
  exit 1
}

# 2. Test manpath registration and man page resolution
source ./zload.zsh

if ((! ${manpath[(Ie)${ZLOAD_HOME}/man]})); then
  echo "FAIL: ZLOAD_HOME/man not added to manpath"
  exit 1
fi

# 3. Assert man finds zload if man is available
if (($+commands[man])); then
  RESOLVED_MAN="$(man -w zload 2>/dev/null || man -M "${ZLOAD_HOME}/man" -w zload 2>/dev/null || true)"
  if [[ -n "$RESOLVED_MAN" ]]; then
    [[ "$RESOLVED_MAN" == *"$MAN_FILE"* ]] || {
      echo "FAIL: man -w zload resolved to unexpected path ($RESOLVED_MAN)"
      exit 1
    }
  fi
fi

echo "PASS: test_man (man page troff header, manpath registration, and man resolution)"
