#!/usr/bin/env zsh
set -e

source ./zload.zsh

TMP_DIR=$(mktemp -d)
TMP_DIR="${TMP_DIR:A}"
trap 'rm -rf "$TMP_DIR"' EXIT

# Test 1: <name>.plugin.zsh + bin
mkdir -p "$TMP_DIR/p1/bin"
touch "$TMP_DIR/p1/p1.plugin.zsh"
local -A r1
_zload_find_main_file r1 "$TMP_DIR/p1" "p1"
[[ "$r1[script]" == "$TMP_DIR/p1/p1.plugin.zsh" ]] || {
  echo "FAIL: p1 script"
  exit 1
}
[[ "$r1[bin]" == "$TMP_DIR/p1/bin" ]] || {
  echo "FAIL: p1 bin"
  exit 1
}

# Test 2: <name>.zsh + completions/
mkdir -p "$TMP_DIR/p2/completions"
touch "$TMP_DIR/p2/p2.zsh"
touch "$TMP_DIR/p2/completions/_p2"
local -A r2
_zload_find_main_file r2 "$TMP_DIR/p2" "p2"
[[ "$r2[script]" == "$TMP_DIR/p2/p2.zsh" ]] || {
  echo "FAIL: p2 script"
  exit 1
}
[[ "$r2[fpath]" == *"$TMP_DIR/p2/completions"* ]] || {
  echo "FAIL: p2 fpath"
  exit 1
}

# Test 3: init.zsh + root completion
mkdir -p "$TMP_DIR/p3"
touch "$TMP_DIR/p3/init.zsh"
touch "$TMP_DIR/p3/_p3"
local -A r3
_zload_find_main_file r3 "$TMP_DIR/p3" "p3"
[[ "$r3[script]" == "$TMP_DIR/p3/init.zsh" ]] || {
  echo "FAIL: p3 script"
  exit 1
}
[[ "$r3[fpath]" == *"$TMP_DIR/p3"* ]] || {
  echo "FAIL: p3 fpath"
  exit 1
}

# Test 4: theme file
mkdir -p "$TMP_DIR/p4"
touch "$TMP_DIR/p4/robbyrussell.zsh-theme"
local -A r4
_zload_find_main_file r4 "$TMP_DIR/p4" "robbyrussell"
[[ "$r4[script]" == "$TMP_DIR/p4/robbyrussell.zsh-theme" ]] || {
  echo "FAIL: p4 theme script"
  exit 1
}

# Test 5: fallback *.zsh skipping test files
mkdir -p "$TMP_DIR/p5"
touch "$TMP_DIR/p5/test_helper.zsh"
touch "$TMP_DIR/p5/actual_tool.zsh"
local -A r5
_zload_find_main_file r5 "$TMP_DIR/p5" "p5"
[[ "$r5[script]" == "$TMP_DIR/p5/actual_tool.zsh" ]] || {
  echo "FAIL: p5 fallback script"
  exit 1
}

# Test 6: Non-existent directory returns failure
local -A r6
if _zload_find_main_file r6 "$TMP_DIR/nonexistent"; then
  echo "FAIL: expected nonexistent directory to fail"
  exit 1
fi

echo "PASS: test_find_file (all 6 test cases)"
