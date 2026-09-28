#!/usr/bin/env zsh
set -e

SANDBOX=$(mktemp -d)
SANDBOX="${SANDBOX:A}"
trap 'rm -rf "$SANDBOX"' EXIT

export XDG_DATA_HOME="$SANDBOX/data"
export XDG_CACHE_HOME="$SANDBOX/cache"

source ./zload.zsh

# Create dummy plugin and compile bundle
mkdir -p "$SANDBOX/p1"
echo "export P1=1" > "$SANDBOX/p1/p1.plugin.zsh"
zload "$SANDBOX/p1"

# 1. Test doctor
DOCTOR_OUT=$(zload doctor)
[[ "$DOCTOR_OUT" == *"Zsh version:"* ]] || { echo "FAIL: doctor missing Zsh version"; exit 1; }
[[ "$DOCTOR_OUT" == *"Git:"* ]] || { echo "FAIL: doctor missing Git check"; exit 1; }
[[ "$DOCTOR_OUT" == *"Bytecode bundle:"* ]] || { echo "FAIL: doctor missing bytecode bundle check"; exit 1; }
[[ "$DOCTOR_OUT" == *"passed!"* || "$DOCTOR_OUT" == *"healthy"* ]] || { echo "FAIL: doctor reported failure on healthy system"; exit 1; }

# 2. Test profile
PROFILE_OUT=$(zload profile)
[[ "$PROFILE_OUT" == *"Memory-mapped bundle"* ]] || { echo "FAIL: profile missing bundle entry"; exit 1; }
[[ "$PROFILE_OUT" == *"Total warm interactive overhead"* ]] || { echo "FAIL: profile missing total overhead"; exit 1; }

echo "PASS: test_doctor (doctor diagnostics and profile latency breakdown)"
