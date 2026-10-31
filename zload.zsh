# zload - Ultra-fast, zero-friction Zsh plugin manager
# https://github.com/casonadams/zload

0="${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}"
0="${${(M)0:#/*}:-$PWD/$0}"
typeset -g ZLOAD_HOME="${0:A:h}"
typeset -g ZLOAD_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/zload"
typeset -g ZLOAD_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/zload"
typeset -g ZLOAD_PLUGINS="${ZLOAD_DATA}/plugins"

[[ -d "$ZLOAD_CACHE" && -d "$ZLOAD_PLUGINS" ]] || mkdir -p "$ZLOAD_CACHE" "$ZLOAD_PLUGINS"

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

autoload -Uz _zload_parse_spec _zload_find_main_file _zload_install _zload_load_plugin _zload_ensure_omz _zload_omz_shim _zload_omz_libs _zload_run_build _zload_add_paths _zload_gh_r_asset _zload_gh_r_unpack _zload_spec_source _zload_activate_dirs _zload_doctor_env _zload_doctor_cache _zload_update_snippets _zload_install_all _zload_write_bundle _zload_defer_arm _zload_defer_fire _zload_flush_compdefs _zload_lazy_compinit_widget _zload_compile_self _zload_compile_plugins _zload_index_specs _zload_row _zload_sha256 _zload_fetch_snippet _zload_resolve_plugin _zload_update_gh_r _zload_create_stub _zload_setup_lazy_compinit _zload_real_compinit _zload_schedule_deferred _zload_run_deferred _zload_sort_plugins _zload_compile_bundle _zload_cmd_compile _zload_cmd_update _zload_cmd_clean _zload_cmd_list _zload_cmd_doctor _zload_cmd_profile _zload_cmd_help _zload_eval _zload_schedule_on_dir _zload_cmd_path _zload_cmd_fpath _zload_install_gh_r _zload_cmd_which _zload_cmd_cd _zload_cmd_lock _zload_cmd_sync _zload_cmd_self_update

typeset -g -U -a _zload_specs
typeset -g -A _zload_call_entries _zload_call_keys
typeset -g -i _zload_call_n=0
typeset -g -A _zload_loaded_plugins
typeset -g -a _zload_deferred_specs
typeset -g -a _zload_deferred_compdefs
typeset -g _zload_compinit_done=0

if ! typeset -f compdef >/dev/null 2>&1; then
  compdef() {
    _zload_deferred_compdefs+=("${(j: :)${(q)@}}")
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
      if [[ "$1" == "--lazy" ]]; then
        _zload_setup_lazy_compinit
      else
        _zload_real_compinit
      fi
      return 0
      ;;
    eval)
      shift
      _zload_eval "$@"
      return $?
      ;;
    self-update | upgrade)
      shift
      _zload_cmd_self_update "$@"
      return $?
      ;;
    update)
      shift
      case "$1" in
        --self)
          shift
          _zload_cmd_self_update "$@"
          ;;
        --all)
          shift
          _zload_cmd_self_update
          _zload_cmd_update "$@"
          ;;
        *) _zload_cmd_update "$@" ;;
      esac
      return $?
      ;;
    path | fpath | which | cd | clean | list | doctor | profile | compile | lock | sync | help)
      local cmd="$1"
      shift
      "_zload_cmd_${cmd}" "$@"
      return $?
      ;;
  esac

  local raw_input="$*"
  raw_input="${raw_input%%$'\n'#}"

  local slot=$((++_zload_call_n)) sfx=""
  ((slot > 1)) && sfx=".${slot}"
  local bundle="${ZLOAD_CACHE}/bundle${sfx}.zsh"
  local hash_file="${ZLOAD_CACHE}/bundle${sfx}.hash"

  if [[ -f "${bundle}.zwc" && -f "$hash_file" && "$(<"$hash_file")" == "$raw_input" ]]; then
    source "$bundle"
    return 0
  fi

  local -a entries
  local arg entry
  if (($# == 1)) && [[ "$1" == *$'\n'* ]]; then
    entries=("${(f)1}")
  else
    local current=""
    local expects_arg=0
    for arg in "$@"; do
      if ((expects_arg)); then
        current="$current ${(q)arg}"
        expects_arg=0
      elif [[ "$arg" == --(on|bin|path|subpath|build|hook|on-dir|from|sha256) ]]; then
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

  local -a clean
  for entry in "${entries[@]}"; do
    entry="${entry#"${entry%%[![:space:]]*}"}"
    entry="${entry%"${entry##*[![:space:]]}"}"
    [[ -z "$entry" || "$entry" == \#* ]] || clean+=("$entry")
  done
  entries=("${clean[@]}")
  _zload_specs+=("${entries[@]}")

  _zload_install_all "${entries[@]}"
  local -a failed_entries=("${reply[@]}")
  integer install_errors=${#failed_entries}

  local -A parsed
  for entry in "${entries[@]}"; do
    if ((${failed_entries[(Ie)$entry]})); then
      print -u2 "zload: failed to install $entry"
      continue
    fi

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

  if ((${#entries} > 0)); then
    _zload_call_entries[$slot]="${(F)entries}"
    _zload_call_keys[$slot]="$raw_input"
    ((install_errors == 0)) && _zload_write_bundle "$slot" "${entries[@]}"
  fi

  if ((! ${+ZLOAD_NO_COMPINIT})) && [[ -o interactive ]] && ((! _zload_compinit_done)); then
    autoload -Uz _zload_setup_lazy_compinit
    _zload_setup_lazy_compinit
  fi
}
