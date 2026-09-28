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

echo 'export ZLOAD_VERSION="0.1.0"' > "$MOCK_SRC/version.zsh"
git -C "$MOCK_SRC" add .
git -C "$MOCK_SRC" commit -q -m "v0.1.0"
git clone --bare -q "$MOCK_SRC" "$MOCK_BARE"

# Clone mock zload to sandbox
LOCAL_ZLOAD="$SANDBOX/local_zload"
git clone --depth 1 -q "file://$MOCK_BARE" "$LOCAL_ZLOAD"
cp -R functions "$LOCAL_ZLOAD/"
cp zload.zsh "$LOCAL_ZLOAD/"

# Push new commit to remote
echo 'export ZLOAD_VERSION="0.1.1"' > "$MOCK_SRC/version.zsh"
git -C "$MOCK_SRC" commit -q -am "v0.1.1"
git -C "$MOCK_SRC" push -q "$MOCK_BARE" main
NEW_COMMIT="$(git -C "$MOCK_SRC" rev-parse --short HEAD)"

# Run zload upgrade
ZLOAD_HOME="$LOCAL_ZLOAD" zsh -c "
  export XDG_DATA_HOME=\"$XDG_DATA_HOME\"
  export XDG_CACHE_HOME=\"$XDG_CACHE_HOME\"
  source \"$LOCAL_ZLOAD/zload.zsh\"
  zload upgrade
" >/dev/null

# Assert local clone was updated to new commit
UPDATED_COMMIT="$(git -C "$LOCAL_ZLOAD" rev-parse --short HEAD)"
[[ "$UPDATED_COMMIT" == "$NEW_COMMIT" ]] || {
  echo "FAIL: zload upgrade did not advance to new commit ($UPDATED_COMMIT != $NEW_COMMIT)"
  exit 1
}

echo "PASS: test_upgrade (self-upgrade and module recompilation verified)"
