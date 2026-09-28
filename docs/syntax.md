# zload Declaration Syntax & Input Flexibility

`zload` is designed to be extraordinarily flexible with how you declare plugins, themes, and snippets. You can choose the format that best fits your workflow and editor preferences.

---

## 1. Native Zsh Array (Recommended)

Storing plugins in an array is the cleanest and most idiomatic format in Zsh:

```zsh
plugins=(
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
- Options like `--on`, `--defer`, and `--path` attach naturally to the preceding plugin.

---

## 3. Line-by-Line Declarations

You can invoke `zload` line-by-line across separate sections of your `.zshrc`:

```zsh
zload romkatv/powerlevel10k
zload omz:git
zload zsh-users/zsh-syntax-highlighting --defer
zload zsh-users/zsh-autosuggestions
```

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
| **Oh-My-Zsh Plugin** | `omz:git` or `omz:plugins/git` | Fetches plugin from shared OMZ shallow clone |
| **Oh-My-Zsh Theme** | `omz:themes/robbyrussell` | Loads theme file and color/git dependencies |
| **Oh-My-Zsh Library** | `omz:lib/git.zsh` | Sourced directly from OMZ libraries |
| **Prezto Module** | `prezto:utility` | Loads Prezto module and autoloads its `functions/` |
| **Remote Snippet** | `snippet:https://.../tool.zsh` | Downloads raw file via curl without Git clone |
| **GitHub Release Binary** | `user/repo --from gh-r` | Downloads matching OS/Arch precompiled binary into PATH |
| **Git Remote URL** | `https://gitlab.com/group/repo.git` | Clones any arbitrary remote Git repository |
| **Local Directory** | `~/code/my-local-plugin` | Sources local development plugin from disk |
