#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"

source ./zload.zsh

# Create mock repository requiring a build step
SRC_DIR="$SANDBOX/buildable-src"
BARE_DIR="$SANDBOX/buildable.git"
mkdir -p "$SRC_DIR"
git -C "$SRC_DIR" init -q -b main
git -C "$SRC_DIR" config user.email "test@zload.test"
git -C "$SRC_DIR" config user.name "Zload Test"

cat <<'EOF' >"$SRC_DIR/tool.plugin.zsh"
export TOOL_INSTALLED=1
EOF

git -C "$SRC_DIR" add .
git -C "$SRC_DIR" commit -q -m "initial"
git clone --bare -q "$SRC_DIR" "$BARE_DIR"

# Install with --build hook
zload "file://$BARE_DIR" --build "echo 'export BUILT_ARTIFACT=1' > artifact.zsh"

local -A spec_info
_zload_parse_spec spec_info "file://$BARE_DIR"
CLONED_DIR="${spec_info[dir]}"
ARTIFACT="$CLONED_DIR/artifact.zsh"

[[ -f "$ARTIFACT" ]] || {
  echo "FAIL: artifact.zsh was not created by --build hook"
  exit 1
}
[[ "$(<"$ARTIFACT")" == *"BUILT_ARTIFACT=1"* ]] || {
  echo "FAIL: artifact.zsh has unexpected content"
  exit 1
}
# Push new commit to test rebuild on update
cat <<'EOF' >"$SRC_DIR/tool.plugin.zsh"
export TOOL_INSTALLED=2
EOF
git -C "$SRC_DIR" commit -q -am "v2"
git -C "$SRC_DIR" push -q "$BARE_DIR" main

# Remove artifact to prove update rebuilds it
rm -f "$ARTIFACT"

# Run zload update
zload update >/dev/null

[[ -f "$ARTIFACT" ]] || {
  echo "FAIL: artifact.zsh was not re-created on update by --build hook"
  exit 1
}
[[ "$(<"$ARTIFACT")" == *"BUILT_ARTIFACT=1"* ]] || {
  echo "FAIL: rebuilt artifact has unexpected content"
  exit 1
}

echo "PASS: test_build (post-install and post-update build hook execution)"
