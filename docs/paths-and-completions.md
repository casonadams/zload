# Smart PATH & Completion Management in zload

`zload` completely replaces fragile, repetitive `export PATH=...` and `autoload -Uz compinit` boilerplate with high-performance, deduplicating primitives.

---

## 1. Native Array `$PATH` Management (`zload path`)

Traditional `.zshrc` files often accumulate dozen-line blocks of `export PATH="$PATH:/dir"`. This causes:
- Duplicate entries every time `.zshrc` is re-sourced in subshells or tmux panes.
- Dead directories from uninstalled tools that force pointless `stat` syscalls during command lookup.

### Recommended Usage
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

### Key Capabilities:
- **Existence Validation**: Only directories that actually exist on disk are added. Dead or deleted paths are filtered out automatically, preventing command lookup stalls.
- **Tilde & Variable Expansion**: Automatically expands `~`, `$HOME`, and relative paths into clean canonical paths.
- **Strict Deduplication**: Guarantees each directory appears exactly once at the front of `$PATH`, even when `.zshrc` is re-sourced repeatedly.
- **Inspection**: Run `zload path` with no arguments to print your clean, active `$PATH` one entry per line.

---

## 2. Prepend to `$fpath` (`zload fpath`)

```zsh
zload fpath ~/.my-completions /opt/homebrew/share/zsh/site-functions
```

- Verifies directory existence and deduplicates entries.
- Run `zload fpath` with no arguments to inspect all active completion directories.

---

## 3. Automatic `~/.zfunc` Discovery

If `~/.zfunc` exists on your system (the standard directory for tools like `uv`, `rustup`, `pipx`, `bwc`), `zload` automatically discovers it and links it into `$fpath` in both live sessions and the compiled `.zwc` bundle.

**Zero configuration required in `.zshrc`!**

For example, generating completions for `uv`:
```zsh
uv generate-shell-completion zsh > ~/.zfunc/_uv
```
`zload` immediately discovers and enables `uv <Tab>` autocompletion without needing a single extra line in your `.zshrc`.

---

## 4. Lazy `<Tab>` Compinit

Normally, `compinit` scans `$fpath`, audits permissions, generates `.zcompdump`, and installs ZLE completion widgets, taking **30–120ms** every time a terminal opens.

### How `zload` Optimizes It:
1. When your shell opens, the prompt draws in **0 ms**.
2. If any plugin calls `compdef` before compinit runs, `zload` buffers the call safely.
3. On the very first `<Tab>` keystroke, `zload`:
   - Runs `compinit -C` against the cached dump.
   - Byte-compiles the dump file (`.zcompdump.zwc`).
   - Replays all buffered `compdef` calls.
   - Restores native ZLE completion widgets.
4. Subsequent `<Tab>` keystrokes run at native Zsh speeds.

### Usage in `.zshrc`
Place `zload compinit --lazy` immediately after your plugin declarations:
```zsh
plugins=(
  omz:git
  omz:lib/completion.zsh
  zsh-users/zsh-completions
)
zload "${plugins[@]}"

# Initialize completions lazily (defers compinit until first <Tab>)
zload compinit --lazy
```

---

## 5. Interactive Menu Selection & Highlighting

By default, bare Zsh lists completion candidates without an interactive cursor or highlight box. `zload` does not inject intrusive styling opinions behind your back, but you can enable highlighted menu navigation using either Oh-My-Zsh's library or native Zsh styles.

### Option A: Oh-My-Zsh Completion Library (OMZ Migrators)

Add `omz:lib/completion.zsh` to your `plugins=(...)` array:

```zsh
plugins=(
  omz:lib/completion.zsh
  zsh-users/zsh-completions
  # ... other plugins ...
)
zload "${plugins[@]}"
zload compinit --lazy
```

This imports OMZ's completion defaults (`zmodload -i zsh/complist`, `zstyle ':completion:*:*:*:*:*' menu select`, case-insensitive matching, and process coloring).

> **Note on OMZ Tab Behavior**: OMZ completion sets `auto_menu` and unsets `menu_complete`. The first `<Tab>` displays candidate matches, and the second `<Tab>` activates interactive menu selection with the highlighted cursor.

### Option B: Native Zsh Styles (Zero External Dependencies)

If you prefer not pulling in Oh-My-Zsh, configure native Zsh styles directly in `~/.zshrc`:

```zsh
# Load complist module (required for menu selection & list coloring)
zmodload -i zsh/complist

# Enable menu selection with highlighted cursor on Tab
zstyle ':completion:*' menu select

# Colorize completion entries matching LS_COLORS
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Reverse navigation with Shift-Tab
bindkey -M menuselect '^[[Z' reverse-menu-complete
```
