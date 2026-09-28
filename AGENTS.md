# Repository Instructions

## Core Architecture & Performance Invariants

- **Warm Startup Overhead Target**: Warm interactive startup must strictly remain **< 0.5 ms** (hard ceiling < 2.0 ms on any hardware).
- **Zero Subprocess Invariant**: Interactive warm startup must never fork any external processes (`git`, `sed`, `grep`, `uname`, `which`, `find`, `cut`, `awk`, or `$(...)` subshells). All warm path logic must rely 100% on internal Zsh builtins, parameter expansions, and memory-mapped bytecode wordcode (`bundle.zsh.zwc`).
- **Entrypoint Simplicity**: Keep `zload.zsh` lean and fast. Autoload subcommands and helpers from `functions/` (prefixed with `_zload_`) so they are parsed into memory only when invoked.
- **Autoload Function Cleanliness**: Files in `functions/` must not contain unencapsulated top-level commands outside function definitions. Naked statements outside function blocks break Zsh's autoload mechanism on first call.
- **No Complex Hook DSLs**: Avoid bloated hook DSLs (`atinit`, `atload`, `atclone`, `atpull`). In Zsh, standard shell commands before and after `zload` provide natural, transparent execution.

---

## Documentation & Website Synchronization

When adding, modifying, or removing observable features, CLI subcommands, flags, or configuration options, update all documentation assets together to keep them in lockstep:

1. **`README.md`**: Keep it clean, direct, and concise (rho-style) with bulleted links pointing to dedicated `docs/` guides.
2. **`docs/` Markdown Files**:
   - `docs/commands.md`: Complete CLI reference table and options.
   - `docs/syntax.md`: Declaration formats and supported source URLs.
   - `docs/lazy-loading.md`: Command stubs, directory triggers, and build hooks.
   - `docs/paths-and-completions.md`: PATH deduplication, `~/.zfunc`, and lazy compinit.
3. **UNIX Manual Page (`man/man1/zload.1`)**: Maintain standard troff/groff manual formatting so `man zload` remains accurate.
4. **Website Pages (`www/index.html`, `www/docs.html`, `www/css/style.css`)**:
   - Keep the landing page and documentation site synchronized with current CLI behavior.
   - Whenever CSS updates occur, increment the cache-busting query parameter (e.g. `css/style.css?v=N`).
5. **Array-First Convention**: Always feature native Zsh array syntax first in examples and documentation (`user_paths=( ... ); zload path "${user_paths[@]}"` and `plugins=( ... ); zload "${plugins[@]}"`).
6. **Prompt Recommendations**: Recommend pairing with fast prompts like Powerlevel10k or Starship to complement speed, without embedding full prompt installation guides into `zload`.

---

## Terminal UI & Color Palette Standard

All CLI messages and subcommands (`zload update`, `list`, `doctor`, `profile`, `clean`, `which`) must use the **standard 16-color ANSI palette (colors 0–15)** for universal contrast across light and dark terminals:

- `%F{14}` (Bright Cyan) / `%F{6}` (Cyan): Brand prefix `zload`
- `%F{10}` (Bright Green) / `%F{2}` (Green): Success markers `✓`, `[OK]`, `[FIXED]`, up-to-date statuses
- `%F{11}` (Bright Yellow) / `%F{3}` (Yellow): Warnings, pinned refs, active operations
- `%F{9}` (Bright Red) / `%F{1}` (Red): Errors, failures, deletions
- `%F{12}` (Bright Blue) / `%F{4}` (Blue): Local plugins, info tags
- `%F{8}` (Bright Black / Gray): Muted elements, commit hashes, branches, dividers
- `%F{15}` (Bright White Bold): Highlighted plugin names and active paths

**Variable Declaration Rule**: In Zsh, executing `local var` inside a loop without an assignment prints `var=val` if `var` is already set. Always declare loop scalar variables (`local dir name branch pid pdir ref commit`) outside loops at the top of the function to prevent spurious console output.

---

## Testing & Verification Gates

Run all quality checks before committing:

1. **Clean Bytecode Artifacts**:
   ```sh
   rm -f functions/*.zwc *.zwc
   ```
2. **ShellSpec BDD Suite**:
   ```sh
   shellspec
   ```
3. **Full 5-Gate Specification Verification Runner**:
   ```sh
   zsh test/verify_all.zsh
   ```
   Ensures:
   - Gate 1: 100% clean syntax validation across all files (`zsh -n`).
   - Gate 2: Full unit and integration test suite passes.
   - Gate 3: High-resolution benchmark proves warm startup latency < 2.0 ms (target < 0.5 ms).
   - Gate 4: Zero-subprocess poison test confirms 0 child processes spawned in warm path.
   - Gate 5: Real-world Oh-My-Zsh git branch and dirty status extraction verified.

Never bypass or weaken these gates to make a build pass.
