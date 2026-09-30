#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"

# Create mock zload remote repo
MOCK_SRC="$SANDBOX/zload_src"
MOCK_BARE="$SANDBOX/zload_bare.git"
mkdir -p "$MOCK_SRC"
git -C "$MOCK_SRC" init -q -b main
git -C "$MOCK_SRC" config user.email "test@zload.test"
git -C "$MOCK_SRC" config user.name "Zload Test"
cp -R functions "$MOCK_SRC/"
cp zload.zsh "$MOCK_SRC/"
echo 'export ZLOAD_VERSION="0.1.0"' >"$MOCK_SRC/version.zsh"
git -C "$MOCK_SRC" add .
git -C "$MOCK_SRC" commit -q -m "v0.1.0"
git clone --bare -q "$MOCK_SRC" "$MOCK_BARE"

# Clone mock zload to sandbox
LOCAL_ZLOAD="$SANDBOX/local_zload"
git clone -q "file://$MOCK_BARE" "$LOCAL_ZLOAD"

# Create pre-existing cache file to assert it gets cleared
mkdir -p "$XDG_CACHE_HOME/zload"
echo "old-cache" >"$XDG_CACHE_HOME/zload/bundle.zsh"
echo "old-hash" >"$XDG_CACHE_HOME/zload/bundle.hash"

echo 'export ZLOAD_VERSION="0.1.1"' >"$MOCK_SRC/version.zsh"
cat <<'EOF' >"$MOCK_SRC/functions/_zload_cmd_help"
_zload_cmd_help() {
  echo "zload v2 help message"
}
EOF
git -C "$MOCK_SRC" commit -q -am "v0.1.1"
git -C "$MOCK_SRC" push -q "$MOCK_BARE" main
NEW_COMMIT="$(git -C "$MOCK_SRC" rev-parse --short HEAD)"

# Run zload upgrade in a subshell and check active session reload
UPGRADE_OUT=$(ZLOAD_HOME="$LOCAL_ZLOAD" zsh -c "
  unset ZSH
  export XDG_DATA_HOME=\"$XDG_DATA_HOME\"
  export XDG_CACHE_HOME=\"$XDG_CACHE_HOME\"
  source \"$LOCAL_ZLOAD/zload.zsh\"
  zload help
  zload upgrade >/dev/null
  zload help
")

# Assert local clone was updated to new commit
UPDATED_COMMIT="$(git -C "$LOCAL_ZLOAD" rev-parse --short HEAD)"
[[ "$UPDATED_COMMIT" == "$NEW_COMMIT" ]] || {
  echo "FAIL: zload upgrade did not advance to new commit ($UPDATED_COMMIT != $NEW_COMMIT)"
  exit 1
}

# Assert bytecode was compiled
[[ -f "$LOCAL_ZLOAD/zload.zsh.zwc" ]] || {
  echo "FAIL: zload.zsh.zwc was not compiled by upgrade"
  exit 1
}
[[ -f "$LOCAL_ZLOAD/functions/_zload_cmd_clean.zwc" ]] || {
  echo "FAIL: functions/*.zwc was not compiled by upgrade"
  exit 1
}

# Assert cache directory was wiped
[[ ! -f "$XDG_CACHE_HOME/zload/bundle.zsh" ]] || {
  echo "FAIL: bundle.zsh was not cleared by upgrade"
  exit 1
}
[[ ! -f "$XDG_CACHE_HOME/zload/bundle.hash" ]] || {
  echo "FAIL: bundle.hash was not cleared by upgrade"
  exit 1
}

# Assert active session reloaded updated function
[[ "$UPGRADE_OUT" == *"Ultra-fast"* && "$UPGRADE_OUT" == *"zload v2 help message"* ]] || {
  echo "FAIL: active session did not reload updated function (output: $UPGRADE_OUT)"
  exit 1
}

# Test dirty working tree and force upgrade (-f)
echo 'export ZLOAD_VERSION="0.2.0-dirty"' >"$LOCAL_ZLOAD/version.zsh"
echo 'export ZLOAD_VERSION="0.2.0"' >"$MOCK_SRC/version.zsh"
git -C "$MOCK_SRC" commit -q -am "v0.2.0"
git -C "$MOCK_SRC" push -q "$MOCK_BARE" main

# Upgrade without -f should fail due to local modification
FAIL_OUT=$(ZLOAD_HOME="$LOCAL_ZLOAD" zsh -c "
  unset ZSH
  export XDG_DATA_HOME=\"$XDG_DATA_HOME\"
  export XDG_CACHE_HOME=\"$XDG_CACHE_HOME\"
  source \"$LOCAL_ZLOAD/zload.zsh\"
  zload upgrade 2>&1
" || true)

[[ "$FAIL_OUT" == *"failed to pull latest changes for zload"* ]] || {
  echo "FAIL: expected upgrade to fail on dirty working tree (output: $FAIL_OUT)"
  exit 1
}

# Upgrade with -f should succeed by discarding dirty state
ZLOAD_HOME="$LOCAL_ZLOAD" zsh -c "
  unset ZSH
  export XDG_DATA_HOME=\"$XDG_DATA_HOME\"
  export XDG_CACHE_HOME=\"$XDG_CACHE_HOME\"
  source \"$LOCAL_ZLOAD/zload.zsh\"
  zload upgrade -f >/dev/null
"

V2_COMMIT="$(git -C "$MOCK_SRC" rev-parse --short HEAD)"
LOCAL_V2_COMMIT="$(git -C "$LOCAL_ZLOAD" rev-parse --short HEAD)"
[[ "$LOCAL_V2_COMMIT" == "$V2_COMMIT" ]] || {
  echo "FAIL: zload upgrade -f did not advance to new commit ($LOCAL_V2_COMMIT != $V2_COMMIT)"
  exit 1
}

echo "PASS: test_upgrade (self-upgrade, module recompilation, cache wipe, and live reload verified)"
