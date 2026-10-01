#!/usr/bin/env bash
set -euo pipefail

DOTFILES=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
OS=$(uname -s)

usage() {
  cat <<'EOF'
Usage: ./backup.sh [ITEM ...]

Choose only what to copy from this machine into the repository. If no ITEM is
given, an interactive prompt is shown.

Common items: zsh git tmux vscode
macOS item:   brew
Arch items:   hypr waybar kitty
Special:      all list

Examples:
  ./backup.sh zsh vscode
  ./backup.sh brew
  ./backup.sh all

This script never runs git pull, commit, or push. Always review git diff.
EOF
}

available_items() {
  printf '%s\n' zsh git tmux vscode
  case "$OS" in
    Darwin) printf '%s\n' brew ;;
    Linux) printf '%s\n' hypr waybar kitty ;;
  esac
}

is_available() {
  local wanted=$1 item
  while IFS= read -r item; do
    [[ "$wanted" == "$item" ]] && return 0
  done < <(available_items)
  return 1
}

same_file() {
  local src=$1 dst=$2
  [[ -e "$src" && -e "$dst" ]] && [[ "$src" -ef "$dst" ]]
}

find_vscode_cli() {
  if command -v code >/dev/null 2>&1; then
    command -v code
    return
  fi

  local candidate
  for candidate in \
    "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" \
    "$HOME/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return
    fi
  done
  return 1
}

backup_file() {
  local src=$1 dst=$2 label=$3
  if [[ ! -f "$src" ]]; then
    echo "Skipping $label; source not found: $src"
  elif same_file "$src" "$dst"; then
    echo "Skipping $label; source already points into this repository."
  else
    mkdir -p "$(dirname "$dst")"
    cp -p "$src" "$dst"
    echo "Backed up $label."
  fi
}

backup_dir() {
  local src=$1 dst=$2 label=$3
  if [[ ! -d "$src" ]]; then
    echo "Skipping $label; source not found: $src"
  elif same_file "$src" "$dst"; then
    echo "Skipping $label; source already points into this repository."
  else
    mkdir -p "$dst"
    rsync -a --delete --exclude='.gitkeep' "$src/" "$dst/"
    echo "Backed up $label."
  fi
}

backup_vscode() {
  local user_dir code_cli
  case "$OS" in
    Darwin) user_dir="$HOME/Library/Application Support/Code/User" ;;
    Linux) user_dir="$HOME/.config/Code/User" ;;
  esac

  backup_file "$user_dir/settings.json" \
    "$DOTFILES/common/vscode/settings.json" 'VS Code settings'
  if [[ -f "$user_dir/keybindings.json" ]]; then
    backup_file "$user_dir/keybindings.json" \
      "$DOTFILES/common/vscode/keybindings.json" 'VS Code keybindings'
  fi
  if code_cli=$(find_vscode_cli); then
    "$code_cli" --list-extensions | LC_ALL=C sort > \
      "$DOTFILES/common/vscode/extensions.txt"
    echo "Backed up VS Code extensions using: $code_cli"
  else
    echo 'VS Code CLI not found in PATH or the standard macOS app location; extension list unchanged.'
  fi
}

backup_item() {
  case "$1" in
    zsh) backup_file "$HOME/.zshrc" "$DOTFILES/common/zsh/.zshrc" Zsh ;;
    git)
      echo 'Review Git config for credentials before committing.'
      backup_file "$HOME/.gitconfig" "$DOTFILES/common/git/.gitconfig" Git
      ;;
    tmux) backup_file "$HOME/.tmux.conf" "$DOTFILES/common/tmux/.tmux.conf" tmux ;;
    vscode) backup_vscode ;;
    brew)
      command -v brew >/dev/null 2>&1 || { echo 'Homebrew not found.'; return; }
      HOMEBREW_NO_AUTO_UPDATE=1 brew bundle dump \
        --file="$DOTFILES/macos/Brewfile" --force
      echo 'Backed up Homebrew bundle.'
      ;;
    hypr) backup_dir "$HOME/.config/hypr" "$DOTFILES/arch/hypr" Hyprland ;;
    waybar) backup_dir "$HOME/.config/waybar" "$DOTFILES/arch/waybar" Waybar ;;
    kitty) backup_dir "$HOME/.config/kitty" "$DOTFILES/arch/kitty" Kitty ;;
  esac
}

case "$OS" in
  Darwin|Linux) ;;
  *) printf 'Unsupported OS: %s\n' "$OS" >&2; exit 1 ;;
esac

if [[ ${1:-} == -h || ${1:-} == --help ]]; then
  usage
  exit 0
fi
if [[ ${1:-} == list || ${1:-} == --list ]]; then
  available_items
  exit 0
fi

items=("$@")
if [[ ${#items[@]} -eq 0 ]]; then
  echo 'Available backup items:'
  available_items | sed 's/^/  - /'
  printf 'Enter one or more names separated by spaces (or all): '
  IFS=' ' read -r -a items
fi

if [[ ${#items[@]} -eq 0 ]]; then
  echo 'Nothing selected.'
  exit 0
fi

if [[ " ${items[*]} " == *' all '* ]]; then
  items=()
  while IFS= read -r item; do items+=("$item"); done < <(available_items)
fi

for item in "${items[@]}"; do
  if ! is_available "$item"; then
    printf 'Unknown or unavailable item on %s: %s\n' "$OS" "$item" >&2
    printf 'Available items:\n' >&2
    available_items | sed 's/^/  - /' >&2
    exit 2
  fi
done

for item in "${items[@]}"; do
  backup_item "$item"
done

echo 'Backup complete. Review git status and git diff before committing.'
