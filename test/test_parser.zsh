#!/usr/bin/env zsh
set -e

source ./zload.zsh

test_case() {
  local input="$1"
  local expected_type="$2"
  local expected_name="$3"
  local expected_ref="$4"
  local expected_subpath="$5"
  local expected_defer="$6"
  local expected_on="$7"

  local -A res
  _zload_parse_spec res "$input"

  [[ "$res[type]" == "$expected_type" ]] || {
    echo "FAIL [$input]: type expected '$expected_type', got '$res[type]'"
    exit 1
  }
  [[ "$res[name]" == "$expected_name" ]] || {
    echo "FAIL [$input]: name expected '$expected_name', got '$res[name]'"
    exit 1
  }
  [[ "$res[ref]" == "$expected_ref" ]] || {
    echo "FAIL [$input]: ref expected '$expected_ref', got '$res[ref]'"
    exit 1
  }
  [[ "$res[subpath]" == "$expected_subpath" ]] || {
    echo "FAIL [$input]: subpath expected '$expected_subpath', got '$res[subpath]'"
    exit 1
  }
  [[ "$res[defer]" == "$expected_defer" ]] || {
    echo "FAIL [$input]: defer expected '$expected_defer', got '$res[defer]'"
    exit 1
  }
  [[ "$res[on_cmds]" == "$expected_on" ]] || {
    echo "FAIL [$input]: on_cmds expected '$expected_on', got '$res[on_cmds]'"
    exit 1
  }
}

# 1. Standard GitHub
test_case "zsh-users/zsh-autosuggestions" "github" "zsh-users---zsh-autosuggestions" "" "" "0" ""

# 2. GitHub with tag
test_case "romkatv/powerlevel10k@v1.20.0" "github" "romkatv---powerlevel10k" "v1.20.0" "" "0" ""

# 3. GitHub with branch and defer
test_case "zsh-users/zsh-syntax-highlighting#develop --defer" "github" "zsh-users---zsh-syntax-highlighting" "develop" "" "1" ""

# 4. OMZ shorthand
test_case "omz:git" "omz" "_omz" "" "plugins/git" "0" ""

# 5. OMZ full subpath
test_case "omz:plugins/extract" "omz" "_omz" "" "plugins/extract" "0" ""

# 6. OMZ theme
test_case "omz:themes/robbyrussell" "omz" "_omz" "" "themes/robbyrussell" "0" ""

# 7. Prezto shorthand
test_case "prezto:utility" "prezto" "_prezto" "" "modules/utility" "0" ""

# 8. Prezto full
test_case "prezto:modules/completion" "prezto" "_prezto" "" "modules/completion" "0" ""

# 9. Git URL
test_case "https://gitlab.com/test/repo.git" "git" "gitlab.com---test---repo" "" "" "0" ""

# 10. Lazy on-command stub
test_case "lukechilds/zsh-nvm --on nvm,node,npm" "github" "lukechilds---zsh-nvm" "" "" "0" "nvm,node,npm"

# 11. Local directory
TMP_LOCAL=$(mktemp -d)
trap 'rm -rf "$TMP_LOCAL"' EXIT
test_case "$TMP_LOCAL" "local" "local---${TMP_LOCAL:t}" "" "" "0" ""

# 12. Remote snippet
test_case "snippet:https://example.com/tool.zsh" "snippet" "example.com---tool.zsh" "" "tool.zsh" "0" ""

# 13. Monorepo with subpath
test_case "owner/repo --path plugins/tool" "github" "owner---repo" "" "plugins/tool" "0" ""

echo "PASS: test_parser (all 13 test cases)"
