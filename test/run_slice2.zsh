#!/usr/bin/env zsh
set -e

echo "=== Running Slice 2 Syntax Checks ==="
zsh -n zload.zsh
zsh -n functions/_zload_ensure_omz
zsh -n functions/_zload_omz_shim
zsh -n functions/_zload_load_plugin
echo "Syntax checks: OK"

echo "\n=== Running Slice 2 Compatibility Tests ==="
zsh test/test_omz.zsh
zsh test/test_prezto.zsh

echo "\n=== Running Slice 1 Regression Tests ==="
zsh test/run_slice1.zsh

echo "\nAll Slice 2 tests passed successfully!"
