#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"

source ./zload.zsh

# Create mock release tarball with binary
SRC_DIR="$SANDBOX/pkg_src"
mkdir -p "$SRC_DIR"
cat <<'EOF' >"$SRC_DIR/my_binary"
#!/bin/sh
echo "my_binary_v1_output"
EOF
chmod +x "$SRC_DIR/my_binary"

ARCHIVE_TAR="$SANDBOX/tool_v1.tar.gz"
tar -czf "$ARCHIVE_TAR" -C "$SRC_DIR" my_binary

# Mock _zload_install_gh_r downloading step to use the local archive
local -A spec
_zload_parse_spec spec "mock/tool" --from gh-r
spec[url]="file://$ARCHIVE_TAR"

_zload_install_gh_r spec
_zload_load_plugin spec

# 1. Assert binary exists in bin/
BIN_DIR="${ZLOAD_PLUGINS}/gh-r---mock---tool/bin"
[[ -x "$BIN_DIR/my_binary" ]] || {
  echo "FAIL: my_binary not installed in bin"
  exit 1
}

# 2. Assert bin/ is in PATH
[[ "$path[1]" == "$BIN_DIR" ]] || {
  echo "FAIL: bin not prepended to PATH"
  exit 1
}

# 3. Assert binary executes through PATH
RES="$(my_binary)"
[[ "$RES" == "my_binary_v1_output" ]] || {
  echo "FAIL: binary execution returned '$RES'"
  exit 1
}

# 4. Assert bundle integration
_zload_specs+=("mock/tool --from gh-r")
zload compile >/dev/null
unset path
path=("/usr/bin" "/bin")
source "$ZLOAD_CACHE/bundle.zsh"
[[ "$path" == *"$BIN_DIR"* ]] || {
  echo "FAIL: bin not in PATH from bundle"
  exit 1
}

echo "PASS: test_gh_r (GitHub Releases binary extraction, PATH export, and bundle compiling)"
