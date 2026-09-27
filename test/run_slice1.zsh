#!/usr/bin/env zsh
set -e

echo "=== Running Slice 1 Syntax Checks ==="
zsh -n zload.zsh
zsh -n functions/_zload_parse_spec
zsh -n functions/_zload_find_main_file
zsh -n functions/_zload_install
zsh -n functions/_zload_load_plugin
echo "Syntax checks: OK"

echo "\n=== Running Slice 1 Unit & Integration Tests ==="
zsh test/test_bootstrap.zsh
zsh test/test_parser.zsh
zsh test/test_find_file.zsh
zsh test/test_install.zsh

echo "\nAll Slice 1 tests passed successfully!"
