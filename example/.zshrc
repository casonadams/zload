# Minimal, ultra-fast .zshrc powered by zload
# Run with: ZDOTDIR=example zsh

# 1. Source zload
0="${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}"
0="${${(M)0:#/*}:-$PWD/$0}"
ZLOAD_ROOT="${0:A:h:h}"
source "${ZLOAD_ROOT}/zload.zsh"

# 2. Add custom paths in clean array syntax (automatically deduplicated)
user_paths=(
  ~/bin
  ~/.local/bin
  /opt/homebrew/bin
)
zload path "${user_paths[@]}"

# 3. Declare plugins in simple array syntax
plugins=(
  # Completion system & menu styling
  omz:lib/completion.zsh
  zsh-users/zsh-completions
  # Oh-My-Zsh plugins (loads lib/git.zsh automatically)
  omz:git
  omz:extract

  # Prompts & Themes (e.g. zline, Powerlevel10k)
  casonadams/zline
  # romkatv/powerlevel10k

  # Syntax Highlighting & Autosuggestions (ordered canonically)
  zsh-users/zsh-syntax-highlighting --defer
  zsh-users/zsh-autosuggestions

  # Heavy command lazy-loaded only when invoked
  lukechilds/zsh-nvm --on nvm,node,npm
)

zload "${plugins[@]}"

# 4. Optional: subshell eval caching (0ms overhead)
# zload eval zoxide "zoxide init zsh"
