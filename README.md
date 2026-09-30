# zload

[![CI](https://github.com/casonadams/zload/actions/workflows/ci.yml/badge.svg)](https://github.com/casonadams/zload/actions/workflows/ci.yml)
[![Release Please](https://github.com/casonadams/zload/actions/workflows/release-please.yml/badge.svg)](https://github.com/casonadams/zload/actions/workflows/release-please.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docs](https://img.shields.io/badge/docs-casonadams.github.io%2Fzload-blue)](https://casonadams.github.io/zload/docs.html)

`zload` is an ultra-fast, zero-friction, memory-mapped Zsh plugin manager and loader built with 100% pure Zsh.

It delivers **< 0.5 ms warm interactive startup overhead** by compiling plugins into a consolidated `.zwc` wordcode bundle, automatically resolving canonical execution order, and completely eliminating subprocess forks.

---

## Installation

Add this 4-line snippet to the very top of your `~/.zshrc`. When you sync your dotfiles to any machine, `zload` automatically bootstraps itself on the first terminal launch:

```zsh
if [ ! -d "${HOME}/.zload" ]; then
  git clone --depth 1 https://github.com/casonadams/zload.git "${HOME}/.zload"
fi
source "${HOME}/.zload/zload.zsh"
```

*Or install via the one-liner script:*
```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/casonadams/zload/main/install.sh)"
```

---

## Quick Start

A clean, high-performance `~/.zshrc` configuration:

```zsh
# 1. Bootstrap zload (auto-clones on fresh machines)
if [ ! -d "${HOME}/.zload" ]; then
  git clone --depth 1 https://github.com/casonadams/zload.git "${HOME}/.zload"
fi
source "${HOME}/.zload/zload.zsh"

# 2. Deduplicating PATH management
user_paths=(
  ~/.cargo/bin
  ~/.local/bin
  /opt/homebrew/bin
  /opt/homebrew/sbin
)
zload path "${user_paths[@]}"

# 3. Declare plugins (automatic canonical ordering & bytecode compilation)
plugins=(
  casonadams/zline
  omz:git
  omz:lib/completion.zsh
  casonadams/walh-shell
  lukechilds/zsh-nvm --on nvm,node,npm
  zsh-users/zsh-syntax-highlighting --defer
  zsh-users/zsh-autosuggestions
)
zload "${plugins[@]}"
bindkey '^ ' autosuggest-accept
> **Tip — Fast Prompts**: Pair with a high-performance prompt like [zline](https://github.com/casonadams/zline) (`zload casonadams/zline`), [Powerlevel10k](https://github.com/romkatv/powerlevel10k) (`zload romkatv/powerlevel10k`), or [Starship](https://starship.rs) (`zload eval starship "starship init zsh"`) to complement `zload`'s sub-millisecond shell startup.

---

## Benchmark

Benchmarking 10 active plugins on macOS (Apple Silicon):

| Plugin Manager | Warm Startup Overhead | Subprocess Forks | Memory-Mapped Wordcode |
|---|---|---|---|
| **zload** | **0.45 ms** | **0 (Zero)** | **✓ Full Native (.zwc)** |
| Antidote | 12 ms | Few | ✕ |
| Zinit (Turbo) | 28 ms | Several | Partial |
| Oh-My-Zsh | 340 ms | Many (10+) | ✕ |

---

## Feature Highlights & Documentation

Comprehensive guides and technical documentation are organized in [`docs/`](docs/) and on the **[Documentation Website](https://casonadams.github.io/zload/docs.html)**:

- **[Declaration Syntax & Input Flexibility](docs/syntax.md)**
  - Native Zsh arrays (`plugins=( ... ); zload "${plugins[@]}"`), multiline strings, line-by-line, and inline arguments.
  - Complete syntax table for GitHub repos, `@tag` pinning, `#branch` tracking, Oh-My-Zsh plugins/themes/libs, Prezto modules, remote snippets, and precompiled binaries (`--from gh-r`).

- **[CLI Commands Reference](docs/commands.md)**
  - Complete reference for all subcommands formatted in standard 16-color ANSI output:
    `zload path`, `zload fpath`, `update`, `clean`, `list`, `which`, `cd`, `doctor --fix`, `profile`, `lock`, `sync`, `compile`, and `eval`.
  - Self-healing diagnostics (`zload doctor --fix`) to automatically repair missing wordcode caches.

- **[Lazy Loading Primitives](docs/lazy-loading.md)**
  - **Command Proxy Stubs (`--on`)**: Inlines instant proxy functions directly into bundle wordcode, deferring heavy CLI runtimes (like `nvm`, `pyenv`, `tfswitch`) until invocation in 0.00ms with zero runtime `eval`.
  - **Directory-Triggered Loading (`--on-dir`)**: Loads plugins only upon entering matching directories (e.g. `.envrc`, `.tfswitchrc`, `.git`).
  - **Post-Prompt Idle Deferral (`--defer`)**: Schedules visual highlighting plugins immediately after the prompt draws via `precmd`.
  - **Post-Install Build Hooks (`--build`)**: Executes compilation scripts after cloning without runtime shell startup overhead.

- **[Smart PATH & Completion Management](docs/paths-and-completions.md)**
  - `zload path`: Auto-expands `~`, validates directory existence, filters out dead paths, and applies instant O(1) deduplication to `$PATH`.
  - `zload fpath`: Prepend and deduplicate completion directories.
  - **Automatic `~/.zfunc` Discovery**: Automatically detects and links custom completion directories (for `uv`, `rustup`, `pipx`) into `$fpath` with zero configuration in `.zshrc`.
  - **Automatic Lazy `<Tab>` Compinit**: Automatically buffers early `compdef` calls, defers `compinit` until your first `<Tab>` press, and executes completion seamlessly on that first press with zero dropped keystrokes.
  - **Highlighted Menu Selection**: Pair with `omz:lib/completion.zsh` or native `zstyle` for interactive `<Tab>` menu navigation.
- **[Zero-Subprocess Eval Caching](docs/commands.md#3-zload-eval)**
  - Replaces slow `eval "$(starship init zsh)"` or `eval "$(zoxide init zsh)"` subshells by compiling shell output into memory-mapped `.zwc` files, loading in 0.2ms with zero subprocesses.

- **[Reproducible Lockfiles & Machine Sync](docs/commands.md#10-zload-lock--zload-sync)**
  - Freeze exact Git commit hashes across all plugins with `zload lock`.
  - Check out identical pinned environments on new machines with `zload sync`.

---

## UNIX Manual Page

`zload` installs a full manpage automatically registered in your shell's `$manpath`:

```sh
man zload
```

---

## Development & Verification

Run the unified specification test runner across all 32 tests and benchmark gates:

```sh
# Run ShellSpec BDD suite
shellspec

# Run all 5 specification verification gates
zsh test/verify_all.zsh
```

---

## License

MIT © [Cason Adams](https://github.com/casonadams)
