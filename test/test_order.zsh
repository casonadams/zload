#!/usr/bin/env zsh
set -e

source ./zload.zsh

input_specs=(
  "zsh-users/zsh-history-substring-search"
  "zsh-users/zsh-autosuggestions"
  "omz:git"
  "zsh-users/zsh-syntax-highlighting"
  "romkatv/powerlevel10k"
  "casonadams/zline"
  "zsh-users/zsh-completions"
  "omz:plugins/docker"
)

local -a sorted_specs
_zload_sort_plugins sorted_specs "${input_specs[@]}"

expected_specs=(
  "zsh-users/zsh-completions"
  "romkatv/powerlevel10k"
  "casonadams/zline"
  "omz:git"
  "omz:plugins/docker"
  "zsh-users/zsh-syntax-highlighting"
  "zsh-users/zsh-autosuggestions"
  "zsh-users/zsh-history-substring-search"
)

for (( i=1; i<=${#expected_specs}; i++ )); do
  if [[ "${sorted_specs[i]}" != "${expected_specs[i]}" ]]; then
    echo "FAIL at position $i:"
    echo "  Expected: ${expected_specs[i]}"
    echo "  Got:      ${sorted_specs[i]}"
    exit 1
  fi
done

echo "PASS: test_order (canonical plugin ordering verified)"
