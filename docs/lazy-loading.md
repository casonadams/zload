# zload Lazy Loading Primitives

`zload` provides three distinct, safe mechanisms for lazy loading plugins to keep interactive shell startup strictly under 1 millisecond.

---

## 1. Command Proxy Stubs (`--on`)

Heavy development environments (like `nvm`, `pyenv`, `thefuck`, `kubectl` plugins) often take 50–200ms to initialize synchronously at shell startup.

With `--on`, `zload` registers lightweight placeholder functions that self-replace upon first execution:

```zsh
zload lukechilds/zsh-nvm --on nvm,node,npm
zload ptavares/zsh-tfswitch --on tfswitch,terraform
```

### How it Works:
1. At shell startup, `zload` registers instant proxy functions:
   ```zsh
   nvm() {
     unfunction nvm node npm
     source ~/.local/share/zload/plugins/lukechilds---zsh-nvm/zsh-nvm.plugin.zsh
     "$0" "$@"
   }
   ```
2. Startup cost: **0.02 ms**.
3. When you run `nvm use 20` or `node -v`:
   - All related stubs are unfunctioned.
   - The plugin is sourced.
   - The real command executes with all original arguments preserved.
   - Subsequent calls execute directly with zero proxy overhead.

---

## 2. Directory-Triggered Lazy Loading (`--on-dir`)

Plugins that are only needed in specific directories (e.g. Git repositories, Node packages, Cargo workspaces) do not need to be loaded when opening a terminal in your home directory.

With `--on-dir`, `zload` defers loading until you navigate into a matching directory:

```zsh
# Load only when entering a Git repository
zload "davidde/git-time-metric" --on-dir ".git"

# Load only when entering a Node project
zload "wbinglee/zsh-wakatime" --on-dir "package.json"

# Load when entering any directory matching a pattern
zload "custom/dev-plugin" --on-dir "~/work/*"
```

### How it Works:
1. If the shell opens already inside a matching directory, the plugin loads immediately.
2. If not, a lightweight `chpwd` hook is registered.
3. Upon `cd` into a matching directory:
   - The plugin is loaded.
   - The `chpwd` hook cleanly deregisters itself.

---

## 3. Post-Prompt Idle Deferral (`--defer` / `--idle`)

For plugins that only touch prompt visuals or terminal syntax highlighting:

```zsh
zload zsh-users/zsh-syntax-highlighting --defer
```

### How it Works:
- In interactive shells, deferred plugins load immediately **after** the first prompt appears on screen via `precmd`.
- In non-interactive scripts (`zsh -c "..."`), deferred plugins source immediately so dependencies are never missing.

---

## 4. Post-Install Build Hooks (`--build`)

For plugins that require a compilation or install step before first use (e.g. `fzf`, `pure` prompt):

```zsh
zload "junegunn/fzf" --build "./install --bin" --bin "bin"
```

### How it Works:
- Runs `./install --bin` inside the cloned directory right after cloning.
- Runs again during `zload update` if new commits were pulled.
- **Zero runtime overhead**: The build hook is never run during shell startup.
