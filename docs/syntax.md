# zload Declaration Syntax & Input Flexibility

`zload` is designed to be extraordinarily flexible with how you declare plugins, themes, and snippets. You can choose the format that best fits your workflow and editor preferences.

---

## 1. Native Zsh Array (Recommended)

Storing plugins in an array is the cleanest and most idiomatic format in Zsh:

```zsh
plugins=(
  casonadams/zline
  romkatv/powerlevel10k
  omz:lib/theme-and-appearance.zsh
  omz:lib/key-bindings.zsh
  omz:lib/completion.zsh
  casonadams/fzf.zsh
  casonadams/walh-shell
  lukechilds/zsh-nvm --on nvm,node,npm
  ptavares/zsh-direnv
  ptavares/zsh-tfswitch
  zsh-users/zsh-syntax-highlighting --defer
  zsh-users/zsh-autosuggestions
)

zload "${plugins[@]}"
```

### Why Arrays Are Recommended:
- **Editor Syntax Highlighting**: Each token and path is highlighted individually in your editor.
- **Native Tilde Expansion**: `~` expands automatically at parse time without string replacement.
- **Line Comments**: You can add comments directly on any line (`# comment`).
- **Composition**: You can append conditionally (`[[ $OSTYPE == darwin* ]] && plugins+=(...)`).

---

## 2. Multiline String Syntax

If you prefer a single quoted block with linebreaks:

```zsh
zload "
  romkatv/powerlevel10k
  omz:lib/theme-and-appearance.zsh
  casonadams/fzf.zsh
  lukechilds/zsh-nvm --on nvm,node,npm
  zsh-users/zsh-syntax-highlighting --defer
  zsh-users/zsh-autosuggestions
"
```

### Features:
- Blank lines and whitespace are automatically trimmed.
- Comment lines starting with `#` are automatically ignored.
- Options like `--on`, `--defer`, and `--path` attach naturally to the preceding plugin (see [Options](#options)).

---

## 3. Line-by-Line Declarations

You can invoke `zload` line-by-line across separate sections of your `.zshrc`:

```zsh
zload romkatv/powerlevel10k
zload omz:git
zload zsh-users/zsh-syntax-highlighting --defer
zload zsh-users/zsh-autosuggestions
```

Every `zload` call has its own cached bundle, so separate calls all stay on the warm path. Canonical ordering (completions first, syntax highlighting and autosuggestions last) is applied **within** a call, so put plugins that depend on each other in the same call. See [How zload Works](how-it-works.md).

---

## 4. Inline Arguments

Declare multiple plugins in a single command invocation:

```zsh
zload zsh-users/zsh-completions omz:git romkatv/powerlevel10k
```

---

## Supported Source Formats

| Format | Example | Description |
|---|---|---|
| **GitHub repo** | `user/repo` | Resolves to `https://github.com/user/repo.git` |
| **Specific Tag** | `user/repo@v1.2.0` | Checks out pinned Git tag |
| **Specific Branch** | `user/repo#develop` | Checks out pinned Git branch |
| **Specific Commit** | `user/repo@3f2a9c1` | Checks out a pinned commit SHA (7-40 hex chars) |
| **Oh-My-Zsh Plugin** | `omz:git` or `omz:plugins/git` | Fetches plugin from shared OMZ shallow clone |
| **Oh-My-Zsh Theme** | `omz:themes/robbyrussell` | Loads theme file and color/git dependencies |
| **Oh-My-Zsh Library** | `omz:lib/git.zsh` | Sourced directly from OMZ libraries |
| **Prezto Module** | `prezto:utility` | Loads Prezto module and autoloads its `functions/` |
| **Remote Snippet** | `snippet:https://.../tool.zsh` | Downloads raw file via curl without Git clone |
| **GitHub Release Binary** | `user/repo --from gh-r` | Downloads matching OS/Arch precompiled binary into PATH |
| **Git Remote URL** | `https://gitlab.com/group/repo.git` | Clones any arbitrary remote Git repository |
| **SSH Git URL** | `git@github.com:user/repo.git` | Clones over SSH; `@ref` / `#ref` suffixes work as for other URLs |
| **Local Directory** | `~/code/my-local-plugin` | Sources local development plugin from disk (`/abs`, `~/`, `./rel`, `../rel`) |

> A `@ref` can be a tag, a branch name, or a commit SHA (7-40 hex characters). Tags and branches are cloned directly; a SHA is fetched afterwards, and abbreviated SHAs need a remote that resolves them (GitHub does).

---

## Options

Options follow the plugin they apply to. Aliases are listed together.

| Option | Applies to | Effect |
|---|---|---|
| `--on cmd1,cmd2` | any | Define proxy functions for those commands; the plugin is sourced when one is first run ([lazy loading](lazy-loading.md)) |
| `--on-dir pattern` | any | Load when the working directory matches `pattern` or contains a file named `pattern` ([lazy loading](lazy-loading.md)) |
| `--defer`, `--idle` | any | Load right after the first prompt is drawn ([lazy loading](lazy-loading.md)) |
| `--path dir`, `--subpath dir` | any | Use a subdirectory of the plugin as its root (monorepos) |
| `--bin dir` | any | Add `dir` (relative to the plugin) to `$PATH` |
| `--build cmd`, `--hook cmd` | Git | Run `cmd` inside the clone after install and after `zload update` pulls new commits |
| `--from gh-r` (or `github-releases`) | `user/repo` | Install a precompiled GitHub release asset matching your OS and CPU into `$PATH` |
| `--sha256 hash` | snippets, `--from gh-r` | Reject the download unless its SHA-256 matches |

Options that take a value need it as the next argument: `zload user/repo --build "make install"`.

### Integrity checks

```zsh
# Reject a snippet whose contents change unexpectedly
zload snippet:https://example.com/tool.zsh --sha256 <sha256-of-the-file>

# Release binaries: verified against --sha256 when given, otherwise against
# a published .sha256 / .sha256sum asset when the release has one
zload sharkdp/fd --from gh-r
```

A failed check installs nothing and reports an error.
