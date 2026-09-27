# zload - Ultra-fast, zero-friction Zsh plugin manager
# https://github.com/casonadams/zload

0="${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}"
0="${${(M)0:#/*}:-$PWD/$0}"
typeset -g ZLOAD_HOME="${0:A:h}"
typeset -g ZLOAD_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/zload"
typeset -g ZLOAD_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/zload"
typeset -g ZLOAD_PLUGINS="${ZLOAD_DATA}/plugins"

mkdir -p "$ZLOAD_CACHE" "$ZLOAD_PLUGINS"

if (( ! ${fpath[(Ie)${ZLOAD_HOME}/functions]} )); then
  fpath=("${ZLOAD_HOME}/functions" "${fpath[@]}")
fi

autoload -Uz _zload_parse_spec _zload_find_main_file _zload_install _zload_load_plugin

typeset -g -a _zload_specs
typeset -g -A _zload_loaded_plugins

zload() {
  emulate -L zsh
  setopt extended_glob

  if (( $# == 0 )); then
    print "Usage: zload <plugin> [options] | zload <command>"
    return 1
  fi

  case "$1" in
    update|clean|list|doctor|compile|help)
      local cmd="$1"
      shift
      autoload -Uz "_zload_cmd_${cmd}" 2>/dev/null
      if typeset -f "_zload_cmd_${cmd}" >/dev/null 2>&1; then
        "_zload_cmd_${cmd}" "$@"
        return $?
      else
        print -u2 "zload: command not implemented yet: $cmd"
        return 1
      fi
      ;;
  esac

  local -a entries
  if (( $# == 1 )) && [[ "$1" == *$'\n'* ]]; then
    entries=("${(f)1}")
  else
    local current=""
    local expects_arg=0
    for arg in "$@"; do
      if (( expects_arg )); then
        current="$current $arg"
        expects_arg=0
      elif [[ "$arg" == --(on|bin) ]]; then
        current="$current $arg"
        expects_arg=1
      elif [[ "$arg" == --* ]] && [[ -n "$current" ]]; then
        current="$current $arg"
      else
        [[ -n "$current" ]] && entries+=("$current")
        current="$arg"
      fi
    done
    [[ -n "$current" ]] && entries+=("$current")
  fi

  for entry in "${entries[@]}"; do
    entry="${entry#"${entry%%[![:space:]]*}"}"
    entry="${entry%"${entry##*[![:space:]]}"}"
    [[ -z "$entry" || "$entry" == \#* ]] && continue

    _zload_specs+=("$entry")

    local -A parsed
    _zload_parse_spec parsed "$entry"

    if ! _zload_install parsed; then
      print -u2 "zload: failed to install $entry"
      continue
    fi

    _zload_load_plugin parsed
  done
}
