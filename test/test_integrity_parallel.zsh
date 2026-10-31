#!/usr/bin/env zsh
set -e
setopt extended_glob

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"
export HOME="$SANDBOX/home"
export ZLOAD_NO_COMPINIT=1
mkdir -p "$HOME"

source ./zload.zsh

fail() {
  echo "FAIL: $1"
  exit 1
}

# 1. Snippet integrity: right hash installs, wrong hash is rejected and leaves nothing.
echo 'export SNIP=1' >"$SANDBOX/snip.zsh"
_zload_sha256 "$SANDBOX/snip.zsh"
GOOD="$REPLY"
[[ "$GOOD" == [0-9a-f](#c64) ]] || fail "sha256 helper returned '$GOOD'"

local -A good bad
_zload_parse_spec good "file://$SANDBOX/snip.zsh --sha256 $GOOD"
_zload_install good >/dev/null 2>&1 || fail "snippet with correct sha256 rejected"
[[ -f "${good[dir]}/${good[subpath]}" ]] || fail "snippet not written"

echo 'export SNIP=2' >"$SANDBOX/snip2.zsh"
_zload_parse_spec bad "file://$SANDBOX/snip2.zsh --sha256 $GOOD"
if _zload_install bad >/dev/null 2>&1; then fail "snippet with wrong sha256 accepted"; fi
[[ ! -e "${bad[dir]}" ]] || fail "rejected snippet left files behind"

# 2. Release assets honor --sha256 too.
printf '#!/bin/sh\necho ok\n' >"$SANDBOX/rel-tool"
_zload_sha256 "$SANDBOX/rel-tool"
RELSUM="$REPLY"
local -A rel_bad rel_ok
_zload_parse_spec rel_bad "mock/relbad --from gh-r --sha256 $GOOD"
rel_bad[url]="file://$SANDBOX/rel-tool"
if _zload_install_gh_r rel_bad >/dev/null 2>&1; then fail "gh-r asset with wrong sha256 accepted"; fi
[[ ! -e "${rel_bad[dir]}" ]] || fail "rejected gh-r asset left files behind"
_zload_parse_spec rel_ok "mock/relok --from gh-r --sha256 $RELSUM"
rel_ok[url]="file://$SANDBOX/rel-tool"
_zload_install_gh_r rel_ok >/dev/null 2>&1 || fail "gh-r asset with correct sha256 rejected"

# 3. Several remote plugins install together; failures are attributed to the right entry.
for n in one two three; do
  mkdir -p "$SANDBOX/src_$n"
  git -C "$SANDBOX/src_$n" init -q -b main
  git -C "$SANDBOX/src_$n" config user.email t@zload.test
  git -C "$SANDBOX/src_$n" config user.name t
  echo "export LOADED_$n=1" >"$SANDBOX/src_$n/$n.plugin.zsh"
  git -C "$SANDBOX/src_$n" add . && git -C "$SANDBOX/src_$n" commit -q -m init
done
if zsh -c "source ${(q)PWD}/zload.zsh; zload file://$SANDBOX/src_one file://$SANDBOX/src_two file://$SANDBOX/src_missing file://$SANDBOX/src_three; print one=\$LOADED_one two=\$LOADED_two three=\$LOADED_three" >"$SANDBOX/out" 2>"$SANDBOX/err"; then :; fi
grep -q "one=1 two=1 three=1" "$SANDBOX/out" || fail "plugins not all loaded: $(<"$SANDBOX/out")"
[[ "$(grep -c "failed to install" "$SANDBOX/err")" == 1 ]] || fail "expected exactly one failure message: $(<"$SANDBOX/err")"
grep -q "src_missing" "$SANDBOX/err" || fail "failure not attributed to the missing repo"
[[ ! -f "$XDG_CACHE_HOME/zload/bundle.zsh" ]] || fail "bundle written despite an install failure"

# 4. SSH-style git URLs keep their host and honor refs.
local -A ssh
_zload_parse_spec ssh "git@github.com:foo/bar.git@v1.2"
[[ "${ssh[url]}" == "git@github.com:foo/bar.git" && "${ssh[ref]}" == "v1.2" ]] || fail "ssh spec parsed as ${ssh[url]} @ ${ssh[ref]}"

echo "PASS: test_integrity_parallel (sha256 checks, concurrent installs, ssh spec parsing)"
