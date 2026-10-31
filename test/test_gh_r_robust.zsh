#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"

source ./zload.zsh

fail() {
  echo "FAIL: $1"
  exit 1
}

# 1. A failed install must not leave a directory behind (it would mask the failure forever).
local -A bad
_zload_parse_spec bad "mock/missing" --from gh-r
bad[url]="file://$SANDBOX/does-not-exist.tar.gz"
if _zload_install_gh_r bad 2>/dev/null; then
  fail "install of a missing asset reported success"
fi
[[ ! -e "${bad[dir]}" ]] || fail "failed gh-r install left ${bad[dir]} behind"
[[ -z "$(print -l "${ZLOAD_PLUGINS}"/*.tmp.*(N))" ]] || fail "temp directory leaked"

# 2. An archive without executables is an error, not a silent empty install.
mkdir -p "$SANDBOX/noexec"
echo "data" >"$SANDBOX/noexec/README"
tar -czf "$SANDBOX/noexec.tar.gz" -C "$SANDBOX/noexec" README
local -A empty
_zload_parse_spec empty "mock/empty" --from gh-r
empty[url]="file://$SANDBOX/noexec.tar.gz"
if _zload_install_gh_r empty 2>/dev/null; then
  fail "archive without executables reported success"
fi
[[ ! -e "${empty[dir]}" ]] || fail "no-executable install left a directory"

# 3. A bare (non-archive) asset is installed under the repository name.
printf '#!/bin/sh\necho bare-ok\n' >"$SANDBOX/tool-darwin-arm64"
local -A bare
_zload_parse_spec bare "mock/tool" --from gh-r
bare[url]="file://$SANDBOX/tool-darwin-arm64"
_zload_install_gh_r bare >/dev/null || fail "bare asset install failed"
[[ -x "${bare[dir]}/bin/tool" ]] || fail "bare asset not installed as 'tool'"
[[ "$("${bare[dir]}/bin/tool")" == "bare-ok" ]] || fail "installed bare binary does not run"

# 4. Re-running is a no-op once executables exist.
touch -t 202001010000 "${bare[dir]}/bin/tool"
_zload_install_gh_r bare >/dev/null
[[ "$(stat -f %Sm -t %Y "${bare[dir]}/bin/tool")" == 2020 ]] || fail "existing install was rewritten"

echo "PASS: test_gh_r_robust (atomic install, empty-archive error, bare asset naming)"
