#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"

print -P "%F{cyan}========================================%f"
print -P "%F{cyan}       zload Startup Benchmark         %f"
print -P "%F{cyan}========================================%f\n"

# Create 10 mock plugins
mkdir -p "$SANDBOX/plugins"
local -a plugin_paths
for i in {1..10}; do
  local pdir="$SANDBOX/plugins/p$i"
  mkdir -p "$pdir"
  cat << EOF > "$pdir/p$i.plugin.zsh"
export PLUGIN_${i}_LOADED=1
p${i}_cmd() { echo "p${i}"; }
EOF
  plugin_paths+=("$pdir")
done

# Helper script for benchmarking
cat << 'EOF' > "$SANDBOX/runner.zsh"
export XDG_DATA_HOME="$1"
export XDG_CACHE_HOME="$2"
source ./zload.zsh
zload "${@:3}"
EOF

cat << 'EOF' > "$SANDBOX/timed_runner.zsh"
export XDG_DATA_HOME="$1"
export XDG_CACHE_HOME="$2"
zmodload zsh/datetime
t0=$EPOCHREALTIME
source ./zload.zsh
zload "${@:3}"
t1=$EPOCHREALTIME
diff=$(( (t1 - t0) * 1000 ))
echo "$diff"
EOF

# Pre-compile bundle
print -P "%F{blue}==> Pre-compiling 10-plugin bundle...%f"
zsh "$SANDBOX/runner.zsh" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "${plugin_paths[@]}" >/dev/null 2>&1

print -P "%F{blue}==> Measuring warm runs (10 iterations)...%f\n"

integer iterations=10
float total_zload_ms=0.0
float total_pure_bundle_ms=0.0

for (( n=1; n<=iterations; n++ )); do
  out=$(zsh "$SANDBOX/timed_runner.zsh" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "${plugin_paths[@]}")
  total_zload_ms=$(( total_zload_ms + out ))

  out_bundle=$(zsh -c "
    zmodload zsh/datetime
    t0=\$EPOCHREALTIME
    source \"$XDG_CACHE_HOME/zload/bundle.zsh\"
    t1=\$EPOCHREALTIME
    diff=\$(( (t1 - t0) * 1000 ))
    echo \"\$diff\"
  ")
  total_pure_bundle_ms=$(( total_pure_bundle_ms + out_bundle ))
done

avg_zload=$(( total_zload_ms / iterations ))
avg_bundle=$(( total_pure_bundle_ms / iterations ))

printf "%-45s %15s\n" "Scenario" "Average Latency"
print "---------------------------------------------------------------"
printf "%-45s %12.3f ms\n" "Pure compiled bundle (.zwc)" "$avg_bundle"
printf "%-45s %12.3f ms\n" "zload warm (sourcing zload.zsh + 10 plugins)" "$avg_zload"
print "---------------------------------------------------------------"

if (( avg_bundle < 2.0 )); then
  print -P "%F{green}[PASS] Memory-mapped bytecode bundle executes in < 2.0 ms!%f"
else
  print -P "%F{yellow}[WARN] Latency above 2.0 ms threshold%f"
fi
