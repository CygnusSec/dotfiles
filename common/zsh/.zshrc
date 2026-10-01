# Shared interactive shell configuration for macOS and Arch Linux.
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_THEME="robbyrussell"
plugins=(git)

if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
fi

export EDITOR="${EDITOR:-nvim}"
export VISUAL="${VISUAL:-$EDITOR}"
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

case "$(uname -s)" in
  Darwin)
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi

    [[ -s /opt/homebrew/opt/nvm/nvm.sh ]] && source /opt/homebrew/opt/nvm/nvm.sh
    [[ -s /opt/homebrew/opt/nvm/etc/bash_completion.d/nvm ]] && \
      source /opt/homebrew/opt/nvm/etc/bash_completion.d/nvm

    path=(
      /opt/homebrew/opt/rustup/bin
      /opt/homebrew/opt/openjdk@21/bin
      "$HOME/.docker/bin"
      /Applications/Docker.app/Contents/Resources/bin
      $path
    )

    if [[ -d "$HOME/.docker/completions" ]]; then
      fpath=("$HOME/.docker/completions" $fpath)
    fi
    ;;
  Linux)
    alias update='sudo pacman -Syu'
    ;;
esac

# Optional machine-local configuration and secrets. This file is not tracked.
[[ -r "$HOME/.config/private/env" ]] && source "$HOME/.config/private/env"
[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

alias dots='cd "$HOME/dotfiles"'
alias dots-status='git -C "$HOME/dotfiles" status'
alias dots-pull='git -C "$HOME/dotfiles" pull --rebase'

dots-push() {
  git -C "$HOME/dotfiles" add . || return
  git -C "$HOME/dotfiles" commit -m "${1:-Update dotfiles}" || return
  git -C "$HOME/dotfiles" push
}
