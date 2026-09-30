# zload - Ultra-fast, zero-friction Zsh plugin manager
# https://github.com/casonadams/zload

0="${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}"
0="${${(M)0:#/*}:-$PWD/$0}"
typeset -g ZLOAD_HOME="${0:A:h}"
typeset -g ZLOAD_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/zload"
typeset -g ZLOAD_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/zload"
typeset -g ZLOAD_PLUGINS="${ZLOAD_DATA}/plugins"

mkdir -p "$ZLOAD_CACHE" "$ZLOAD_PLUGINS"

if ((! ${fpath[(Ie)${ZLOAD_HOME}/functions]})); then
  fpath=("${ZLOAD_HOME}/functions" "${fpath[@]}")
fi

if [[ -d "$HOME/.zfunc" ]] && ((! ${fpath[(Ie)$HOME/.zfunc]})); then
  fpath=("$HOME/.zfunc" "${fpath[@]}")
fi

if [[ -d "${ZLOAD_HOME}/man" ]]; then
  typeset -g -U manpath MANPATH
  manpath=("${ZLOAD_HOME}/man" "${manpath[@]}")
fi

autoload -Uz _zload_parse_spec _zload_find_main_file _zload_install _zload_load_plugin _zload_ensure_omz _zload_omz_shim _zload_create_stub _zload_setup_lazy_compinit _zload_real_compinit _zload_schedule_deferred _zload_run_deferred _zload_sort_plugins _zload_compile_bundle _zload_cmd_compile _zload_cmd_update _zload_cmd_clean _zload_cmd_list _zload_cmd_doctor _zload_cmd_profile _zload_cmd_help _zload_eval _zload_schedule_on_dir _zload_cmd_path _zload_cmd_fpath _zload_install_gh_r _zload_cmd_which _zload_cmd_cd _zload_cmd_lock _zload_cmd_sync _zload_cmd_self_update

typeset -g -a _zload_specs
typeset -g -A _zload_loaded_plugins
typeset -g -a _zload_deferred_specs
typeset -g -a _zload_deferred_compdefs
typeset -g _zload_compinit_done=0

_zload_hash() {
  local str="$1"
  integer hash=5381 i len=${#str}
  for ((i = 1; i <= len; i++)); do
    ((hash = ((hash << 5) + hash) + "#str[i]"))
  done
  REPLY="$hash"
}

if ! typeset -f compdef >/dev/null 2>&1; then
  compdef() {
    _zload_deferred_compdefs+=("$*")
  }
fi

zload() {
  emulate -L zsh
  setopt extended_glob

  if (($# == 0)); then
    print "Usage: zload <plugin> [options] | zload <command>"
    return 1
  fi

  case "$1" in
    compinit)
      shift
      autoload -Uz _zload_setup_lazy_compinit
      if [[ "$1" == "--lazy" ]]; then
        _zload_setup_lazy_compinit
      else
        _zload_real_compinit
      fi
      return 0
      ;;
    eval)
      shift
      autoload -Uz _zload_eval
      _zload_eval "$@"
      return $?
      ;;
    path)
      shift
      autoload -Uz _zload_cmd_path
      _zload_cmd_path "$@"
      return $?
      ;;
    fpath)
      shift
      autoload -Uz _zload_cmd_fpath
      _zload_cmd_fpath "$@"
      return $?
      ;;
    which)
      shift
      autoload -Uz _zload_cmd_which
      _zload_cmd_which "$@"
      return $?
      ;;
    cd)
      shift
      autoload -Uz _zload_cmd_cd
      _zload_cmd_cd "$@"
      return $?
      ;;
    self-update | upgrade)
      shift
      autoload -Uz _zload_cmd_self_update
      _zload_cmd_self_update "$@"
      return $?
      ;;
    update)
      shift
      if [[ "$1" == "--self" ]]; then
        shift
        autoload -Uz _zload_cmd_self_update
        _zload_cmd_self_update "$@"
        return $?
      elif [[ "$1" == "--all" ]]; then
        shift
        autoload -Uz _zload_cmd_self_update _zload_cmd_update
        _zload_cmd_self_update
        _zload_cmd_update "$@"
        return $?
      else
        autoload -Uz _zload_cmd_update
        _zload_cmd_update "$@"
        return $?
      fi
      ;;
    clean | list | doctor | profile | compile | lock | sync | help)
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

  local raw_input="$*"
  local current_hash
  _zload_hash "$raw_input"
  current_hash="$REPLY"

  if [[ -f "${ZLOAD_CACHE}/bundle.zsh.zwc" && -f "${ZLOAD_CACHE}/bundle.hash" ]]; then
    if [[ "$(<"${ZLOAD_CACHE}/bundle.hash")" == "$current_hash" ]]; then
      source "${ZLOAD_CACHE}/bundle.zsh"
      return 0
    fi
  fi

  local -a entries
  if (($# == 1)) && [[ "$1" == *$'\n'* ]]; then
    entries=("${(f)1}")
  else
    local current=""
    local expects_arg=0
    for arg in "$@"; do
      if ((expects_arg)); then
        current="$current ${(q)arg}"
        expects_arg=0
      elif [[ "$arg" == --(on|bin|path|subpath|build|hook|on-dir|from) ]]; then
        current="$current $arg"
        expects_arg=1
      elif [[ "$arg" == --* ]] && [[ -n "$current" ]]; then
        current="$current $arg"
      else
        [[ -n "$current" ]] && entries+=("$current")
        current="${(q)arg}"
      fi
    done
    [[ -n "$current" ]] && entries+=("$current")
  fi

  integer install_errors=0
  for entry in "${entries[@]}"; do
    entry="${entry#"${entry%%[![:space:]]*}"}"
    entry="${entry%"${entry##*[![:space:]]}"}"
    [[ -z "$entry" || "$entry" == \#* ]] && continue

    _zload_specs+=("$entry")

    local -A parsed
    _zload_parse_spec parsed "$entry"

    if ! _zload_install parsed; then
      print -u2 "zload: failed to install $entry"
      ((install_errors++))
      continue
    fi

    if [[ -n "${parsed[on_dir]}" ]]; then
      _zload_schedule_on_dir "$entry" "${parsed[on_dir]}"
    elif ((parsed[defer])); then
      _zload_schedule_deferred "$entry"
    else
      _zload_load_plugin parsed
    fi
  done

  if ((install_errors == 0 && ${#entries} > 0)); then
    _zload_compile_bundle "${entries[@]}"
    print "$current_hash" >"${ZLOAD_CACHE}/bundle.hash"
  fi

  if ((! ${+ZLOAD_NO_COMPINIT})) && [[ -o interactive ]] && ((! _zload_compinit_done)); then
    autoload -Uz _zload_setup_lazy_compinit
    _zload_setup_lazy_compinit
  fi
}
