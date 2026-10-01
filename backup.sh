#!/usr/bin/env bash
set -euo pipefail

DOTFILES=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if command -v code >/dev/null 2>&1; then
  echo 'Updating VS Code extension list...'
  code --list-extensions | LC_ALL=C sort > "$DOTFILES/common/vscode/extensions.txt"
else
  echo 'VS Code CLI not found; extension list unchanged.'
fi

case "$(uname -s)" in
  Linux)
    for app in hypr waybar kitty; do
      src="$HOME/.config/$app"
      dst="$DOTFILES/arch/$app"
      if [[ -L "$src" && "$(readlink -f "$src")" == "$(readlink -f "$dst")" ]]; then
        echo "Skipping $app; source already links into this repository."
      elif [[ -d "$src" ]]; then
        rsync -a --delete --exclude='.gitkeep' "$src/" "$dst/"
      fi
    done
    ;;
  Darwin)
    if command -v brew >/dev/null 2>&1; then
      HOMEBREW_NO_AUTO_UPDATE=1 brew bundle dump \
        --file="$DOTFILES/macos/Brewfile" --force
    else
      echo 'Homebrew not found; Brewfile unchanged.'
    fi
    ;;
  *) printf 'Unsupported OS: %s\n' "$(uname -s)" >&2; exit 1 ;;
esac

echo 'Backup complete. Review git diff before committing.'
