#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"

source ./zload.zsh

# Create mock monorepo with multiple plugins in subdirectories
MONOREPO="$SANDBOX/my-monorepo"
mkdir -p "$MONOREPO/plugins/pkg_alpha" "$MONOREPO/plugins/pkg_beta"

cat << 'EOF' > "$MONOREPO/plugins/pkg_alpha/pkg_alpha.plugin.zsh"
export ALPHA_LOADED=1
EOF

cat << 'EOF' > "$MONOREPO/plugins/pkg_beta/pkg_beta.plugin.zsh"
export BETA_LOADED=1
EOF

# Load only pkg_alpha using --path
zload "$MONOREPO" --path "plugins/pkg_alpha"

[[ "$ALPHA_LOADED" == "1" ]] || { echo "FAIL: pkg_alpha not loaded via --path"; exit 1; }
[[ -z "$BETA_LOADED" ]] || { echo "FAIL: pkg_beta was loaded unintentionally"; exit 1; }

# Load pkg_beta using --path
zload "$MONOREPO" --path "plugins/pkg_beta"
[[ "$BETA_LOADED" == "1" ]] || { echo "FAIL: pkg_beta not loaded via --path"; exit 1; }

echo "PASS: test_subpath (monorepo subpath targeting with --path)"
