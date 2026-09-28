#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

MOCK_HOME="$SANDBOX/home"
mkdir -p "$MOCK_HOME"

CURRENT_REPO="$PWD"

# Run install.sh pointing to local repository
HOME="$MOCK_HOME" \
ZLOAD_HOME="$MOCK_HOME/.zload" \
ZLOAD_REPO="file://$CURRENT_REPO" \
./install.sh >/dev/null

# Sync working tree changes into test installation
cp -R zload.zsh zload.plugin.zsh functions "$MOCK_HOME/.zload/"
zsh -c "source '$MOCK_HOME/.zload/zload.zsh' && zload compile" >/dev/null 2>&1

# Assert installation directory
[[ -d "$MOCK_HOME/.zload" ]] || { echo "FAIL: .zload not installed"; exit 1; }
[[ -f "$MOCK_HOME/.zload/zload.zsh" ]] || { echo "FAIL: zload.zsh not installed"; exit 1; }
[[ -f "$MOCK_HOME/.zload/zload.zsh.zwc" ]] || { echo "FAIL: zload.zsh.zwc not compiled"; exit 1; }

# Assert .zshrc hook
grep -Fq "zload.zsh" "$MOCK_HOME/.zshrc" || { echo "FAIL: .zshrc missing zload hook"; exit 1; }

echo "PASS: test_installer (standalone installer execution, compilation, and hook setup)"
