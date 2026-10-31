# How zload Works

This page explains what happens at shell startup, what is cached, when the cache is rebuilt, and how to diagnose problems.

---

## 1. Cold Start vs Warm Start

Every `zload <plugins...>` call is either **cold** (first time, or the declaration changed) or **warm** (unchanged since the last shell).

| | Cold start | Warm start |
|---|---|---|
| Runs when | A plugin is missing, or the arguments of that `zload` call changed | The arguments are identical to the cached call |
| Work done | Installs missing plugins (in parallel), resolves each plugin's entry script, `fpath` and `bin` directories, sorts plugins into canonical order, writes and compiles the bundle | Sources one pre-compiled bundle |
| Subprocesses | `git` / `curl` / `tar` as needed | **None** |
| Cost | Depends on network and plugin count | ~0.6 ms for 10 plugins (see `zsh benchmark/bench.zsh`) |

The warm path uses only Zsh builtins: it compares the raw arguments of the call with a cached copy and sources `bundle.zsh` (memory-mapped through `bundle.zsh.zwc`).

### One bundle per `zload` call

Each `zload` call in your `.zshrc` has its own bundle, numbered by position: the first call uses `bundle.zsh`, the second `bundle.2.zsh`, and so on. Each bundle is checked against the exact arguments of its own call, so:

- You can split plugins across several `zload` calls and every call stays warm.
- Changing one call rebuilds only that call's bundle.
- Inserting a new call in the middle renumbers the calls after it, so those bundles rebuild once.

Management commands (`zload path`, `zload eval`, `zload update`, ...) do not count as plugin calls.

---

## 2. Canonical Load Order

Within one `zload` call, plugins are sorted so ordering mistakes cannot break your shell. Plugins that match none of the rules keep their declared order.

| Order | Matches |
|---|---|
| 1 | `zsh-completions` |
| 2 | themes and prompts (`theme`, `prompt`, `powerlevel10k`, `zline`) |
| 3 | everything else, in declared order |
| 4 | `zsh-syntax-highlighting` |
| 5 | `zsh-autosuggestions` |
| 6 | `zsh-history-substring-search` |

Plugins declared with `--on`, `--on-dir` or `--defer` are placed in the bundle as proxy stubs, directory hooks or a deferred queue instead of being sourced immediately.

---

## 3. What Invalidates the Cache

| Event | Effect |
|---|---|
| Change the arguments of a `zload` call (add, remove, reorder, edit an option) | That call's bundle rebuilds on the next shell start |
| `zload update`, `zload sync`, `zload compile` | Every bundle is rebuilt in place; completion dump is cleared when something changed |
| `zload clean -f` | Removes unreferenced plugins, all `bundle.*` files and the completion dump |
| `zload upgrade` | Wipes the whole cache directory and reloads zload |
| A bundle is rebuilt with different content | `zcompdump*` is deleted so new completions are discovered |
| `zload eval <name> <cmd>`: the command string changes or the tool binary is newer than the cache | That eval cache is regenerated |

Editing a plugin's own scripts takes effect immediately, because bundles source plugins by path. The bundle records **structure** discovered at build time (which directories hold completions or binaries). If a plugin gains a new `_completion` file or `bin/` directory, run `zload compile` (or `zload update`) so the bundle picks it up.

If a call fails to install any plugin, no bundle is written for it: you get an error on stderr and the next shell start retries.

---

## 4. Files on Disk

| Path | Contents |
|---|---|
| `$ZLOAD_HOME` (default: the directory containing `zload.zsh`) | zload itself: `zload.zsh`, `functions/`, `man/` |
| `$ZLOAD_PLUGINS` (`~/.local/share/zload/plugins`) | One directory per plugin (`owner---repo`), plus `_omz`, `_prezto`, `_snippets`, and `gh-r---owner---repo/bin` |
| `$ZLOAD_CACHE/bundle[.N].zsh` and `.zwc` | Compiled bundle for the N-th `zload` call |
| `$ZLOAD_CACHE/bundle[.N].hash` | The exact arguments that bundle was built from |
| `$ZLOAD_CACHE/zcompdump-<version>` and `.zwc` | Completion dump |
| `$ZLOAD_CACHE/eval/` | `zload eval` caches and their `.zwc` |
| `$ZLOAD_DATA/zload.lock` | Default lockfile written by `zload lock` |

---

## 5. Environment Variables

| Variable | Default | Purpose |
|---|---|---|
| `ZLOAD_HOME` | Directory of `zload.zsh` | zload installation |
| `ZLOAD_DATA` | `${XDG_DATA_HOME:-~/.local/share}/zload` | Plugin and lockfile storage |
| `ZLOAD_CACHE` | `${XDG_CACHE_HOME:-~/.cache}/zload` | Bundles, completion dump, eval caches |
| `ZLOAD_PLUGINS` | `$ZLOAD_DATA/plugins` | Cloned plugins |
| `ZLOAD_NO_COMPINIT` | unset | Set (any value) to stop zload from arming lazy `compinit` |
| `GITHUB_TOKEN` | unset | Sent to the GitHub API by `--from gh-r` to avoid anonymous rate limits |
| `ZSH`, `ZSH_CACHE_DIR` | set by zload | Exported when an `omz:` plugin is declared |

---

## 6. Troubleshooting

**Start with `zload doctor`.** It checks the Zsh version, Git, directory permissions, and bundle/dump health. `zload doctor --fix` creates missing directories and compiles missing wordcode.

| Symptom | Cause and fix |
|---|---|
| A new plugin's completions do not show up | Run `zload compile` (or `zload update`) so its completion directory is added; the completion dump is cleared automatically when the bundle changes |
| `zload: failed to install <spec>` | The message is followed by git's or curl's reason. Fix the spec or network and open a new shell; no bundle was written, so it retries |
| A build hook failed | `--build` output is printed and the half-built plugin is removed so it is retried on the next start |
| `--from gh-r` says no asset matches | None of the release's assets contain your OS and CPU architecture in their file name. zload refuses to guess; install that tool another way |
| `--from gh-r` fails with a rate-limit hint | Export `GITHUB_TOKEN` |
| `checksum mismatch` / `sha256 mismatch` | The download did not match the published checksum or your `--sha256`. Nothing was installed |
| `zload sync` reports `could not check out <sha>` | The commit is not reachable from the remote (force-pushed or deleted). Run `zload lock` again from a working setup |
| Tab completion never triggers lazy `compinit` | You rebound Tab to a widget other than the six zload hooks (`expand-or-complete`, `expand-or-complete-prefix`, `complete-word`, `menu-complete`, `menu-expand-or-complete`, `reverse-menu-complete`). Call `zload compinit` after your `bindkey` lines |
| Everything feels stale after hand-editing the cache | `zload clean -f` clears bundles and the completion dump; the next shell rebuilds them |
