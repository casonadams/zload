#!/usr/bin/env sh
set -e

ZLOAD_DIR="${ZLOAD_HOME:-$HOME/.zload}"
REPO_URL="${ZLOAD_REPO:-https://github.com/casonadams/zload.git}"

printf "Installing zload to %s...\n" "$ZLOAD_DIR"
if [ -d "$ZLOAD_DIR/.git" ]; then
  git -C "$ZLOAD_DIR" pull --ff-only
else
  git clone --depth 1 "$REPO_URL" "$ZLOAD_DIR"
fi

if command -v zsh >/dev/null 2>&1; then
  printf "Compiling zload modules...\n"
  zsh -c "source '$ZLOAD_DIR/zload.zsh' && zload compile" >/dev/null 2>&1 || true
fi

ZSHRC="$HOME/.zshrc"
HOOK_LINE="source \"$ZLOAD_DIR/zload.zsh\""

if [ -f "$ZSHRC" ] && grep -Fq "zload.zsh" "$ZSHRC"; then
  printf "zload hook already present in %s\n" "$ZSHRC"
else
  printf "\n# zload plugin manager\n%s\n" "$HOOK_LINE" >> "$ZSHRC"
  printf "Added zload initialization to %s\n" "$ZSHRC"
fi

printf "Installation complete! Restart your shell or run: source ~/.zshrc\n"
