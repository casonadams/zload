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

# Update both zload itself and all plugins:
zload update --all

# Update only zload itself:
zload update --self
```

- Pulls fast-forward updates across all active plugins.
- Skips pinned release tags and local directories.
- Automatically triggers `zload compile` upon completion so the warm bytecode bundle is always in sync.

---

## 5. `zload upgrade` / `zload self-update`

Upgrades `zload` itself to the latest commit/release from upstream Git and recompiles all internal modules.

### Usage
```zsh
zload upgrade
# or:
zload self-update
```

---

## 6. `zload clean [-f|--force]`

Prunes unreferenced plugins from disk that were removed from `.zshrc`.

### Usage
```zsh
# Dry run: lists unreferenced directories on disk
zload clean

# Forced deletion: deletes unreferenced directories
zload clean -f
```

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

### Usage
```zsh
# Lazy completion: defers compinit until first <Tab> press (recommended, default)
zload compinit --lazy

# Immediate completion: runs compinit synchronously
zload compinit
```
