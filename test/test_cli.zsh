#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"

source ./zload.zsh

# 1. Test help
HELP_OUT=$(zload help)
[[ "$HELP_OUT" == *"Usage:"* ]] || { echo "FAIL: zload help missing Usage"; exit 1; }

# 2. Test list when empty
LIST_EMPTY=$(zload list)
[[ "$LIST_EMPTY" == *"(no plugins installed)"* ]] || { echo "FAIL: zload list not reporting empty"; exit 1; }

# 3. Create active plugin and unused plugin
mkdir -p "$ZLOAD_PLUGINS/active-plugin"
cat << 'EOF' > "$ZLOAD_PLUGINS/active-plugin/active.plugin.zsh"
export ACTIVE_LOADED=1
EOF

mkdir -p "$ZLOAD_PLUGINS/unused-plugin"

# Load active plugin
zload "$ZLOAD_PLUGINS/active-plugin"

# Test list with installed plugin
LIST_OUT=$(zload list)
[[ "$LIST_OUT" == *"active-plugin"* ]] || { echo "FAIL: active-plugin not in list"; exit 1; }

# 4. Test clean without force (dry run)
CLEAN_DRY=$(zload clean)
[[ "$CLEAN_DRY" == *"unused-plugin"* ]] || { echo "FAIL: dry clean did not find unused-plugin"; exit 1; }
[[ -d "$ZLOAD_PLUGINS/unused-plugin" ]] || { echo "FAIL: dry clean removed directory"; exit 1; }

# Test clean with force
zload clean -f >/dev/null
[[ ! -d "$ZLOAD_PLUGINS/unused-plugin" ]] || { echo "FAIL: clean -f did not delete unused-plugin"; exit 1; }
[[ -d "$ZLOAD_PLUGINS/active-plugin" ]] || { echo "FAIL: clean -f deleted active plugin"; exit 1; }

# 5. Test compile
zload compile >/dev/null
[[ -f "$ZLOAD_CACHE/bundle.zsh.zwc" ]] || { echo "FAIL: zload compile did not produce zwc"; exit 1; }

echo "PASS: test_cli (help, list, clean dry-run & force, compile)"
