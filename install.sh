#!/usr/bin/env bash
set -euo pipefail

DOTFILES=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
OS=$(uname -s)
DRY_RUN=false
items=()

usage() {
  cat <<'EOF'
Usage: ./install.sh [--dry-run] [ITEM ...]

Choose only what to install. With no ITEM, an interactive prompt is shown.

Common items: zsh git tmux nvim vscode
macOS items:  brew defaults
Arch items:   hypr waybar kitty packages
Special:      all list

Examples:
  ./install.sh zsh nvim vscode
  ./install.sh --dry-run brew
  ./install.sh packages hypr waybar

Existing destinations are moved to timestamped backup files before linking.
EOF
}

available_items() {
  printf '%s\n' zsh git tmux nvim vscode
  case "$OS" in
    Darwin) printf '%s\n' brew defaults ;;
    Linux) printf '%s\n' hypr waybar kitty packages ;;
  esac
}

is_available() {
  local wanted=$1 item
  while IFS= read -r item; do
    [[ "$wanted" == "$item" ]] && return 0
  done < <(available_items)
  return 1
}

info() { printf '\n==> %s\n' "$1"; }
run() {
  if "$DRY_RUN"; then
    printf 'DRY-RUN:'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

link_file() {
  local src=$1 dst=$2 backup
  if [[ ! -e "$src" && ! -L "$src" ]]; then
    printf 'Skipping missing source: %s\n' "$src"
    return
  fi
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    printf 'Already linked: %s\n' "$dst"
    return
  fi
  run mkdir -p "$(dirname "$dst")"
  if [[ -e "$dst" || -L "$dst" ]]; then
    backup="${dst}.backup.$(date +%Y%m%d%H%M%S)"
    run mv "$dst" "$backup"
    if "$DRY_RUN"; then
      printf 'Would back up: %s -> %s\n' "$dst" "$backup"
    else
      printf 'Backed up: %s -> %s\n' "$dst" "$backup"
    fi
  fi
  run ln -s "$src" "$dst"
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
    [[ -x "$candidate" ]] && { printf '%s\n' "$candidate"; return; }
  done
  return 1
}

install_vscode() {
  local user_dir code_cli ext ext_file="$DOTFILES/common/vscode/extensions.txt"
  case "$OS" in
    Darwin) user_dir="$HOME/Library/Application Support/Code/User" ;;
    Linux) user_dir="$HOME/.config/Code/User" ;;
  esac
  link_file "$DOTFILES/common/vscode/settings.json" "$user_dir/settings.json"
  if [[ -f "$DOTFILES/common/vscode/keybindings.json" ]]; then
    link_file "$DOTFILES/common/vscode/keybindings.json" "$user_dir/keybindings.json"
  fi
  if code_cli=$(find_vscode_cli) && [[ -f "$ext_file" ]]; then
    while IFS= read -r ext; do
      [[ -z "$ext" || "$ext" == \#* ]] && continue
      run "$code_cli" --install-extension "$ext"
    done < "$ext_file"
  else
    echo 'VS Code CLI not found; skipping extensions.'
  fi
}

install_packages() {
  case "$OS" in
    Darwin)
      command -v brew >/dev/null 2>&1 || { echo 'Homebrew not installed.' >&2; exit 1; }
      run brew bundle --file="$DOTFILES/macos/Brewfile"
      ;;
    Linux)
      command -v pacman >/dev/null 2>&1 || { echo 'pacman not found.' >&2; exit 1; }
      run sudo pacman -Syu --needed
      if [[ -s "$DOTFILES/arch/packages.txt" ]]; then
        if "$DRY_RUN"; then
          echo "DRY-RUN: sudo pacman -S --needed - < $DOTFILES/arch/packages.txt"
        else
          sudo pacman -S --needed - < "$DOTFILES/arch/packages.txt"
        fi
      fi
      ;;
  esac
}

install_item() {
  info "Installing $1"
  case "$1" in
    zsh) link_file "$DOTFILES/common/zsh/.zshrc" "$HOME/.zshrc" ;;
    git) link_file "$DOTFILES/common/git/.gitconfig" "$HOME/.gitconfig" ;;
    tmux) link_file "$DOTFILES/common/tmux/.tmux.conf" "$HOME/.tmux.conf" ;;
    nvim) link_file "$DOTFILES/common/nvim" "$HOME/.config/nvim" ;;
    vscode) install_vscode ;;
    brew|packages) install_packages ;;
    defaults) run "$DOTFILES/macos/macos-defaults.sh" ;;
    hypr) link_file "$DOTFILES/arch/hypr" "$HOME/.config/hypr" ;;
    waybar) link_file "$DOTFILES/arch/waybar" "$HOME/.config/waybar" ;;
    kitty) link_file "$DOTFILES/arch/kitty" "$HOME/.config/kitty" ;;
  esac
}

case "$OS" in
  Darwin|Linux) ;;
  *) printf 'Unsupported OS: %s\n' "$OS" >&2; exit 1 ;;
esac

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true ;;
    --packages) items+=("$([[ "$OS" == Darwin ]] && echo brew || echo packages)") ;;
    --defaults) items+=(defaults) ;;
    -h|--help) usage; exit 0 ;;
    list|--list) available_items; exit 0 ;;
    --*) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    *) items+=("$1") ;;
  esac
  shift
done

if [[ ${#items[@]} -eq 0 ]]; then
  echo 'Available install items:'
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
    available_items | sed 's/^/  - /' >&2
    exit 2
  fi
done

for item in "${items[@]}"; do
  install_item "$item"
done

info 'Selected dotfiles installation completed.'
