#!/usr/bin/env zsh
set -e
zmodload zsh/zpty

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'zpty -d z 2>/dev/null; rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"
export HOME="$SANDBOX/home"
mkdir -p "$HOME" "$SANDBOX/plug" "$SANDBOX/zd"

fail() {
  echo "FAIL: $1"
  exit 1
}

cat >"$SANDBOX/plug/plug.plugin.zsh" <<'PLUG'
print DEFERRED-RAN
export DEF_OK=1
PLUG

cat >"$SANDBOX/zd/.zshrc" <<RC
PROMPT='READY> '
ZLOAD_NO_COMPINIT=1
source ${(q)PWD}/zload.zsh
zload ${(q)SANDBOX}/plug --defer
print AFTER-ZLOAD
RC

# Starts an interactive shell on a pty and returns everything it printed in $out.
run_interactive() {
  local chunk
  integer i
  out=""
  zpty z env ZDOTDIR="$SANDBOX/zd" HOME="$HOME" zsh -o no_global_rcs -i
  for ((i = 0; i < 40; i++)); do
    if zpty -r -t z chunk 2>/dev/null; then out+="$chunk"; else sleep 0.1; fi
    [[ "$out" == *DEFERRED-RAN* ]] && break
  done
  zpty -w z '[[ -t 2 ]] && print STDERR_${:-TTY}; print DEF_OK=$DEF_OK'
  for ((i = 0; i < 20; i++)); do
    if zpty -r -t z chunk 2>/dev/null; then out+="$chunk"; else sleep 0.1; fi
    [[ "$out" == *DEF_OK=1* ]] && break
  done
  zpty -w z 'exit'
  zpty -d z 2>/dev/null || true
}

check() {
  local label="$1" before after
  [[ "$out" == *AFTER-ZLOAD* ]] || fail "$label: shell did not finish startup: $out"
  [[ "$out" == *DEFERRED-RAN* ]] || fail "$label: deferred plugin never ran: $out"
  before="${out%%DEFERRED-RAN*}"
  [[ "$before" == *"READY> "* ]] || fail "$label: plugin ran before the first prompt was drawn: $out"
  [[ "$out" == *DEF_OK=1* ]] || fail "$label: deferred plugin's environment missing: $out"
  [[ "$out" == *STDERR_TTY* ]] || fail "$label: shell stderr no longer attached to the terminal: $out"
}

# Cold start (installs/compiles), then warm start (sources the bundle).
run_interactive
check cold
[[ -f "$XDG_CACHE_HOME/zload/bundle.zsh" ]] || fail "bundle not written"
run_interactive
check warm

echo "PASS: test_defer_prompt (deferred plugins load after the first prompt on cold and warm starts)"
