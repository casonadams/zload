# zload Implementation Plan

## 1. Research

Key findings from profiling and state-of-the-art Zsh tooling:
- **Zero-fork interactive execution**: macOS forks cost 2–5ms per process (`git`, `sed`, `grep`, `which`, `uname`, `cut`). Pure Zsh builtins (parameter expansions `${var#pattern}`, `${(M)...}`, `zsh/stat`, `zsh/files`) cost ~0.01ms.
- **Bytecode compilation (`zcompile`)**: Compiling concatenated shell scripts to `.zwc` wordcode files eliminates tokenization and syntax parsing overhead. Zsh memory-maps `.zwc` files directly.
- **Single-bundle sourcing vs multi-file sourcing**: Sourcing 20 individual plugin files incurs 20 `open(2)` / `read(2)` syscalls plus directory traversal. Concatenating into one `.zload/bundle.zsh` with its companion `.zwc` reduces warm startup to a single memory-mapped read (< 1.5ms).
- **Compinit deferral**: Traditional `compinit` takes 30–120ms. Intercepting ZLE completion widgets (`expand-or-complete`, `complete-word`) defers compinit until the first `<Tab>` press, cutting startup latency to near-zero with zero perceived downside to typing commands.
- **Command stubs (lazy execution)**: Heavy tools (`nvm`, `pyenv`, `thefuck`, `kubectl`) can be stubbed with lightweight functions that unfunction themselves and load the real script on first use.

## 2. Reuse

- **Zsh Builtins & Parameter Expansion**:
  - `${(q)var}`, `${(A)var}`, `${(k)var}`, `${var:t}`, `${var:h}` for fast string/path manipulation.
  - `autoload -Uz` for loading helper modules without executing them up front.
  - Built-in `zcompile -R` for memory-mapped bytecode creation.
  - Zsh modules: `zsh/stat` for file timestamps and size checks without forking `stat(1)`.
- **Git Capabilities**:
  - `git clone --depth 1 --recurse-submodules --shallow-submodules` for minimal footprint.
  - `git sparse-checkout` for granular OMZ plugin fetching if desired, or a lightweight shared OMZ repo cache.

## 3. Invariants and Security Boundaries

- **State Locations**:
  - Plugins: `${XDG_DATA_HOME:-$HOME/.local/share}/zload/plugins`
  - Cache & Bundles: `${XDG_CACHE_HOME:-$HOME/.cache}/zload`
- **Zero Subprocesses During Warm Interactive Startup**:
  - No `git`, `curl`, `subshells $(...)`, or external system utilities during warm startup.
- **Deterministic Canonical Ordering**:
  - Plugin loading sequence must be normalized: Completions -> compinit -> themes/prompts -> general plugins -> syntax highlighting -> autosuggestions -> substring search.
- **Safe Directory Names**:
  - URLs and repository identifiers sanitized using character replacement (`/` -> `---`) to prevent path traversal.

## 4. Quality Gates

- **Lint / Shell Check**: Scripts must pass `zsh -n` (syntax check) without warnings.
- **Automated Tests**: Comprehensive test suite run with standard Zsh test harness (`test/*.zsh`).
- **Startup Latency Gate**: Warm interactive shell startup must measure under 2.0ms on modern hardware.
- **Zero Subprocess Gate**: Verify via `strace` or tracing (`set -x` / subshell monitors) that zero child processes are spawned on warm load.

## 5. Definition of Done

- All functional requirements (REQ-001 through REQ-011) implemented and verified.
- Unit and integration tests verify:
  - Repository cloning and source resolution (GitHub, OMZ, local, tags/branches).
  - OMZ library dependency auto-loading (`lib/git.zsh`).
  - Bundle compilation and atomic `.zwc` cache generation.
  - Cache invalidation when plugin declarations change.
  - Lazy command dispatcher (`--on`) function replacement and argument passing.
  - Lazy compinit execution on completion trigger.
  - CLI management commands (`update`, `clean`, `list`, `doctor`, `compile`).
- Benchmark script confirms sub-2.0ms startup time.

## 6. Assumptions

- Target system has Zsh >= 5.1 (standard across macOS Mojave+, modern Linux distros).
- Git is installed and accessible in `$PATH` for install/update operations.
- User interactive shells have write access to `$HOME/.cache` and `$HOME/.local/share` (or XDG overrides).

## 7. Risks

- **Risk**: A plugin modifies ZLE widgets or keybindings during deferred execution.
  - *Mitigation*: Bundle static plugins synchronously at start; use lazy stubs only for commands explicitly designated via `--on` or safe hooks.
- **Risk**: Concurrency issues if multiple terminal windows open simultaneously while cache is regenerating.
  - *Mitigation*: Write compiled bundle to a temporary file (`bundle.zsh.tmp.$$`) and atomically move (`mv`) to `bundle.zsh`.
- **Risk**: OMZ plugin depends on multiple library files.
  - *Mitigation*: Inspect the OMZ plugin for `require` or common dependencies, or source all OMZ `lib/*.zsh` files into the bundle when any OMZ plugin is requested.

## 8. Dependencies

- Pure Zsh. Zero third-party runtime dependencies.
- Git (system tool) required only for fetching and updating remote plugins.

## 9. Decisions

- **Decision 1: Declarative Array Syntax with Parentheses**:
  - *Options*: (a) Line-by-line `zload author/plugin` only; (b) Static config file `.zload_plugins`; (c) Zsh list syntax `zload ( ... )` + line-by-line.
  - *Choice*: (c) Support both `zload ( ... )` and line-by-line.
  - *Tradeoff*: Requires light parsing of arguments inside `zload()`, but provides the ultimate developer experience.
- **Decision 2: Automated Single-File Bundle Generation**:
  - *Options*: (a) Source each plugin file in loop; (b) Generate static bundle script and `zcompile`.
  - *Choice*: Generate single static bundle script + `zcompile`.
  - *Tradeoff*: Incurs a 50ms re-generation cost when config changes, but pays back with 0.8ms startup on every subsequent shell launch.
- **Decision 3: Lazy Compinit as Default**:
  - *Options*: (a) Run compinit synchronously; (b) Omit compinit; (c) Wrap `expand-or-complete` widget to initialize on first `<Tab>`.
  - *Choice*: Wrap completion widget to initialize on first `<Tab>` (with instant fallback if already initialized).
  - *Tradeoff*: Saves 40–100ms on startup. Transparent to the user.

## 10. Out of Scope

- Native binary package management (compiling C/Rust binaries from scratch).
- GUI configuration editors.
- Non-Zsh shells (Bash, Fish).

---

## Slices

### Slice 1: Core Loader & Repository Resolution
**Goal**: Bootstrap `zload`, parse plugin declarations (GitHub, tags, branches, local paths, OMZ shorthand), and clone/resolve them safely.
**Acceptance Criteria**:
- `zload` function parses array and single-item inputs.
- Repositories are normalized and cloned to `$ZLOAD_DIR/plugins/`.
- OMZ plugins (`omz:git` or `omz:plugins/git`) are fetched into a shared OMZ directory.
- Tags and branches (`user/repo#dev`, `user/repo@v1.0`) are checked out accurately.

#### Task 1.1: Core environment & directory bootstrap [2]
**Do**: Create `zload.zsh` with base configuration variables (`ZLOAD_HOME`, `ZLOAD_CACHE`, `ZLOAD_PLUGINS`), internal state arrays, and safety checks for interactive vs non-interactive sessions.
**Context**: Respect `XDG_DATA_HOME` and `XDG_CACHE_HOME`.
**Tests**: `test/test_bootstrap.zsh`: Verifies default paths and initialization without errors.
**Verify**: `zsh -c "source zload.zsh && [[ -d \$ZLOAD_CACHE ]]"` -- exits with 0.

#### Task 1.2: Declaration parser & source resolver [3]
**Do**: Implement `_zload_parse_spec` pure Zsh function. Parses shorthand strings:
- `owner/repo[@tag|#branch]`
- `omz:<plugin>` or `omz:plugins/<plugin>` or `omz:themes/<theme>`
- `prezto:<module>`
- `https://*.git`
- `/local/path` or `~/path`
- Flags: `--on <cmds>`, `--defer`, `--bin <path>`.
**Tests**: `test/test_parser.zsh`: Table-driven tests validating parsed records (type, URL, branch/tag, subpath, flags).
**Verify**: Run `zsh test/test_parser.zsh` -- all test assertions pass.

#### Task 1.3: Plugin locator & installer [3]
**Do**: Implement `_zload_install` and `_zload_find_main_file`. Clones missing plugins shallowly. Locates entry script using canonical precedence:
1. `<repo>.plugin.zsh`
2. `<repo>.zsh`
3. `*.plugin.zsh`
4. `init.zsh`
5. `*.zsh` (excluding tests/builds)
**Tests**: `test/test_install.zsh`: Clone a dummy local git repo, resolve entry point, verify directory structure.
**Verify**: `zsh test/test_install.zsh` -- returns 0.

**Slice 1 Verification**: Run `zsh test/run_slice1.zsh` passing all parser, bootstrap, and locator test cases.

---

### Slice 2: Oh-My-Zsh & Prezto Compatibility Shims
**Goal**: Seamless execution of Oh-My-Zsh plugins and themes without requiring full Oh-My-Zsh framework installation.
**Acceptance Criteria**:
- `omz:git` loads `lib/git.zsh` automatically.
- Completions inside OMZ plugins are added to `$fpath`.
- Prompt themes from OMZ (`omz:themes/robbyrussell`) load required OMZ prompt lib files.

#### Task 2.1: Shared OMZ repository manager [2]
**Do**: Implement `_zload_ensure_omz`. Clones or manages a shared shallow clone of Oh-My-Zsh under `$ZLOAD_PLUGINS/_omz`.
**Context**: Reuses single clone across all `omz:*` references.
**Tests**: `test/test_omz.zsh`: Requesting multiple OMZ plugins clones OMZ once.
**Verify**: `zsh test/test_omz.zsh` -- single clone confirmed.

#### Task 2.2: OMZ library dependency auto-loader [3]
**Do**: Implement `_zload_omz_shim`. Detects when an OMZ plugin requires OMZ core functions. Loads `lib/git.zsh`, `lib/termsupport.zsh`, etc.
**Tests**: Test loading `omz:git` in clean zsh and verifying `current_branch` function is defined and callable.
**Verify**: `zsh -c "source zload.zsh && zload omz:git && typeset -f current_branch"` -- outputs function definition.

**Slice 2 Verification**: Run `zsh test/run_slice2.zsh`.

---

### Slice 3: Lazy Loading Primitives
**Goal**: Implement `--on <cmd1,cmd2>`, `--defer`, and lazy `compinit` on first `<Tab>`.
**Acceptance Criteria**:
- Commands specified in `--on` define instant proxy stubs.
- Invoking the command replaces the stub, loads the plugin, and forwards original arguments.
- Lazy `compinit` runs only on `<Tab>` or idle hook, keeping initial prompt delay at 0ms.

#### Task 3.1: Lazy command proxy generator (`--on`) [2]
**Do**: Implement `_zload_create_stub` in `zload.zsh`. Dynamically registers dispatcher functions for specified commands.
**Tests**: `test/test_lazy_cmd.zsh`: Define a mock plugin with `--on mycmd`. Assert `mycmd` is a stub, invoke `mycmd arg1`, verify stub replaced and mock executed with `arg1`.
**Verify**: `zsh test/test_lazy_cmd.zsh` -- passes.

#### Task 3.2: Lazy compinit widget integration [3]
**Do**: Implement `_zload_setup_lazy_compinit`. Hooks into ZLE widget `expand-or-complete`. On first `<Tab>`, runs `autoload -Uz compinit && compinit -C`, recompiles `.zcompdump.zwc`, re-binds original widget, and executes it.
**Tests**: `test/test_lazy_compinit.zsh`: Simulate widget trigger, assert compinit runs once and widget restores.
**Verify**: `zsh test/test_lazy_compinit.zsh` -- passes.

#### Task 3.3: Post-prompt idle deferral (`--defer`) [2]
**Do**: Implement `_zload_schedule_deferred`. Uses `add-zsh-hook precmd` or `zle-line-init` / `sched` to source deferred scripts right after the prompt renders.
**Tests**: `test/test_defer.zsh`: Verify deferred scripts execute on the precmd/idle event.
**Verify**: `zsh test/test_defer.zsh` -- passes.

**Slice 3 Verification**: Run `zsh test/run_slice3.zsh`.

---

### Slice 4: Bundle Compiler & Ultra-Fast Warm Startup
**Goal**: Consolidate declared plugins into a single byte-compiled script (`bundle.zsh.zwc`) delivering sub-2ms warm startup with zero subprocess forks.
**Acceptance Criteria**:
- Generates `~/.cache/zload/bundle.zsh` and compiles to `bundle.zsh.zwc`.
- Computes SHA-256/hash of plugin declarations to detect configuration edits.
- On warm startup, sources compiled bundle directly without disk scans or subprocesses.

#### Task 4.1: Canonical plugin ordering engine [2]
**Do**: Implement `_zload_sort_plugins`. Orders plugins deterministically:
1. Completions (`$fpath` setup)
2. Themes & prompts
3. Standard plugins & OMZ plugins
4. Syntax highlighting (`zsh-syntax-highlighting`, `fast-syntax-highlighting`)
5. Autosuggestions (`zsh-autosuggestions`)
6. History substring search
**Tests**: `test/test_order.zsh`: Provide out-of-order plugin list, verify output ordering is canonical.
**Verify**: `zsh test/test_order.zsh` -- passes.

#### Task 4.2: Bundle generator & `zcompile` compiler [3]
**Do**: Implement `_zload_compile_bundle`. Combines sorted scripts, environment setups, and `$fpath`/`$PATH` additions into `bundle.zsh`. Executes `zcompile -R bundle.zsh`. Writes hash signature to `bundle.hash`.
**Tests**: `test/test_bundle.zsh`: Check that `bundle.zsh` and `bundle.zsh.zwc` are produced with correct permissions.
**Verify**: `zsh test/test_bundle.zsh` -- bundle files exist and are valid.

#### Task 4.3: Fast-path warm launcher [2]
**Do**: Implement the fast-path check in `zload.zsh`:
If `bundle.zsh.zwc` exists and current declaration signature matches `bundle.hash`:
Immediately `source "$ZLOAD_CACHE/bundle.zsh"` and return.
**Tests**: `test/test_warm_startup.zsh`: Verify that warm load executes zero subshells and completes in < 2ms.
**Verify**: `zsh test/test_warm_startup.zsh` -- reports < 2.0ms startup.

**Slice 4 Verification**: Run `zsh test/run_slice4.zsh`.

---

### Slice 5: CLI Management & Quality Assurance
**Goal**: Complete user CLI subcommands (`update`, `clean`, `list`, `doctor`, `compile`) and packaging.
**Acceptance Criteria**:
- `zload update` updates plugins in parallel.
- `zload clean` deletes unreferenced plugins.
- `zload list` prints installed plugins with version and status.
- `zload doctor` checks for conflicts, uncompiled scripts, and syntax warnings.

#### Task 5.1: CLI subcommands (`list`, `clean`, `compile`) [2]
**Do**: Implement `zload list`, `zload clean`, and `zload compile` dispatchers.
**Tests**: `test/test_cli.zsh`: Run commands in test environment, verify standard output.
**Verify**: `zsh test/test_cli.zsh` -- passes.

#### Task 5.2: Parallel updater (`zload update`) [3]
**Do**: Implement `_zload_update`. Iterates through installed plugins and pulls latest updates, then automatically triggers `_zload_compile_bundle`.
**Tests**: `test/test_update.zsh`: Verify Git pull execution and recompile trigger.
**Verify**: `zsh test/test_update.zsh` -- passes.

#### Task 5.3: Diagnostic doctor & profiler (`zload doctor`, `zload profile`) [2]
**Do**: Implement `zload doctor` (checks environment, permissions, PATH, completion system) and `zload profile` (high-resolution microsecond timer breakdown using `zsh/datetime`).
**Tests**: `test/test_doctor.zsh`: Run doctor and profile in healthy test environment.
**Verify**: `zsh test/test_doctor.zsh` -- passes.

#### Task 5.4: Comprehensive test runner & benchmark harness [2]
**Do**: Create `test/run_all.zsh` and `benchmark/bench.zsh` comparing empty Zsh vs `zload` warm start vs `zload` with 10 plugins.
**Verify**: `zsh test/run_all.zsh` -- 100% tests pass.

**Slice 5 Verification**: Full test suite passes; benchmark displays warm startup overhead under 2ms.

---

### Slice 6: Remote Snippets & Monorepo Subpath Loading
**Goal**: Support direct single-file script downloads (`snippet:https://...` or `https://.../*.zsh`) and arbitrary repository subpath targeting (`--path <subdir>`).
**Acceptance Criteria**:
- `snippet:https://...` or URLs ending in `.zsh`/`.sh` download the raw script file into `${ZLOAD_PLUGINS}/_snippets/` without a full Git clone.
- Downloaded snippets are byte-compiled to `.zwc` and bundled into `bundle.zsh`.
- `--path <subdir>` targets a specific directory within any repository for script, completion, and binary discovery.
- `zload update` updates snippets conditionally via `curl -z`.

#### Task 6.1: Snippet & subpath specification parsing [2]
**Do**: Update `functions/_zload_parse_spec` to recognize `snippet:<url>`, URLs ending in `.zsh` or `.sh`, and parse `--path <subpath>`.
**Tests**: `test/test_parser.zsh`: Add test cases for `snippet:https://...` and `--path`.
**Verify**: `zsh test/test_parser.zsh` -- passes.

#### Task 6.2: Snippet downloader & compiler [3]
**Do**: Implement `_zload_install_snippet` in `functions/_zload_install`. Fetches the file via `curl -fsSL` (or file copy for `file://`), writes to `${ZLOAD_PLUGINS}/_snippets/<slug>/<filename>`, and compiles to `.zwc`.
**Tests**: `test/test_snippet.zsh`: Download a mock snippet, verify bytecode compilation and execution.
**Verify**: `zsh test/test_snippet.zsh` -- passes.

#### Task 6.3: Monorepo subpath loader [2]
**Do**: Update `functions/_zload_find_main_file` and `functions/_zload_compile_bundle` to honor `--path <subpath>` across any repository source.
**Tests**: `test/test_subpath.zsh`: Load a mock repo with a plugin in a nested subdirectory using `--path`.
**Verify**: `zsh test/test_subpath.zsh` -- passes.

**Slice 6 Verification**: Full test suite passes including `test_snippet.zsh` and `test_subpath.zsh`.

---

## Final Verification

1. **Syntax Check**: `zsh -n zload.zsh` returns 0 with no errors.
2. **Full Test Suite**: `zsh test/run_all.zsh` passes all unit and integration tests.
3. **Warm Benchmark**: `zsh benchmark/bench.zsh` demonstrates warm startup latency < 2.0ms.
4. **Subprocess Verification**: `zsh -c "source zload.zsh && zload_test_no_forks"` confirms 0 child processes spawned during warm startup.
5. **Real-world OMZ Verification**: Load `omz:git` and call `current_branch`.
