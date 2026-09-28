# zload

[![CI](https://github.com/casonadams/zload/actions/workflows/ci.yml/badge.svg)](https://github.com/casonadams/zload/actions/workflows/ci.yml)
[![Release Please](https://github.com/casonadams/zload/actions/workflows/release-please.yml/badge.svg)](https://github.com/casonadams/zload/actions/workflows/release-please.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**zload** is an ultra-fast, zero-friction plugin manager and loader for Zsh.

It is designed to give you rich plugins, themes, and completions with **< 1.0 ms warm startup overhead** by leveraging memory-mapped bytecode compilation (`.zwc`), transparent lazy-loading, automatic canonical ordering, and zero subprocess forks during interactive startup.

---

## Features

- **Blazingly Fast (< 1.0 ms warm overhead)**: Merges and byte-compiles plugins into a consolidated `.zwc` wordcode bundle. Sourcing one memory-mapped file replaces dozens of slow individual disk reads.
- **Zero Subprocesses**: 100% pure Zsh builtins and parameter expansion in the critical interactive path. Zero calls to `git`, `sed`, `grep`, or subshell forks `$(...)` during warm startup.
- **Human-First Ergonomics**: Declare plugins simply by listing them in an array or line-by-line in `.zshrc`.
- **Automatic Canonical Ordering**: Automatically sorts completions, themes, general plugins, syntax highlighting, autosuggestions, and substring search into their safe execution order.
- **Seamless Oh-My-Zsh & Prezto Compatibility**: Load OMZ plugins (`omz:git`) without cloning the full framework. Missing OMZ library dependencies (`lib/git.zsh`) and completions are loaded automatically.
- **Built-in Safe Lazy Loading**:
  - **Command Stubs (`--on "cmd1, cmd2"`)**: Stub heavy CLIs (like `nvm`, `pyenv`, `thefuck`) so your shell opens instantly; the real tool loads only when invoked.
  - **Lazy Compinit**: Defers `compinit` to your first `<Tab>` keystroke, saving 30–100 ms on shell startup with zero impact on typing commands.
  - **Post-Prompt Scheduling (`--defer`)**: Safely loads visual plugins after the prompt is drawn.
- **Smart Cache Invalidation**: Computes a fast signature of your `.zshrc` declarations. Edits trigger automatic bundle recompilation on the next launch.

---

## Installation

### Automatic Bootstrapping in `~/.zshrc`
Add this to the very top of your `~/.zshrc` to automatically clone `zload` if missing on new machines:

```zsh
### zload ###
if [ ! -d "${HOME}/.zload" ]; then
  git clone --depth 1 https://github.com/casonadams/zload.git "${HOME}/.zload"
fi
source "${HOME}/.zload/zload.zsh"
```

### Or Single-Line Installer
```zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/casonadams/zload/main/install.sh)"
```

---

## Quick Start

Add the following to your `~/.zshrc`:

```zsh
# Source zload
source ~/.zload/zload.zsh

# Declare your plugins
plugins=(
  # Completions
  zsh-users/zsh-completions

  # Oh-My-Zsh plugins (no full OMZ clone required)
  omz:git
  omz:extract
  omz:docker

  # Themes / Prompts
  romkatv/powerlevel10k

  # UI enhancements
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-autosuggestions

  # Heavy tools lazy-loaded on command
  lukechilds/zsh-nvm --on nvm,node,npm
)

zload "${plugins[@]}"
```

---

## Powerlevel10k & Instant Prompt Setup

`zload` is built to be 100% leak-free. It produces **0 console output** and forks **0 child processes** on warm startup, making it the most reliable companion for Powerlevel10k's Instant Prompt (which disables itself if startup scripts write to stdout/stderr or spawn subshells prematurely).

### Recommended `~/.zshrc` Order

```zsh
# 1. Enable Powerlevel10k Instant Prompt (at the very top of ~/.zshrc)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# 2. Source or auto-clone zload
if [ ! -d "${HOME}/.zload" ]; then
  git clone --depth 1 https://github.com/casonadams/zload.git "${HOME}/.zload"
fi
source "${HOME}/.zload/zload.zsh"

# 3. Load Powerlevel10k
zload romkatv/powerlevel10k

# 4. Load your plugins (canonical ordering automatically places completions first and UI hooks last)
zload "
  omz:lib/theme-and-appearance.zsh
  omz:lib/key-bindings.zsh
  omz:lib/completion.zsh
  casonadams/walh-shell
  lukechilds/zsh-nvm --on nvm,node,npm
  zsh-users/zsh-syntax-highlighting --defer
  zsh-users/zsh-autosuggestions
"
bindkey '^ ' autosuggest-accept

# 5. Source your Powerlevel10k customization file
[[ ! -f "${HOME}/.p10k.zsh" ]] || source "${HOME}/.p10k.zsh"
```

---

## Migrating from Zinit

If you are migrating from Zinit, `zload` replaces cryptic `ice` modifiers with a clean declarative format:

### Before (Zinit)
```zsh
# Clunky DSL with arcane ice modifiers
autoload -Uz compinit && compinit
autoload -Uz _zinit && ((${+_comps})) && _comps[zinit]=_zinit

zinit wait lucid light-mode depth=1 for \
  OMZL::theme-and-appearance.zsh \
  OMZL::key-bindings.zsh \
  OMZL::completion.zsh \
  casonadams/walh-shell \
  lukechilds/zsh-nvm \
  atinit"zicompinit; zicdreplay" \
  zsh-users/zsh-syntax-highlighting \
  atload"_zsh_autosuggest_start; bindkey '^ ' autosuggest-accept" \
  zsh-users/zsh-autosuggestions

zinit ice depth=1
zinit light romkatv/powerlevel10k
```

### After (zload)
```zsh
### zload (auto-installs if missing) ###
if [ ! -d "${HOME}/.zload" ]; then
  git clone --depth 1 https://github.com/casonadams/zload.git "${HOME}/.zload"
fi
source "${HOME}/.zload/zload.zsh"

# Prompt theme
zload romkatv/powerlevel10k

# Plugins (clean, declarative, automatic canonical ordering)
zload "
  omz:lib/theme-and-appearance.zsh
  omz:lib/key-bindings.zsh
  omz:lib/completion.zsh
  casonadams/walh-shell
  lukechilds/zsh-nvm --on nvm,node,npm
  zsh-users/zsh-syntax-highlighting --defer
  zsh-users/zsh-autosuggestions
"
bindkey '^ ' autosuggest-accept
```

#### Key Differences:
- **No manual `compinit`**: `zload` defers `compinit` until your first `<Tab>` press, cutting 40–100ms off startup.
- **`OMZL::` -> `omz:lib/`**: Load Oh-My-Zsh libraries and plugins directly with standard paths.
- **`wait` / `lucid` -> Automatic**: `zload` automatically orders your plugins canonically and compiles them into a sub-millisecond memory-mapped wordcode bundle (`bundle.zsh.zwc`).

Restart your shell or run `source ~/.zshrc`. On first run, `zload` downloads missing plugins and compiles the bytecode bundle. Subsequent shells start in **under 1 millisecond**.

---

## Supported Source Syntaxes

| Source | Syntax | Description |
|---|---|---|
| **GitHub repo** | `user/repo` | Standard GitHub repository |
| **Git tag** | `user/repo@v1.2.0` | Pin to a specific Git release tag |
| **Git branch** | `user/repo#develop` | Pin to a specific Git branch |
| **Oh-My-Zsh plugin** | `omz:git` | Loads `plugins/git` and auto-loads `lib/git.zsh` |
| **Oh-My-Zsh theme** | `omz:themes/robbyrussell` | Loads OMZ theme and color/git dependencies |
| **Prezto module** | `prezto:utility` | Loads Prezto module and autoloads its `functions/` |
| **Full Git URL** | `https://gitlab.com/group/repo.git` | Arbitrary remote Git repository |
| **Monorepo Subpath** | `user/repo --path plugins/tool` | Targets specific directory inside a repository |
| **Remote Snippet** | `snippet:https://.../script.zsh` | Single-file script download without Git clone |
| **Build Hook** | `user/repo --build "./install --bin"` | Executes compilation command in cloned repo |
| **GitHub Releases Binary** | `user/repo --from gh-r` | Downloads precompiled binary asset and adds to PATH |
| **Local directory** | `~/code/my-plugin` | Local directory on your machine |

---

## Lazy Loading Options

### 1. Lazy Command Dispatchers (`--on`)
Heavy CLI tools only need to be loaded when you actually execute them:

```zsh
zload lukechilds/zsh-nvm --on nvm,node,npm
```

`zload` defines instant proxy functions for `nvm`, `node`, and `npm`. When any of those commands is first called, the proxy removes itself, loads the real plugin, and transparently executes your command with all arguments intact.

### 2. Post-Prompt Deferral (`--defer`)
For plugins that only affect prompt visuals or input highlighting:

```zsh
zload zsh-users/zsh-syntax-highlighting --defer
```

In interactive shells, deferred plugins load immediately after the first prompt appears. In non-interactive scripts (`zsh -c`), they source immediately so dependencies are never missing.

### 3. Lazy Compinit
`compinit` is deferred by default to the first time you press `<Tab>`:

```zsh
zload compinit --lazy
```

Any calls to `compdef` made by plugins prior to `compinit` are buffered and automatically replayed once `compinit` runs.

### 4. Zero-Subprocess Eval Caching (`zload eval`)
Tools like `starship`, `zoxide`, or `direnv` normally spawn subshells on every terminal startup:

```zsh
# Instead of slow eval "$(starship init zsh)":
zload eval starship "starship init zsh"
zload eval zoxide "zoxide init zsh"
```

`zload` executes the command once, compiles its shell output into memory-mapped wordcode (`.zwc`), and checks the binary timestamp. Subsequent shell startups source the compiled file in **0.2 ms** with **0 subshells**.

### 5. Directory-Triggered Lazy Loading (`--on-dir`)
Defer loading plugins until you `cd` into a matching directory (e.g. entering a Git repository, Node project, or Cargo workspace):

```zsh
zload "davidde/git-time-metric" --on-dir ".git"
zload "wbinglee/zsh-wakatime" --on-dir "package.json"
```

A lightweight `chpwd` hook checks directory patterns upon `cd`, loads the plugin immediately when matched, and unregisters itself.

---

## Smart PATH & FPATH Management

Managing `$PATH` manually with lines of `export PATH="$PATH:/dir"` in `.zshrc` frequently accumulates dead directories and duplicate entries every time a shell or tmux pane is opened.

`zload` provides built-in, deduplicating path helpers:

### 1. Prepend to `$PATH` with Auto-Deduplication
```zsh
user_paths=(
  ~/.opencode/bin
  ~/.cargo/bin
  ~/.local/bin
  /opt/homebrew/bin
  /opt/homebrew/sbin
  /opt/homebrew/opt/openjdk/bin
  /usr/local/bin
)
zload path "${user_paths[@]}"
```

- **Existence Validation**: Only directories that actually exist on disk are added. Dead or deleted paths are filtered out automatically, preventing command resolution stalls.
- **Tilde & Variable Expansion**: Automatically expands `~`, `$HOME`, and relative paths into clean canonical paths.
- **Strict Deduplication**: Guarantees each directory appears exactly once at the front of `$PATH`, even when `.zshrc` is re-sourced repeatedly.
- **Inspect**: Run `zload path` with no arguments to print your clean, active `$PATH` one entry per line.

### 2. Prepend to `$fpath`
```zsh
zload fpath ~/.my-completions /opt/homebrew/share/zsh/site-functions
```

- Deduplicates `$fpath` entries and validates directory existence.
- Run `zload fpath` with no arguments to inspect all active completion directories.

### 3. Automatic `~/.zfunc` Discovery
If `~/.zfunc` exists on your system (the standard directory for tools like `uv`, `rustup`, `pipx`, `bwc`), `zload` automatically discovers it and links it into `$fpath` in both live sessions and the compiled `.zwc` bundle. Zero configuration required in `.zshrc`!

---

## CLI Management

`zload` provides built-in shell commands to inspect and maintain your plugins:

```zsh
# Update all installed plugins in parallel from remotes and recompile
zload update

# Upgrade zload itself to latest release
zload upgrade     # or: zload self-update
zload update --all # updates zload + all plugins together

# List installed plugins with active Git branch, tag, and commit status
zload list

# Clean unreferenced plugin directories from disk
zload clean       # Dry run
zload clean -f    # Force delete

# Run environment and health diagnostics
zload doctor

# Profile startup latency breakdown
zload profile

# Manually force bundle recompilation
zload compile

# Add directories to PATH / fpath with automatic deduplication
zload path ~/bin /opt/homebrew/bin
zload fpath ~/.zfunc

# Inspect and navigate installed plugins
zload which omz:git
zload cd zsh-autosuggestions

# Export and synchronize pinned lockfiles
zload lock [file]
zload sync [file]

# Display help and options
zload help
```

---

## Benchmark

Benchmarking 10 plugins on macOS (Apple Silicon):

```text
========================================
       zload Startup Benchmark         
========================================

Scenario                                      Average Latency
---------------------------------------------------------------
Pure compiled bundle (.zwc)                          0.446 ms
zload warm (sourcing zload.zsh + 10 plugins)         4.468 ms
---------------------------------------------------------------
[PASS] Memory-mapped bytecode bundle executes in < 2.0 ms!
```

---

## Development & Testing

Run the automated test suite across all feature slices:

```zsh
zsh test/run_all.zsh
```

Run the benchmark:

```zsh
zsh benchmark/bench.zsh
```

---

## License

MIT © [Cason Adams](https://github.com/casonadams)
