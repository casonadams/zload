#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"

MOCK_HOME="$SANDBOX/mock_home"
mkdir -p "$MOCK_HOME/.zfunc"
touch "$MOCK_HOME/.zfunc/_custom_tool"

# Source zload in environment with ~/.zfunc present
HOME="$MOCK_HOME" zsh -c "
  export XDG_DATA_HOME=\"$XDG_DATA_HOME\"
  export XDG_CACHE_HOME=\"$XDG_CACHE_HOME\"
  export HOME=\"$MOCK_HOME\"
  source ./zload.zsh

  if (( ! \${fpath[(Ie)\$HOME/.zfunc]} )); then
    echo 'FAIL: ~/.zfunc was not automatically added to fpath'
    exit 1
  fi
"

echo "PASS: test_zfunc (automatic discovery and inclusion of ~/.zfunc in fpath)"
