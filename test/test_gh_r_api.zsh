#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"
export HOME="$SANDBOX/home"
mkdir -p "$HOME" "$SANDBOX/bin" "$SANDBOX/assets"

fail() {
  echo "FAIL: $1"
  exit 1
}

# Release assets for every OS/arch combination; only the host's should be chosen.
for os in darwin linux; do
  for arch in arm64 x86_64; do
    name="tool-${os}-${arch}"
    mkdir -p "$SANDBOX/pkg_$name"
    printf '#!/bin/sh\necho %s\n' "$name" >"$SANDBOX/pkg_$name/tool"
    chmod +x "$SANDBOX/pkg_$name/tool"
    tar -czf "$SANDBOX/assets/$name.tar.gz" -C "$SANDBOX/pkg_$name" tool
  done
done

if [[ "${(L)OSTYPE}" == darwin* ]]; then HOST_OS=darwin; else HOST_OS=linux; fi
if [[ "${(L)CPUTYPE}" == *(arm64|aarch64)* ]]; then HOST_ARCH=arm64; else HOST_ARCH=x86_64; fi
HOST_ASSET="tool-${HOST_OS}-${HOST_ARCH}"

# Fake curl: serves a GitHub-style release JSON and local assets; logs every call.
cat >"$SANDBOX/bin/curl" <<FAKE
#!/bin/sh
echo "\$*" >>"$SANDBOX/curl.log"
out=""; url=""
while [ \$# -gt 0 ]; do
  case "\$1" in
    -o) out="\$2"; shift 2 ;;
    -H) shift 2 ;;
    -*) shift ;;
    *) url="\$1"; shift ;;
  esac
done
case "\$url" in
  https://api.github.com/*)
    [ -f "$SANDBOX/release.json" ] || exit 22
    cat "$SANDBOX/release.json" ;;
  *.sha256)
    cat "$SANDBOX/sums/\${url##*/}" ;;
  https://example.test/dl/*)
    cp "$SANDBOX/assets/\${url##*/}" "\$out" ;;
  *) exit 22 ;;
esac
FAKE
chmod +x "$SANDBOX/bin/curl"
export PATH="$SANDBOX/bin:$PATH"

write_release() {
  local sums="$1" first=1 f
  {
    echo '{"tag_name": "v1", "assets": ['
    for f in "$SANDBOX"/assets/*.tar.gz; do
      ((first)) || echo ','
      first=0
      printf '{"name": "%s", "browser_download_url": "https://example.test/dl/%s"}' "${f:t}" "${f:t}"
    done
    [[ -n "$sums" ]] && printf ',{"name": "x.sha256", "browser_download_url": "https://example.test/dl/%s.tar.gz.sha256"}' "$HOST_ASSET"
    echo ']}'
  } >"$SANDBOX/release.json"
}

source ./zload.zsh

install_host() {
  local -A spec
  rm -rf "$ZLOAD_PLUGINS"/gh-r---*(N)
  _zload_parse_spec spec "mock/tool --from gh-r"
  _zload_install_gh_r spec >/dev/null 2>"$SANDBOX/err"
}

# 1. Picks the host asset from the API listing and verifies a bare-hash .sha256 file.
mkdir -p "$SANDBOX/sums"
_zload_sha256 "$SANDBOX/assets/$HOST_ASSET.tar.gz"
print -r -- "$REPLY" >"$SANDBOX/sums/$HOST_ASSET.tar.gz.sha256"
write_release sums
install_host || fail "install failed: $(<"$SANDBOX/err")"
[[ "$("$ZLOAD_PLUGINS/gh-r---mock---tool/bin/tool")" == "$HOST_ASSET" ]] || fail "wrong asset installed"

# 2. A wrong published checksum is rejected and nothing is installed.
print -r -- "$(printf '0%.0s' {1..64})  $HOST_ASSET.tar.gz" >"$SANDBOX/sums/$HOST_ASSET.tar.gz.sha256"
if install_host; then fail "checksum mismatch accepted"; fi
[[ ! -e "$ZLOAD_PLUGINS/gh-r---mock---tool" ]] || fail "rejected release left files behind"

# 3. No matching asset is an error, not a guess.
rm -f "$SANDBOX/assets/$HOST_ASSET.tar.gz"
write_release ""
if install_host; then fail "installed an asset that does not match this host"; fi
grep -q "matches" "$SANDBOX/err" || fail "missing no-match message: $(<"$SANDBOX/err")"

# 4. GITHUB_TOKEN is sent to the API.
: >"$SANDBOX/curl.log"
GITHUB_TOKEN=tok123 install_host || true
grep -q "Authorization: Bearer tok123" "$SANDBOX/curl.log" || fail "token not sent: $(<"$SANDBOX/curl.log")"

echo "PASS: test_gh_r_api (release listing, host asset match, checksum, no-match error, token)"
