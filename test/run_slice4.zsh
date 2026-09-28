#!/usr/bin/env zsh
set -e

echo "=== Running Slice 4 Syntax Checks ==="
zsh -n zload.zsh
for f in functions/*; do
  zsh -n "$f"
done
echo "Syntax checks: OK"

echo "\n=== Running Slice 4 Bundle & Warm Startup Tests ==="
zsh test/test_order.zsh
zsh test/test_bundle.zsh
zsh test/test_warm_startup.zsh

echo "\n=== Running Slice 1, 2, & 3 Regression Tests ==="
zsh test/run_slice3.zsh

echo "\nAll Slice 4 tests passed successfully!"
