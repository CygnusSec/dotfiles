#!/usr/bin/env bash
set -euo pipefail

DOTFILES=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DRY_RUN=false
INSTALL_PACKAGES=false
APPLY_DEFAULTS=false

usage() {
  cat <<'EOF'
Usage: ./install.sh [--dry-run] [--packages] [--defaults]

  --dry-run   Print actions without changing files or installing anything.
  --packages  Install packages from Brewfile or arch/packages.txt.
  --defaults  Apply macOS defaults (macOS only).
EOF
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --packages) INSTALL_PACKAGES=true ;;
    --defaults) APPLY_DEFAULTS=true ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$arg" >&2; usage >&2; exit 2 ;;
  esac
done

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
    printf 'Backed up: %s -> %s\n' "$dst" "$backup"
  fi
  run ln -s "$src" "$dst"
}

install_vscode_extensions() {
  local ext_file="$DOTFILES/common/vscode/extensions.txt" ext
  command -v code >/dev/null 2>&1 || { echo 'VS Code CLI not found; skipping extensions.'; return; }
  [[ -f "$ext_file" ]] || return
  while IFS= read -r ext; do
    [[ -z "$ext" || "$ext" == \#* ]] && continue
    run code --install-extension "$ext"
  done < "$ext_file"
}

install_common() {
  info 'Installing common dotfiles'
  link_file "$DOTFILES/common/zsh/.zshrc" "$HOME/.zshrc"
  link_file "$DOTFILES/common/git/.gitconfig" "$HOME/.gitconfig"
  link_file "$DOTFILES/common/tmux/.tmux.conf" "$HOME/.tmux.conf"
  if [[ -f "$DOTFILES/common/nvim/init.lua" || -f "$DOTFILES/common/nvim/init.vim" ]]; then
    link_file "$DOTFILES/common/nvim" "$HOME/.config/nvim"
  fi
  install_vscode_extensions
}

install_vscode() {
  local vscode_dir=$1
  link_file "$DOTFILES/common/vscode/settings.json" "$vscode_dir/settings.json"
  if [[ -f "$DOTFILES/common/vscode/keybindings.json" ]]; then
    link_file "$DOTFILES/common/vscode/keybindings.json" "$vscode_dir/keybindings.json"
  fi
}

install_arch() {
  info 'Installing Arch Linux configuration'
  if "$INSTALL_PACKAGES"; then
    command -v pacman >/dev/null 2>&1 || { echo 'pacman not found.' >&2; exit 1; }
    run sudo pacman -Syu --needed
    if [[ -s "$DOTFILES/arch/packages.txt" ]]; then
      if "$DRY_RUN"; then
        echo "DRY-RUN: sudo pacman -S --needed - < $DOTFILES/arch/packages.txt"
      else
        sudo pacman -S --needed - < "$DOTFILES/arch/packages.txt"
      fi
    fi
  fi
  link_file "$DOTFILES/arch/hypr" "$HOME/.config/hypr"
  link_file "$DOTFILES/arch/waybar" "$HOME/.config/waybar"
  link_file "$DOTFILES/arch/kitty" "$HOME/.config/kitty"
  install_vscode "$HOME/.config/Code/User"
}

install_macos() {
  info 'Installing macOS configuration'
  if "$INSTALL_PACKAGES"; then
    command -v brew >/dev/null 2>&1 || { echo 'Homebrew not installed.' >&2; exit 1; }
    run brew bundle --file="$DOTFILES/macos/Brewfile"
  fi
  install_vscode "$HOME/Library/Application Support/Code/User"
  if "$APPLY_DEFAULTS"; then
    run "$DOTFILES/macos/macos-defaults.sh"
  fi
}

install_common
case "$(uname -s)" in
  Linux) install_arch ;;
  Darwin) install_macos ;;
  *) printf 'Unsupported OS: %s\n' "$(uname -s)" >&2; exit 1 ;;
esac
info 'Dotfiles installation completed.'
