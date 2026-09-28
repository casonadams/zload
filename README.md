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

Clone `zload` to your machine:

```zsh
git clone --depth 1 https://github.com/casonadams/zload.git ~/.zload
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

---

## CLI Management

`zload` provides built-in shell commands to inspect and maintain your plugins:

```zsh
# Update all installed plugins in parallel from remotes and recompile
zload update

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
