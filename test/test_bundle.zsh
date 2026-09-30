#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"

source ./zload.zsh

# Create two mock plugins
mkdir -p "$SANDBOX/p1" "$SANDBOX/p2/bin" "$SANDBOX/p2/completions"
cat <<'EOF' >"$SANDBOX/p1/p1.plugin.zsh"
export P1_BUNDLE_LOADED=1
EOF

cat <<'EOF' >"$SANDBOX/p2/p2.plugin.zsh"
export P2_BUNDLE_LOADED=1
EOF
touch "$SANDBOX/p2/completions/_p2"
touch "$SANDBOX/p2/bin/p2tool"
chmod +x "$SANDBOX/p2/bin/p2tool"

# Compile bundle
_zload_compile_bundle "$SANDBOX/p1" "$SANDBOX/p2"

BUNDLE_FILE="${ZLOAD_CACHE}/bundle.zsh"
BUNDLE_ZWC="${ZLOAD_CACHE}/bundle.zsh.zwc"
BUNDLE_HASH="${ZLOAD_CACHE}/bundle.hash"

[[ -f "$BUNDLE_FILE" ]] || {
  echo "FAIL: bundle.zsh not found"
  exit 1
}
[[ -f "$BUNDLE_ZWC" ]] || {
  echo "FAIL: bundle.zsh.zwc not found"
  exit 1
}
[[ -f "$BUNDLE_HASH" ]] || {
  echo "FAIL: bundle.hash not found"
  exit 1
}

# Clear environment and test sourcing compiled bundle directly
unset P1_BUNDLE_LOADED P2_BUNDLE_LOADED
source "$BUNDLE_FILE"

[[ "$P1_BUNDLE_LOADED" == "1" ]] || {
  echo "FAIL: P1 not loaded from bundle"
  exit 1
}
[[ "$P2_BUNDLE_LOADED" == "1" ]] || {
  echo "FAIL: P2 not loaded from bundle"
  exit 1
}
[[ "$_zload_bundle_loaded" == "1" ]] || {
  echo "FAIL: _zload_bundle_loaded not set"
  exit 1
}
[[ "$path" == *"$SANDBOX/p2/bin"* ]] || {
  echo "FAIL: bin not in path from bundle"
  exit 1
}
[[ "$fpath" == *"$SANDBOX/p2/completions"* ]] || {
  echo "FAIL: completions not in fpath from bundle"
  exit 1
}

echo "PASS: test_bundle (bundle generation, zwc bytecode compilation, and direct sourcing)"
