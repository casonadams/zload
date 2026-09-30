#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"

mkdir -p "$SANDBOX/p1" "$SANDBOX/p2"
echo "export P1=1" >"$SANDBOX/p1/p1.plugin.zsh"
echo "export P2=1" >"$SANDBOX/p2/p2.plugin.zsh"

LIST_PLUGINS="$SANDBOX/p1
$SANDBOX/p2"

# 1. Cold run: install and compile bundle
zsh -c "
  export XDG_DATA_HOME=\"$XDG_DATA_HOME\"
  export XDG_CACHE_HOME=\"$XDG_CACHE_HOME\"
  source ./zload.zsh
  zload \"$LIST_PLUGINS\"
"

# 2. Setup poison bin directory with failing shims for all common external tools
mkdir -p "$SANDBOX/poison_bin"
for tool in git sed grep uname which find cut awk tr wc cat; do
  cat <<EOF >"$SANDBOX/poison_bin/$tool"
#!/bin/sh
echo "FORK_DETECTED: \$0 was invoked during warm startup!" >&2
exit 99
EOF
  chmod +x "$SANDBOX/poison_bin/$tool"
done

# 3. Execute warm launch with poisoned PATH
WARM_OUTPUT=$(zsh -c "
  export XDG_DATA_HOME=\"$XDG_DATA_HOME\"
  export XDG_CACHE_HOME=\"$XDG_CACHE_HOME\"
  export PATH=\"$SANDBOX/poison_bin:\$PATH\"
  source ./zload.zsh
  zload \"$LIST_PLUGINS\"
  echo \"SUCCESS:\$P1:\$P2:\$_zload_bundle_loaded\"
")

[[ "$WARM_OUTPUT" == "SUCCESS:1:1:1" ]] || {
  echo "FAIL: external utilities invoked during warm startup ($WARM_OUTPUT)"
  exit 1
}

echo "PASS: test_zero_forks (verified zero subprocess forks on warm interactive startup)"
