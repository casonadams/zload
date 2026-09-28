#!/usr/bin/env zsh
set -e

echo "=== Running Slice 3 Syntax Checks ==="
zsh -n zload.zsh
for f in functions/*; do
  zsh -n "$f"
done
echo "Syntax checks: OK"

echo "\n=== Running Slice 3 Lazy Loading Tests ==="
zsh test/test_lazy_cmd.zsh
zsh test/test_lazy_compinit.zsh
zsh test/test_defer.zsh

echo "\n=== Running Slice 1 & 2 Regression Tests ==="
zsh test/run_slice2.zsh

echo "\nAll Slice 3 tests passed successfully!"
