Describe 'zload'
  setup() {
    local tmp="$(mktemp -d)"
    export SANDBOX="${tmp:A}"
    export XDG_DATA_HOME="$SANDBOX/data"
    export XDG_CACHE_HOME="$SANDBOX/cache"
    source ./zload.zsh
  }

  cleanup() {
    rm -rf "$SANDBOX"
  }

  BeforeEach 'setup'
  AfterEach 'cleanup'

  Describe 'bootstrap'
    It 'initializes XDG cache directory'
      When call test -d "$ZLOAD_CACHE"
      The status should be success
    End

    It 'initializes XDG plugin directory'
      When call test -d "$ZLOAD_PLUGINS"
      The status should be success
    End

    It 'adds functions to fpath'
      When call test -d "$ZLOAD_HOME/functions"
      The status should be success
    End
  End

  Describe 'specification parser'
    It 'parses GitHub repository format'
      local -A parsed
      _zload_parse_spec parsed "zsh-users/zsh-autosuggestions"
      The variable 'parsed[type]' should equal 'github'
      The variable 'parsed[name]' should equal 'zsh-users---zsh-autosuggestions'
    End

    It 'parses GitHub release tags'
      local -A parsed
      _zload_parse_spec parsed "romkatv/powerlevel10k@v1.20.0"
      The variable 'parsed[ref]' should equal 'v1.20.0'
    End

    It 'parses Oh-My-Zsh shorthand'
      local -A parsed
      _zload_parse_spec parsed "omz:git"
      The variable 'parsed[type]' should equal 'omz'
      The variable 'parsed[subpath]' should equal 'plugins/git'
    End

    It 'parses lazy command stubs (--on)'
      local -A parsed
      _zload_parse_spec parsed "lukechilds/zsh-nvm" --on "nvm,node,npm"
      The variable 'parsed[on_cmds]' should equal 'nvm,node,npm'
    End

    It 'parses post-prompt deferral (--defer)'
      local -A parsed
      _zload_parse_spec parsed "zsh-users/zsh-syntax-highlighting" --defer
      The variable 'parsed[defer]' should equal '1'
    End
  End

  Describe 'path helpers'
    It 'prepends and deduplicates valid directories'
      mkdir -p "$SANDBOX/bin1" "$SANDBOX/bin2"
      zload path "$SANDBOX/bin1" "$SANDBOX/bin2"
      The variable 'path[1]' should equal "$SANDBOX/bin1"
      The variable 'path[2]' should equal "$SANDBOX/bin2"

      zload path "$SANDBOX/bin1"
      The variable 'path[1]' should equal "$SANDBOX/bin1"
    End

    It 'prepends and deduplicates fpath directories'
      mkdir -p "$SANDBOX/comp1"
      zload fpath "$SANDBOX/comp1"
      The variable 'fpath[1]' should equal "$SANDBOX/comp1"
    End
  End

  Describe 'doctor'
    It 'runs environment diagnostics'
      When run zload doctor
      The status should be success
      The output should include 'Zsh version:'
      The output should include 'all checks passed!'
    End
  End

  Describe 'which and cd'
    It 'locates installed plugin directory'
      mkdir -p "$ZLOAD_PLUGINS/zsh-users---zsh-autosuggestions"
      When run zload which zsh-autosuggestions
      The status should be success
      The output should include 'zsh-users---zsh-autosuggestions'
    End
  End
End
