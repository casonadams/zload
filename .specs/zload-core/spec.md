# zload Core Specification

## Status

Approved

## Problem

Modern interactive shells suffer from noticeable startup latency when configuring plugins, themes, and completions. Existing solutions present unacceptable trade-offs:
- **Oh-My-Zsh / Antigen**: Heavy, unoptimized, forking multiple subshells and sourcing dozens of individual files synchronously, often introducing 200ms–800ms+ startup latency.
- **Zinit**: Fast via deferred loading, but burdened by an arcane, fragile syntax DSL (`ice wait'0b' lucid light-mode as'completion'...`), bloated codebase, and brittle internal state.
- **Antidote / Zim**: Fast via static compilation, but lack built-in dynamic lazy loading primitives (e.g., lazy command dispatchers, eval caching, and lazy `<Tab>` compinit).
- **Oh-My-Zsh Plugin Friction**: Oh-My-Zsh plugins often depend on unspoken internal OMZ libraries (`lib/*.zsh`), causing errors like `command not found: current_branch` when loaded in standalone managers.

Users need a plugin manager where `.zshrc` configuration is as simple as listing plugins in a clean array, while the underlying engine guarantees sub-2ms warm startup, automatic canonical ordering, seamless Oh-My-Zsh/Prezto compatibility, and transparent lazy loading.

## Users and Stakeholders

- **Zsh Users & Dotfiles Maintainers**: Developers who want a rich terminal experience (autosuggestions, syntax highlighting, completions, prompts, git integration) without shell lag.
- **Cross-Platform Developers**: macOS and Linux users running interactive terminal splits, tabs, and SSH sessions where startup speed is directly perceptible.

## Goals

- **Sub-2ms Warm Interactive Startup**: In warm interactive sessions, `zload` loads pre-compiled bytecode bundles directly with zero subprocess forks.
- **Human-First Declarative Configuration**: Support listing plugins in an intuitive array syntax `zload ( user/plugin omz:git ... )` or line-by-line `zload user/plugin`.
- **Zero-Friction Oh-My-Zsh & Prezto Compatibility**: Automatically handle OMZ plugins (`omz:git` or `ohmyzsh/plugins/git`), including their completion definitions and implicit `lib/*.zsh` dependencies.
- **Built-in Safe Lazy Loading**:
  - Automatically defer `compinit` to the first `<Tab>` press or post-prompt idle.
  - Provide command stubs (`--on <cmd1,cmd2>`) so heavy tools load only when invoked.
  - Safely schedule post-prompt UI hooks (`--defer` / `--idle`).
- **Automatic Canonical Ordering**: Automatically order completions, compinit, syntax highlighting, autosuggestions, and substring search into safe execution order regardless of declaration order.
- **Pure Zsh Engine**: 100% pure Zsh builtins and modules for runtime execution; zero external dependencies (no Python, Go, Rust, or jq).

## Non-goals

- Writing our own prompt engine or reimplementing powerlevel10k/starship.
- Replacing package managers (Homebrew, apt, pacman) for general system binaries.
- Windows Command Prompt / PowerShell support (Zsh on macOS, Linux, WSL, and BSD only).

## Current Behavior

New project repository. No current implementation exists.

## Desired Behavior

1. User adds to `.zshrc`:
   ```zsh
   source ~/.zload/zload.zsh

   zload (
     romkatv/powerlevel10k
     zsh-users/zsh-autosuggestions
     zsh-users/zsh-syntax-highlighting
     zsh-users/zsh-completions
     omz:git
     lukechilds/zsh-nvm --on nvm,node,npm
   )
   ```
2. **Cold run (first start or config modified)**:
   - Clones missing repositories shallowly (`git clone --depth 1`).
   - Identifies plugin entrypoints, completion directories, and OMZ dependencies.
   - Slices and compiles the active configuration into `~/.cache/zload/bundle.zsh` and byte-compiles it to `~/.cache/zload/bundle.zsh.zwc`.
   - Records configuration signature to detect changes.
3. **Warm run (every normal shell launch)**:
   - Compares the active configuration signature.
   - Slices directly into the compiled `.zwc` memory map in < 2ms.
   - Zero forks, zero `git` operations, zero directory scans.
4. **Lazy tab completion**:
   - `compinit` is hooked into the initial completion widget (`expand-or-complete`).
   - Typing commands does not wait on compinit.
   - Pressing `<Tab>` triggers fast `compinit -C`, unhooks the stub, and executes the completion seamlessly.

## Requirements

- **REQ-001 (Configuration Syntax)**: Must accept both array-style invocation `zload ( ... )` and individual command invocation `zload <source> [options]`.
- **REQ-002 (Source Resolution)**: Must resolve:
  - GitHub shorthand: `user/repo`
  - Version/branch/tag: `user/repo#branch` or `user/repo@v1.0.0`
  - Oh-My-Zsh plugins/themes: `omz:plugins/<name>`, `omz:<name>`, or `omz:themes/<name>`
  - Prezto modules: `prezto:<module>`
  - Full Git URLs: `https://*.git` or `git@*`
  - Local directories: `~/path/to/plugin` or `/path/to/plugin`
  - Raw snippets: `snippet:https://.../script.zsh`
- **REQ-003 (Oh-My-Zsh Dependency Shims)**: Must detect OMZ plugins requiring OMZ library helpers (e.g. `lib/git.zsh`) and source required library files before loading the plugin.
- **REQ-004 (Zero-Fork Warm Startup)**: On interactive warm startup where plugins are installed and compiled, must not fork any external process (`git`, `sed`, `grep`, `uname`, `which`).
- **REQ-005 (Compilation & Invalidation)**: Must concatenate static plugin code into a consolidated bundle and compile with `zcompile -R`. Must store a SHA-256 or fast checksum of the plugin declaration list, rebuilding the bundle automatically when the list changes.
- **REQ-006 (Canonical Ordering)**: Must sort plugins internally so that completions precede compinit, compinit precedes syntax highlighting, and syntax highlighting precedes autosuggestions.
- **REQ-007 (Lazy Command Dispatchers)**: The `--on <cmds>` flag must define stub functions for `<cmds>` that, upon first invocation, unfunction themselves, load the target plugin, and re-execute the called command with original arguments.
- **REQ-008 (Lazy Compinit)**: Must provide an automatic or opt-in `--lazy-comp` mode that defers `compinit` execution until the first completion widget invocation.
- **REQ-009 (Binary/PATH Integration)**: Must automatically append `bin/` directories located in cloned plugin roots to `$PATH`.
- **REQ-010 (Management Subcommands)**: Must support CLI subcommands:
  - `zload update`: Updates installed plugins in parallel via Git.
  - `zload clean`: Removes unreferenced plugin directories from cache.
  - `zload list`: Displays all configured and installed plugins with status.
  - `zload compile`: Manually forces bundle recompilation.
  - `zload doctor`: Runs environment diagnostics and reports issues.
- **REQ-011 (Non-interactive Safety)**: In non-interactive shells (`[[ ! -o interactive ]]`), must bypass all prompt hooks, ZLE widgets, and lazy keybindings while preserving PATH additions.

## Invariants and Security Boundaries

- **State Isolation**: Plugin installations are stored under `${XDG_DATA_HOME:-$HOME/.local/share}/zload/plugins` and cache artifacts under `${XDG_CACHE_HOME:-$HOME/.cache}/zload`.
- **No Network on Interactive Startup**: An interactive shell launch must never attempt outbound network connections. All downloads occur on explicit install/update or initial missing-plugin detection.
- **Sanitized Repository Paths**: Repository names and URLs must be normalized into safe filesystem names without path traversal (`../`) vulnerabilities.
- **Executable Integrity**: Compiled `.zwc` bundles must have permissions restricted to owner (`0600` or `0644`).

## Definition of Done

- 100% of unit and integration tests passing in modern Zsh (`zsh >= 5.1`).
- Verification via benchmark script demonstrating warm interactive startup overhead < 2.0 ms.
- Successful resolution and execution of OMZ plugins (e.g. `omz:git`), GitHub plugins, local plugins, and lazy command stubs.
- No subprocesses spawned during warm interactive startup.

## Acceptance Criteria

- **AC-001**: Given a `.zshrc` with `zload ( zsh-users/zsh-autosuggestions )`, when starting a warm shell, `zsh-autosuggestions` is loaded and warm shell execution adds < 2ms to startup.
- **AC-002**: Given `zload "omz:git"`, when a user enters a Git repository and executes `current_branch`, the function executes successfully without missing library errors.
- **AC-003**: Given `zload "my/heavy-tool" --on "heavy"`, when the shell starts, `heavy` is defined as a stub function; when the user runs `heavy --version`, the plugin sources and the command executes.
- **AC-004**: Given a modified plugin list, when a new shell is launched, `zload` detects the signature difference, invalidates the old cache, and builds a fresh compiled bundle.
- **AC-005**: Given an interactive shell with lazy compinit enabled, when the user launches the shell, `compinit` has not run yet; upon pressing `<Tab>`, `compinit` runs and standard completion suggestions display.

## Edge Cases

- **Plugin with no `.plugin.zsh`**: Must fall back to `<repo-name>.zsh`, then `*.plugin.zsh`, then `*.zsh`, avoiding test or build scripts.
- **Failed Git clone (offline / auth failure)**: Must report a clear error message without corrupting bundle state.
- **Simultaneous terminal windows**: Atomic file replacement (write to temp file then `mv`) for the bundle and `.zwc` to prevent race conditions.
- **Pre-existing compinit**: If user or prompt (e.g., grml or p10k) already initialized completion, detect and avoid redundant compinit execution.

## Constraints

- Runtime implementation must be pure Zsh script; no third-party runtimes (Python, Node, Go, Rust).
- Compatible with Zsh 5.1 and higher across macOS, Linux, and BSD.
- Maximize use of Zsh parameter expansion, flag substitution, and builtins over external calls.

## Risks and Mitigations

- **Risk**: A plugin modifies ZLE widgets or keybindings during deferred execution, breaking user keystrokes.
  - **Mitigation**: Distinguish between static plugins (bundled and loaded at prompt) and command stubs (loaded only on explicit execution). Keep syntax-highlighting in its safe canonical position.
- **Risk**: OMZ updates or changes structure of `lib/` files.
  - **Mitigation**: Pin OMZ clone to a reliable commit or allow shallow auto-syncing with fallback shims for the most common helpers (`git.zsh`).

## References

- Roman Perepelitsa, `zsh-bench`: https://github.com/romkatv/zsh-bench
- Marlon Richert, `zsh-snap`: https://github.com/marlonrichert/zsh-snap
- Matt McHenry, `antidote`: https://github.com/mattmc3/antidote
- Alexandros Kozak, `zcomet`: https://github.com/agkozak/zcomet
