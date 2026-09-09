#!/usr/bin/env bash
# Update dotfiles, submodules, and vim plugins.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if git -C "${DOTFILES_DIR}" rev-parse --abbrev-ref \
    --symbolic-full-name @{u} >/dev/null 2>&1; then
  echo "==> Updating dotfiles repository..."
  git -C "${DOTFILES_DIR}" pull --ff-only
else
  echo "==> Skipping git pull (no upstream branch configured)..."
fi

echo "==> Updating git submodules..."
git -C "${DOTFILES_DIR}" submodule update --init --recursive --remote --merge

echo "==> Updating vim plugins..."
vim -es -u "${HOME}/.vimrc" -i NONE \
  -c "PlugUpdate --sync" -c "silent! PlugClean!" -c "qa"

if [[ -n "${TMUX:-}" ]]; then
  echo "==> Reloading tmux configuration..."
  tmux source-file "${HOME}/.tmux.conf" 2>/dev/null || true
fi

echo "==> Dotfiles and plugins successfully updated."
