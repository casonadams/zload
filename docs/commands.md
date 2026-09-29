# zload CLI Commands Reference

`zload` provides a complete suite of built-in management commands to inspect, update, clean, and profile your environment.

All output uses standardized **term16 colors (0–15)** for optimal contrast across both light and dark terminals.

---

## 1. `zload path`

Manages `$PATH` additions with automatic existence validation, tilde expansion, and strict deduplication.

### Usage
```zsh
# Using native array syntax (recommended):
user_paths=(
  ~/.opencode/bin
  ~/.cargo/bin
  ~/.local/bin
  /opt/homebrew/bin
  /opt/homebrew/sbin
  /usr/local/bin
)
zload path "${user_paths[@]}"

# Or multiline string syntax:
zload path "
  ~/.cargo/bin
  ~/.local/bin
  /opt/homebrew/bin
"

# Inspect current deduplicated PATH:
zload path
```

---

## 2. `zload fpath`

Manages `$fpath` additions for custom completions.

### Usage
```zsh
zload fpath ~/.my-completions /opt/homebrew/share/zsh/site-functions

# Inspect current fpath:
zload fpath
```

> **Note**: If `~/.zfunc` exists on your system (standard directory for `uv`, `rustup`, `pipx`, `bwc`), `zload` automatically detects it and adds it to `$fpath`. You do not need to declare `~/.zfunc` manually!

---

## 3. `zload eval`

Caches the output of slow subshell initializers (e.g. `starship`, `zoxide`, `direnv`) into compiled wordcode (`.zwc`).

### Usage
```zsh
# Instead of: eval "$(starship init zsh)"
zload eval starship "starship init zsh"

# Instead of: eval "$(zoxide init zsh)"
zload eval zoxide "zoxide init zsh"
```

- Executes the command once and saves output to `~/.cache/zload/eval/<name>.zsh`.
- Automatically compiles to `.zwc`.
- On subsequent shell startups, memory-maps the compiled file in **0.2 ms** with **0 subprocess forks**.
- Automatically invalidates and recompiles when the tool binary timestamp changes.

---

## 4. `zload update`

Updates all installed plugins and remote assets in parallel via Git background tasks.

### Usage
```zsh
# Update all installed plugins:
zload update

# Force update (discards local dirty changes in plugin working trees):
zload update -f

# Update both zload itself and all plugins:
zload update --all

# Update only zload itself:
zload update --self
```
- Pulls fast-forward updates across all active plugins in parallel.
- Pass `-f` or `--force` to reset local modifications and discard untracked files before pulling.
- Reports commit diffs (`old_commit -> new_commit`) for modified plugins and marks unchanged ones as up to date.
- Re-runs plugin build hooks (`--build` / `--hook`) automatically whenever new commits are pulled.
- Re-fetches and recompiles remote snippets (`snippet:...`).
- Automatically triggers `zload compile` upon completion so the warm bytecode bundle is always in sync.
- Invalidates completion dump caches (`zcompdump*`) when plugin changes are detected.

---

## 5. `zload upgrade` / `zload self-update`

Upgrades `zload` itself to the latest commit/release from upstream Git, recompiles all internal modules and core entrypoints, clears the runtime cache (`~/.cache/zload`), and reloads updated functions in the active shell session while preserving your installed plugins in `$ZLOAD_DATA`.

### Usage
```zsh
zload upgrade
# or:
zload self-update
```

- Pulls fast-forward updates from the upstream Git repository.
- Cleans stale wordcode artifacts and recompiles `zload.zsh` and all `functions/` modules into `.zwc`.
- Wipes `~/.cache/zload` to invalidate old bytecode bundles and completion dumps.
- Immediately re-autoloads updated functions into the active shell without requiring an `exec zsh`.
- Preserves `$ZLOAD_DATA` (`~/.local/share/zload/plugins`), so cloned plugins are never deleted during an upgrade.

---

## 6. `zload clean [-f|--force]`

Prunes unreferenced plugins from disk that were removed from `.zshrc`, and flushes stale bundle caches when forced.

### Usage
```zsh
# Dry run: lists unreferenced directories on disk
zload clean

# Forced deletion: deletes unreferenced directories and flushes stale bundle caches
zload clean -f
```

- Compares active plugin declarations against `$ZLOAD_PLUGINS`.
- When called with `-f` or `--force`, deletes unreferenced plugin directories and removes stale `bundle.*` and completion dump caches from `~/.cache/zload`.

---

## 6. `zload list`

Lists all installed plugins, their active Git branches, release tags, and current commit SHAs.

### Usage
```zsh
zload list
```

---

## 7. `zload which` & `zload cd`

Developer navigation helpers to locate and inspect plugin code.

### Usage
```zsh
# Print full canonical directory path
zload which omz:git
# => /Users/cadams/.local/share/zload/plugins/_omz/plugins/git

zload which zsh-autosuggestions
# => /Users/cadams/.local/share/zload/plugins/zsh-users---zsh-autosuggestions

# Change directory directly into the plugin repository
zload cd zsh-autosuggestions
```

---

## 8. `zload doctor [--fix]`

Runs comprehensive diagnostics on your Zsh runtime version, Git presence, directory permissions, bytecode cache validity, and completion dump health.

### Usage
```zsh
# Run diagnostics:
zload doctor

# Self-healing repair: automatically restores missing or stale .zwc files
zload doctor --fix
```

---

## 9. `zload profile`

Measures high-resolution microsecond startup latency breakdown using `$EPOCHREALTIME`.

### Usage
```zsh
zload profile
```

---

## 10. `zload lock` & `zload sync`

Generates deterministic lockfiles for dotfile syncing across machines.

### Usage
```zsh
# Export pinned commit hashes to lockfile:
zload lock
zload lock ~/dotfiles/zload.lock

# Synchronize installed plugins to match exact lockfile commits:
zload sync
zload sync ~/dotfiles/zload.lock
```

---

## 11. `zload compile`

Manually recompiles the static plugin bundle (`bundle.zsh`), `zload.zsh`, and all internal helper modules into memory-mapped wordcode (`.zwc`).

### Usage
```zsh
zload compile
```

---

## 12. `zload compinit [--lazy]`

Initializes or defers the Zsh completion system.

> **Note**: `zload` automatically arms lazy compinit whenever plugins are declared. You only need this command if you opted out with `ZLOAD_NO_COMPINIT=1`, desire synchronous initialization, or initialize completions without plugins.

### Usage
```zsh
# Lazy completion: defers compinit until first <Tab> press (default behavior)
zload compinit --lazy

# Immediate completion: runs compinit synchronously during shell startup
zload compinit
```

- When run with `--lazy`, intercepts early `compdef` calls from plugins, draws your prompt in 0 ms, and triggers compilation and caching on your first `<Tab>` press.
- Pair with `omz:lib/completion.zsh` or native `zstyle ':completion:*' menu select` for interactive highlighted menu navigation.
- Set `export ZLOAD_NO_COMPINIT=1` to disable automatic completion initialization.
